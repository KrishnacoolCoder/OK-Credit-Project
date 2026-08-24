import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/entities/customer.dart';
import '../domain/entities/product.dart';
import '../domain/entities/transaction.dart' as entity;

/// Firestore-backed cloud sync. Data lives under `shops/{shopCode}/...` so the
/// owner and staff that share a shop code see the same ledger across phones.
///
/// Everything here is only called when Firebase initialized successfully
/// (see [available]); otherwise the app runs fully offline.
class CloudService {
  static bool _available = false;
  static bool get available => _available;
  static void markAvailable() => _available = true;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _shopDoc(String shop) => _db.collection('shops').doc(shop);
  CollectionReference<Map<String, dynamic>> _col(String shop, String name) => _shopDoc(shop).collection(name);

  // ── Mapping helpers ──
  Map<String, dynamic> _custMap(Customer c) =>
      {'id': c.id, 'name': c.name, 'phone': c.phone, 'createdAt': c.createdAt.toIso8601String()};
  Customer _custFromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as String,
        name: m['name'] as String? ?? '',
        phone: m['phone'] as String?,
        createdAt: DateTime.tryParse(m['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> _txnMap(entity.Transaction t) => {
        'id': t.id,
        'customerId': t.customerId,
        'customerName': t.customerName,
        'amount': t.amount,
        'type': t.type.firestoreKey,
        'direction': t.direction == entity.TransactionDirection.incoming ? 'in' : 'out',
        'note': t.note,
        'date': t.date.toIso8601String(),
        'source': t.source,
      };
  entity.Transaction _txnFromMap(Map<String, dynamic> m) => entity.Transaction(
        id: m['id'] as String,
        customerId: m['customerId'] as String?,
        customerName: m['customerName'] as String? ?? 'Walk-in',
        amount: (m['amount'] as num?)?.toDouble() ?? 0,
        type: entity.TransactionTypeExt.fromKey(m['type'] as String? ?? 'cash'),
        direction: (m['direction'] as String?) == 'in' ? entity.TransactionDirection.incoming : entity.TransactionDirection.outgoing,
        note: m['note'] as String?,
        date: DateTime.tryParse(m['date'] as String? ?? '') ?? DateTime.now(),
        source: m['source'] as String? ?? 'manual',
      );

  Future<void> _pushAll(CollectionReference<Map<String, dynamic>> col, List<Map<String, dynamic>> rows) async {
    // Commit in chunks (Firestore batch limit is 500 ops).
    for (var i = 0; i < rows.length; i += 400) {
      final end = (i + 400) < rows.length ? (i + 400) : rows.length;
      final batch = _db.batch();
      for (final row in rows.sublist(i, end)) {
        batch.set(col.doc(row['id'] as String), row, SetOptions(merge: true));
      }
      await batch.commit();
    }
  }

  // ── Push (local → cloud) ──
  Future<void> pushCustomers(String shop, List<Customer> list) =>
      _pushAll(_col(shop, 'customers'), list.map(_custMap).toList());

  Future<void> pushTransactions(String shop, List<entity.Transaction> list) =>
      _pushAll(_col(shop, 'transactions'), list.map(_txnMap).toList());

  Future<void> pushProducts(String shop, List<Product> list) =>
      _pushAll(_col(shop, 'products'), list.map((p) => p.toMap()).toList());

  Future<void> pushProfile(String shop, Map<String, dynamic> profile) async {
    await _shopDoc(shop).set({'profile': profile, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }

  // ── Pull (cloud → local) ──
  Future<List<Customer>> pullCustomers(String shop) async {
    final snap = await _col(shop, 'customers').get();
    return snap.docs.map((d) => _custFromMap(d.data())).toList();
  }

  Future<List<entity.Transaction>> pullTransactions(String shop) async {
    final snap = await _col(shop, 'transactions').get();
    return snap.docs.map((d) => _txnFromMap(d.data())).toList();
  }

  Future<List<Product>> pullProducts(String shop) async {
    final snap = await _col(shop, 'products').get();
    return snap.docs.map((d) => Product.fromMap(d.data())).toList();
  }

  Future<Map<String, dynamic>?> pullProfile(String shop) async {
    final doc = await _shopDoc(shop).get();
    final data = doc.data();
    if (data == null) return null;
    final p = data['profile'];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  // ── Realtime: fire [onChange] when any collection in the shop changes ──
  List<StreamSubscription> listen(String shop, void Function() onChange) {
    return [
      _col(shop, 'customers').snapshots().listen((_) => onChange(), onError: (_) {}),
      _col(shop, 'transactions').snapshots().listen((_) => onChange(), onError: (_) {}),
      _col(shop, 'products').snapshots().listen((_) => onChange(), onError: (_) {}),
    ];
  }
}
