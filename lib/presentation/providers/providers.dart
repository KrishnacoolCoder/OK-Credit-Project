// lib/presentation/providers/providers.dart
export '../../domain/entities/app_notification.dart';
import '../../domain/entities/app_notification.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/entities/customer.dart';
import '../../domain/entities/sms_entry.dart';
import '../../domain/entities/store_profile.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/bill.dart';
import '../../services/auth_service.dart';
import '../../services/cloud_service.dart';
import '../../services/upi_notification_service.dart';

// ── Auth / session ────────────────────────────────────
final authServiceProvider = Provider<AuthService>((_) => AuthService());

/// The currently logged-in user (null = logged out). Tracks Firebase Auth's
/// own sign-in state (`idTokenChanges`) rather than a manually-saved session —
/// Firebase already persists sign-in across app restarts, and this also picks
/// up custom-claim refreshes (e.g. right after claiming a shop).
class SessionNotifier extends StateNotifier<AppUser?> {
  final AuthService _auth;
  final Ref _ref;
  bool _restored = false;
  StreamSubscription<fb.User?>? _sub;

  SessionNotifier(this._auth, this._ref) : super(null) {
    _restore();
    if (firebase_core.Firebase.apps.isNotEmpty) {
      _sub = fb.FirebaseAuth.instance.idTokenChanges().listen((_) => _restore());
    }
  }

  Future<void> _restore() async {
    final user = await _auth.getSessionUser();
    state = user;
    _restored = true;
    if (user != null) {
      _ref.read(cloudSyncProvider).startSyncing(user.effectiveShopId);
    } else {
      _ref.read(cloudSyncProvider).stopSyncing();
    }
  }

  bool get isRestored => _restored;

  /// Re-reads the session from Firebase right now — used right after a
  /// phone-OTP sign-in or a shop claim so the UI doesn't have to wait for the
  /// token-refresh stream to catch up.
  Future<AppUser?> refresh() => _restore().then((_) => state);

  Future<void> logout() async {
    _ref.read(cloudSyncProvider).stopSyncing();
    await _auth.clearSession();
    state = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final currentUserProvider = StateNotifierProvider<SessionNotifier, AppUser?>(
  (ref) => SessionNotifier(ref.watch(authServiceProvider), ref),
);

final usersProvider = FutureProvider<List<AppUser>>((ref) => ref.watch(authServiceProvider).getUsers());
final hasAdminProvider = FutureProvider<bool>((ref) => ref.watch(authServiceProvider).hasAdmin());

// ── Cloud sync (Firestore) ────────────────────────────────
final cloudServiceProvider = Provider<CloudService>((_) => CloudService());

/// Bridges the local, offline-first ledger with Firestore. Pulls a shop's data
/// down once per sign-in (so a second device sees everything), then keeps a
/// realtime listener open so changes made elsewhere show up here too. Local
/// mutations get pushed up to the cloud right after they're saved locally —
/// see [addTransactionProvider] etc below. Every method is a no-op when
/// Firebase wasn't configured at build time, so the app still works fully
/// offline.
class CloudSyncController {
  CloudSyncController(this._ref);
  final Ref _ref;
  final List<StreamSubscription> _subs = [];
  String? _syncedShopId;

  CloudService get _cloud => _ref.read(cloudServiceProvider);
  LocalSource get _local => _ref.read(localSourceProvider);

  Future<void> startSyncing(String shopId) async {
    if (!CloudService.available || _syncedShopId == shopId) return;
    _syncedShopId = shopId;

    try {
      final remoteCustomers = await _cloud.pullCustomers(shopId);
      final remoteTxns = await _cloud.pullTransactions(shopId);
      final remoteProducts = await _cloud.pullProducts(shopId);
      final remoteProfile = await _cloud.pullProfile(shopId);

      // The cloud copy is the source of truth once a shop has synced at all —
      // this is what makes "log in from a second phone" actually work.
      if (remoteCustomers.isNotEmpty || remoteTxns.isNotEmpty || remoteProducts.isNotEmpty) {
        await _local.replaceCustomers(remoteCustomers);
        await _local.replaceTransactions(remoteTxns);
        await _local.replaceProducts(remoteProducts);
      }
      if (remoteProfile != null) {
        await _local.saveStoreProfile(StoreProfile.fromMap(remoteProfile));
      }

      _invalidateAll();
      _ref.read(storeProfileProvider.notifier).reload();
    } catch (_) {
      // Offline, or first-ever sync with nothing pushed yet — local data
      // stays authoritative and we'll try again on the next app open.
    }

    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _subs.addAll(_cloud.listen(shopId, _invalidateAll));
  }

  void stopSyncing() {
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _syncedShopId = null;
  }

  void _invalidateAll() {
    _ref.invalidate(customersStreamProvider);
    _ref.invalidate(transactionsStreamProvider);
    _ref.invalidate(productsStreamProvider);
    _ref.invalidate(todayTotalsProvider);
    _ref.invalidate(overdueCustomersProvider);
  }

  /// Pushes the full local ledger up to Firestore. Cheap enough for a shop's
  /// scale (hundreds, not millions, of rows) and much simpler than tracking
  /// per-record dirty state.
  void pushEverything(String shopId) {
    if (!CloudService.available) return;
    Future(() async {
      try {
        await _cloud.pushCustomers(shopId, await _local.getCustomers());
        await _cloud.pushTransactions(shopId, await _local.getTransactions());
        await _cloud.pushProducts(shopId, await _local.getProducts());
      } catch (_) {
        // Offline — the next successful mutation (or app open) will retry.
      }
    });
  }

  void pushProfile(String shopId, Map<String, dynamic> profile) {
    if (!CloudService.available) return;
    _cloud.pushProfile(shopId, profile).catchError((_) {});
  }
}

final cloudSyncProvider = Provider<CloudSyncController>((ref) => CloudSyncController(ref));

// ── UPI notification bridge ─────────────────────
final upiNotificationServiceProvider = Provider<UpiNotificationService>((_) => UpiNotificationService());

final upiNotificationBridgeProvider = Provider<UpiNotificationBridge>((ref) => UpiNotificationBridge(ref));

class UpiNotificationBridge {
  UpiNotificationBridge(this._ref);

  final Ref _ref;
  StreamSubscription<UpiNotificationEvent>? _sub;
  bool _started = false;

  void start({required Future<void> Function(UpiNotificationEvent event) onEvent}) {
    if (_started) return;
    _started = true;

    _sub = _ref.read(upiNotificationServiceProvider).stream().listen((event) async {
      processEvent(event);
      await onEvent(event);
    });
  }

  void processEvent(UpiNotificationEvent event) {
    final source = _mapSource(event.appSource, event.rawText);
    final senderName = _extractSenderName(event.sender, event.rawText);
    final entry = SmsEntry(
      id: '${event.timestamp}_${event.rawText.hashCode}',
      rawSms: event.rawText,
      parsedAmount: event.amount,
      parsedSource: source,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(event.timestamp),
      status: 'pending',
      senderName: senderName,
    );
    _ref.read(smsQueueProvider.notifier).add(entry);
  }

  /// Extracts the sender's name from the notification.
  /// Tries event.sender first, then falls back to regex on raw text.
  /// Example: "Dipanshu Raj has sent ₹1 to your bank account..."  → "Dipanshu Raj"
  String? _extractSenderName(String sender, String rawText) {
    // Use sender field if it looks like a real name (not empty / generic)
    final trimmed = sender.trim();
    if (trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'unknown' &&
        trimmed.toLowerCase() != 'upi' &&
        !trimmed.contains('@') &&
        trimmed.length > 1) {
      return _toTitleCase(trimmed);
    }

    // Fallback: parse raw SMS text with common UPI notification patterns
    final patterns = [
      // "Dipanshu Raj has sent ₹1 to your bank account"
      RegExp(r'^([A-Za-z][A-Za-z ]{1,40})\s+has sent', caseSensitive: false),
      // "Received Rs.1 from Dipanshu Raj"
      RegExp(r'(?:received|from)\s+(?:rs\.?\s*\d+[\.,]?\d*\s+from\s+)?([A-Za-z][A-Za-z ]{1,40})', caseSensitive: false),
      // "Money received from Dipanshu Raj"
      RegExp(r'from\s+([A-Za-z][A-Za-z ]{1,35})\s+(?:via|on|to|at)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(rawText);
      if (match != null) {
        final name = match.group(1)?.trim();
        if (name != null && name.length > 1 && name.length < 50) {
          return _toTitleCase(name);
        }
      }
    }
    return null;
  }

  String _toTitleCase(String s) =>
      s.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');


  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  entity.TransactionType _mapSource(String appSource, String rawText) {
    final app = appSource.toLowerCase();
    final text = rawText.toLowerCase();

    if (app.contains('phonepe') || text.contains('phonepe')) {
      return entity.TransactionType.upiPhonePe;
    }
    if (app.contains('paytm') || text.contains('paytm')) {
      return entity.TransactionType.upiPaytm;
    }
    if (app.contains('gpay') || app.contains('paisa') || text.contains('google pay') || text.contains('gpay')) {
      return entity.TransactionType.upiGpay;
    }
    return entity.TransactionType.upiGpay;
  }
}

// ── Local source with demo data ───────────────────────
class LocalSource {
  static const _custsKey  = 'sangam_custs';
  static const _txnsKey   = 'sangam_txns';
  static const _seededKey = 'sangam_seeded_v2';
  static const _profileKey = 'sangam_store_profile';
  static const _productsKey = 'sangam_products';
  static const _billsKey = 'sangam_bills';
  static const _uuid = Uuid();

  SharedPreferences? _p;
  Future<SharedPreferences> get _prefs async => _p ??= await SharedPreferences.getInstance();

  /// Ensures local storage is ready. Does NOT auto-seed demo data anymore —
  /// new shop owners choose between a fresh start and demo data during setup.
  Future<void> ensureSeeded() async {
    await _prefs;
  }

  // ── Store profile ──
  Future<StoreProfile> getStoreProfile() async {
    final p = await _prefs;
    final raw = p.getString(_profileKey);
    if (raw == null) return StoreProfile.empty;
    return StoreProfile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveStoreProfile(StoreProfile profile) async {
    final p = await _prefs;
    await p.setString(_profileKey, jsonEncode(profile.toMap()));
  }

  /// Seed demo customers + transactions (used for "Try with demo data").
  Future<void> seedDemoData() async {
    final p = await _prefs;
    await _saveCustomers(_seedCustomers());
    await _saveTransactions(_seedTransactions());
    await p.setBool(_seededKey, true);
  }

  /// Start with an empty ledger (used for a real shop's first launch).
  Future<void> startFresh() async {
    final p = await _prefs;
    await _saveCustomers([]);
    await _saveTransactions([]);
    await p.setBool(_seededKey, true);
  }

  /// Erase all transactions and customers but keep the store profile.
  Future<void> clearAllData() async {
    await _saveCustomers([]);
    await _saveTransactions([]);
  }

  List<Customer> _seedCustomers() => [
    Customer(id:'c1',name:'Ramesh Gupta',   phone:'9876543210',createdAt:DateTime.now().subtract(const Duration(days:30))),
    Customer(id:'c2',name:'Kavita Devi',    phone:'9765432109',createdAt:DateTime.now().subtract(const Duration(days:25))),
    Customer(id:'c3',name:'Mohan Sharma',   phone:'9654321098',createdAt:DateTime.now().subtract(const Duration(days:20))),
    Customer(id:'c4',name:'Sunita Singh',   phone:'9543210987',createdAt:DateTime.now().subtract(const Duration(days:15))),
    Customer(id:'c5',name:'Raju Prasad',    phone:'9432109876',createdAt:DateTime.now().subtract(const Duration(days:10))),
    Customer(id:'c6',name:'Priya Kumari',   phone:'9321098765',createdAt:DateTime.now().subtract(const Duration(days:8))),
    Customer(id:'c7',name:'Vikram Yadav',   phone:'9210987654',createdAt:DateTime.now().subtract(const Duration(days:5))),
  ];

  List<entity.Transaction> _seedTransactions() {
    final now = DateTime.now();
    final List<entity.Transaction> list = [];
    final random = math.Random(42);
    
    // Some older manual credit transactions to make the ledger look real
    list.addAll([
      entity.Transaction(id:_uuid.v4(),customerId:'c1',customerName:'Ramesh Gupta',  amount:350,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Atta 10kg, Dal 2kg',  date:now.subtract(const Duration(days:18))),
      entity.Transaction(id:_uuid.v4(),customerId:'c2',customerName:'Kavita Devi',   amount:180,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Rice 5kg, Sugar 2kg', date:now.subtract(const Duration(days:16))),
      entity.Transaction(id:_uuid.v4(),customerId:'c4',customerName:'Sunita Singh',  amount:600,type:entity.TransactionType.credit,    direction:entity.TransactionDirection.outgoing,note:'Cooking oil',         date:now.subtract(const Duration(days:15))),
    ]);

    final upiTypes = [entity.TransactionType.upiGpay, entity.TransactionType.upiPaytm, entity.TransactionType.upiPhonePe];
    
    // Generate 14 days of realistic daily usage
    for (int day = 14; day >= 0; day--) {
      // Simulate "Used 6 of 7 days in wk 7 (days 7-13) and 5 of 7 in wk 8 (days 0-6)"
      if (day == 10) continue; // skip a day in wk 7
      if (day == 3 || day == 4) continue; // skip 2 days in wk 8 (e.g. shop closed or phone broke)

      // 8 to 15 transactions a day
      int txCount = 8 + random.nextInt(8);
      
      for (int i = 0; i < txCount; i++) {
        // Peak usage 19:30-20:15 IST (cluster heavily in evening)
        int hour = random.nextBool() ? (18 + random.nextInt(3)) : (10 + random.nextInt(7)); 
        if (random.nextInt(10) < 4) hour = 19; // bias towards 7 PM
        
        int minute = random.nextInt(60);
        DateTime txDate = DateTime(now.year, now.month, now.day - day, hour, minute);
        
        bool isWalkin = random.nextInt(10) < 7; // 70% walk-ins
        bool isCash = random.nextInt(10) < 2; // 20% cash, 80% UPI (high UPI adoption)
        
        int amount = (2 + random.nextInt(40)) * 10; // ₹20 to ₹400
        
        list.add(
          entity.Transaction(
            id: _uuid.v4(),
            customerId: isWalkin ? null : 'c${1 + random.nextInt(7)}',
            customerName: isWalkin ? 'Walk-in' : 'Customer ${1 + random.nextInt(7)}',
            amount: amount.toDouble(),
            type: isCash ? entity.TransactionType.cash : upiTypes[random.nextInt(upiTypes.length)],
            direction: entity.TransactionDirection.incoming,
            note: isWalkin ? (isCash ? 'Cash sale' : 'UPI via Notification') : 'Cleared partial dues',
            date: txDate,
            source: isCash ? 'manual' : 'notification',
          )
        );
      }
    }
    
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Customers
  Future<List<Customer>> getCustomers() async {
    final p = await _prefs;
    final raw = p.getString(_custsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => _custFromMap(e)).toList();
  }

  Future<void> addCustomer(Customer c) async {
    final all = await getCustomers(); all.add(c); await _saveCustomers(all);
  }

  /// Overwrites the whole local customer list — used when pulling the cloud
  /// copy down after signing in on a device.
  Future<void> replaceCustomers(List<Customer> list) => _saveCustomers(list);

  Future<void> _saveCustomers(List<Customer> list) async {
    final p = await _prefs;
    await p.setString(_custsKey, jsonEncode(list.map(_custToMap).toList()));
  }

  // Transactions
  Future<List<entity.Transaction>> getTransactions() async {
    final p = await _prefs;
    final raw = p.getString(_txnsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => _txnFromMap(e)).toList()
      ..sort((a,b) => b.date.compareTo(a.date));
  }

  Future<void> addTransaction(entity.Transaction t) async {
    final all = await getTransactions(); all.insert(0,t); await _saveTransactions(all);
  }

  /// Overwrites the whole local transaction list — used when pulling the
  /// cloud copy down after signing in on a device.
  Future<void> replaceTransactions(List<entity.Transaction> list) => _saveTransactions(list);

  Future<void> _saveTransactions(List<entity.Transaction> list) async {
    final p = await _prefs;
    await p.setString(_txnsKey, jsonEncode(list.map(_txnToMap).toList()));
  }

  // Products / Stock
  Future<List<Product>> getProducts() async {
    final p = await _prefs;
    final raw = p.getString(_productsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Product.fromMap(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> addProduct(Product item) async {
    final all = await getProducts(); all.add(item); await _saveProducts(all);
  }

  Future<void> updateProduct(Product item) async {
    final all = await getProducts();
    final idx = all.indexWhere((p) => p.id == item.id);
    if (idx >= 0) all[idx] = item; else all.add(item);
    await _saveProducts(all);
  }

  Future<void> deleteProduct(String id) async {
    final all = await getProducts();
    all.removeWhere((p) => p.id == id);
    await _saveProducts(all);
  }

  /// Overwrites the whole local product list — used when pulling the cloud
  /// copy down after signing in on a device.
  Future<void> replaceProducts(List<Product> list) => _saveProducts(list);

  Future<void> _saveProducts(List<Product> list) async {
    final p = await _prefs;
    await p.setString(_productsKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  // Bills
  Future<List<Bill>> getBills() async {
    final p = await _prefs;
    final raw = p.getString(_billsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => Bill.fromMap(Map<String, dynamic>.from(e as Map))).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addBill(Bill bill) async {
    final all = await getBills(); all.insert(0, bill); await _saveBills(all);
  }

  Future<void> replaceBills(List<Bill> list) => _saveBills(list);

  Future<void> _saveBills(List<Bill> list) async {
    final p = await _prefs;
    await p.setString(_billsKey, jsonEncode(list.map((e) => e.toMap()).toList()));
  }

  // Computed
  Future<double> getBalance(String custId) async {
    final txns = await getTransactions();
    return txns.where((t) => t.customerId == custId).fold<double>(0.0, (s,t) =>
        t.direction == entity.TransactionDirection.outgoing ? s + t.amount : s - t.amount);
  }

  Future<DailyTotals> getDailyTotals(DateTime date) async {
    final txns = await getTransactions();
    final today = txns.where((t) => _sameDay(t.date, date)).toList();
    double paytm=0, gpay=0, phonePe=0, cash=0, creditOut=0, creditIn=0;
    for (final t in today) {
      if (t.direction == entity.TransactionDirection.incoming) {
        switch(t.type) {
          case entity.TransactionType.upiPaytm:   paytm += t.amount; break;
          case entity.TransactionType.upiGpay:    gpay += t.amount; break;
          case entity.TransactionType.upiPhonePe: phonePe += t.amount; break;
          case entity.TransactionType.cash:       cash += t.amount; break;
          case entity.TransactionType.credit:     creditIn += t.amount; break;
        }
      } else { if (t.type == entity.TransactionType.credit) creditOut += t.amount; }
    }
    return DailyTotals(paytm:paytm, gpay:gpay, phonePe:phonePe, cash:cash, creditOut:creditOut, creditIn:creditIn, txnCount:today.length);
  }

  Future<List<OverdueCustomer>> getOverdueCustomers({int dueDays = 7}) async {
    final custs = await getCustomers();
    final txns  = await getTransactions();
    final result = <OverdueCustomer>[];
    for (final c in custs) {
      final bal = txns.where((t) => t.customerId == c.id).fold<double>(0.0, (s,t) =>
          t.direction == entity.TransactionDirection.outgoing ? s + t.amount : s - t.amount);
      if (bal <= 0) continue;
      final lastCredit = txns.where((t) => t.customerId == c.id && t.type == entity.TransactionType.credit && t.direction == entity.TransactionDirection.outgoing).toList()
        ..sort((a,b) => b.date.compareTo(a.date));
      if (lastCredit.isEmpty) continue;
      final days = DateTime.now().difference(lastCredit.first.date).inDays;
      result.add(OverdueCustomer(customerId:c.id, customerName:c.name, phone:c.phone, balance:bal, daysOverdue:days-dueDays));
    }
    result.sort((a,b) => b.daysOverdue.compareTo(a.daysOverdue));
    return result;
  }

  Future<void> resetToDemo() async {
    await seedDemoData();
  }

  bool _sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;

  // Serialization helpers
  Map<String,dynamic> _custToMap(Customer c) => {'id':c.id,'name':c.name,'phone':c.phone,'createdAt':c.createdAt.toIso8601String()};
  Customer _custFromMap(Map<String,dynamic> m) => Customer(id:m['id'],name:m['name'],phone:m['phone'],createdAt:DateTime.parse(m['createdAt']));
  Map<String,dynamic> _txnToMap(entity.Transaction t) => {'id':t.id,'customerId':t.customerId,'customerName':t.customerName,'amount':t.amount,'type':t.type.firestoreKey,'direction':t.direction==entity.TransactionDirection.incoming?'in':'out','note':t.note,'date':t.date.toIso8601String(),'source':t.source};
  entity.Transaction _txnFromMap(Map<String,dynamic> m) => entity.Transaction(id:m['id'],customerId:m['customerId'],customerName:m['customerName']??'Walk-in',amount:(m['amount'] as num).toDouble(),type:entity.TransactionTypeExt.fromKey(m['type']??'cash'),direction:m['direction']=='in'?entity.TransactionDirection.incoming:entity.TransactionDirection.outgoing,note:m['note'],date:DateTime.parse(m['date']),source:m['source']??'manual');
}

// --- Shared Providers ---
final localSourceProvider = Provider<LocalSource>((_) => LocalSource());

final appInitProvider = FutureProvider<void>((ref) => ref.watch(localSourceProvider).ensureSeeded());

// ── Store profile ──
class StoreProfileNotifier extends StateNotifier<StoreProfile> {
  final LocalSource _source;
  final Ref _ref;
  StoreProfileNotifier(this._source, this._ref) : super(StoreProfile.empty) {
    _load();
  }

  Future<void> _load() async {
    state = await _source.getStoreProfile();
  }

  Future<void> save(StoreProfile profile) async {
    await _source.saveStoreProfile(profile);
    state = profile;
    final shopId = _ref.read(currentUserProvider)?.effectiveShopId;
    if (shopId != null) _ref.read(cloudSyncProvider).pushProfile(shopId, profile.toMap());
  }

  Future<void> reload() => _load();
}

final storeProfileProvider = StateNotifierProvider<StoreProfileNotifier, StoreProfile>(
  (ref) => StoreProfileNotifier(ref.watch(localSourceProvider), ref),
);

final _txnStreamCtrl = StreamProvider<List<entity.Transaction>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.watch(localSourceProvider).getTransactions();
});

final transactionsStreamProvider = _txnStreamCtrl;

final addTransactionProvider = Provider<Future<void> Function(entity.Transaction)>((ref) {
  return (t) async {
    await ref.read(localSourceProvider).addTransaction(t);
    ref.invalidate(_txnStreamCtrl);
    ref.invalidate(todayTotalsProvider);
    ref.invalidate(overdueCustomersProvider);
    
    // Generate real dynamic notification based on transaction type
    NotificationType nType = NotificationType.system;
    String nTitle = 'Transaction Added';
    String nBody = 'New transaction logged.';
    
    if (t.direction == entity.TransactionDirection.incoming) {
      if (t.type == entity.TransactionType.cash) {
        nType = NotificationType.paymentReceived;
        nTitle = 'Cash Received';
        nBody = '₹${t.amount.toStringAsFixed(0)} received from ${t.customerName}.';
      } else {
        nType = NotificationType.upiPayment;
        nTitle = 'UPI Payment Received';
        nBody = '₹${t.amount.toStringAsFixed(0)} received from ${t.customerName} via ${t.type.label}.';
      }
    } else {
      nType = NotificationType.creditGiven;
      nTitle = 'Credit Given';
      nBody = '₹${t.amount.toStringAsFixed(0)} credit given to ${t.customerName}.';
    }
    
    ref.read(appNotificationsProvider.notifier).add(
      AppNotification(
        id: const Uuid().v4(),
        title: nTitle,
        body: nBody,
        type: nType,
        timestamp: DateTime.now(),
      )
    );

    final shopId = ref.read(currentUserProvider)?.effectiveShopId;
    if (shopId != null) ref.read(cloudSyncProvider).pushEverything(shopId);
  };
});

final todayTotalsProvider = FutureProvider<DailyTotals>((ref) async {
  ref.watch(_txnStreamCtrl);
  return ref.read(localSourceProvider).getDailyTotals(DateTime.now());
});

final dailyTotalsProvider = FutureProvider.family<DailyTotals, DateTime>((ref, DateTime date) async {
  ref.watch(_txnStreamCtrl);
  return ref.read(localSourceProvider).getDailyTotals(date);
});

final customersStreamProvider = StreamProvider<List<Customer>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.read(localSourceProvider).getCustomers();
});

final addCustomerProvider = Provider<Future<void> Function(Customer)>((ref) {
  return (c) async {
    await ref.read(localSourceProvider).addCustomer(c);
    ref.invalidate(customersStreamProvider);
    final shopId = ref.read(currentUserProvider)?.effectiveShopId;
    if (shopId != null) ref.read(cloudSyncProvider).pushEverything(shopId);
  };
});

final customerBalanceProvider = FutureProvider.family<double, String>((ref, custId) {
  ref.watch(_txnStreamCtrl);
  return ref.read(localSourceProvider).getBalance(custId);
});

final customerTransactionsProvider = FutureProvider.family<List<entity.Transaction>, String>((ref, custId) async {
  ref.watch(_txnStreamCtrl);
  final all = await ref.read(localSourceProvider).getTransactions();
  return all.where((t) => t.customerId == custId).toList();
});

final overdueCustomersProvider = FutureProvider<List<OverdueCustomer>>((ref) {
  ref.watch(_txnStreamCtrl);
  final dueDays = ref.watch(storeProfileProvider).creditDueDays;
  return ref.read(localSourceProvider).getOverdueCustomers(dueDays: dueDays);
});

// ── Products / Stock ──
final productsStreamProvider = StreamProvider<List<Product>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.read(localSourceProvider).getProducts();
});

final saveProductProvider = Provider<Future<void> Function(Product)>((ref) {
  return (item) async {
    await ref.read(localSourceProvider).updateProduct(item);
    ref.invalidate(productsStreamProvider);
    final shopId = ref.read(currentUserProvider)?.effectiveShopId;
    if (shopId != null) ref.read(cloudSyncProvider).pushEverything(shopId);
  };
});

final deleteProductProvider = Provider<Future<void> Function(String)>((ref) {
  return (id) async {
    await ref.read(localSourceProvider).deleteProduct(id);
    ref.invalidate(productsStreamProvider);
    final shopId = ref.read(currentUserProvider)?.effectiveShopId;
    if (shopId != null) ref.read(cloudSyncProvider).pushEverything(shopId);
  };
});

// ── Bills ──
final billsStreamProvider = StreamProvider<List<Bill>>((ref) async* {
  await ref.watch(appInitProvider.future);
  yield await ref.read(localSourceProvider).getBills();
});

final addBillProvider = Provider<Future<void> Function(Bill)>((ref) {
  return (bill) async {
    await ref.read(localSourceProvider).addBill(bill);
    ref.invalidate(billsStreamProvider);
    // TODO: implement cloud sync push for bills
  };
});

final smsQueueProvider = StateNotifierProvider<_SmsQueueNotifier, List<SmsEntry>>((_) => _SmsQueueNotifier());

class _SmsQueueNotifier extends StateNotifier<List<SmsEntry>> {
  static const _key = 'sangam_sms_queue';

  _SmsQueueNotifier() : super([]) {
    _load();
  }

  /// Load persisted entries from disk and filter out anything older than 24 hours.
  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).map((m) {
        final map = Map<String, dynamic>.from(m as Map);
        return SmsEntry(
          id: map['id'] as String,
          rawSms: map['rawSms'] as String,
          parsedAmount: (map['parsedAmount'] as num?)?.toDouble(),
          parsedSource: map['parsedSource'] != null
              ? entity.TransactionTypeExt.fromKey(map['parsedSource'] as String)
              : null,
          receivedAt: DateTime.parse(map['receivedAt'] as String),
          status: map['status'] as String? ?? 'pending',
          senderName: map['senderName'] as String?,
        );
      }).toList();

      // Only keep entries from the last 24 hours
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      state = list.where((e) => e.receivedAt.isAfter(cutoff)).toList();
      // Persist the cleaned-up list back
      _persist();
    } catch (_) {
      // Corrupted data — start fresh
      state = [];
    }
  }

  void add(SmsEntry e) {
    if (state.any((s) => s.id == e.id)) return;
    state = [...state, e];
    _persist();
  }

  void dismiss(String id) {
    state = state.map((e) => e.id == id
        ? SmsEntry(id: e.id, rawSms: e.rawSms, parsedAmount: e.parsedAmount,
            parsedSource: e.parsedSource, receivedAt: e.receivedAt,
            senderName: e.senderName, status: 'dismissed')
        : e).toList();
    _persist();
  }

  void clear() {
    state = [];
    _persist();
  }

  List<SmsEntry> get pending => state.where((e) => e.status == 'pending').toList();

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    final list = state.map((e) => {
      'id': e.id,
      'rawSms': e.rawSms,
      'parsedAmount': e.parsedAmount,
      'parsedSource': e.parsedSource?.firestoreKey,
      'receivedAt': e.receivedAt.toIso8601String(),
      'status': e.status,
      'senderName': e.senderName,
    }).toList();
    await p.setString(_key, jsonEncode(list));
  }
}

final onboardedProvider = FutureProvider<bool>((ref) async {
  final p = await SharedPreferences.getInstance();
  return p.getBool('sangam_onboarded') ?? false;
});


// Minimal language provider for screens that watch it
final languageProvider = StateProvider<bool>((_) => false);
