import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../../domain/entities/sms_entry.dart';
import '../../../domain/entities/customer.dart';
import '../../../services/notification_access_service.dart';
import '../../providers/providers.dart';
import '../../../core/context_extensions.dart';
import '../../widgets/bottom_nav.dart';

class SmsQueueScreen extends ConsumerStatefulWidget {
  const SmsQueueScreen({super.key});

  @override
  ConsumerState<SmsQueueScreen> createState() => _S();
}

class _S extends ConsumerState<SmsQueueScreen> with WidgetsBindingObserver {
  bool _scanning = false;
  bool _enabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAndPoll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// When user switches back to the app (from Settings or after receiving a payment),
  /// re-check permission and auto-poll for new queued payments.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndPoll();
    }
  }

  /// Check notification access permission AND poll for queued payments.
  Future<void> _checkAndPoll() async {
    final enabled = await NotificationAccessService().isEnabled();
    if (mounted) {
      setState(() => _enabled = enabled);
      if (enabled) {
        _scan(showSnack: false); // silent auto-poll
      }
    }
  }

  Future<void> _scan({bool showSnack = true}) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    
    final service = NotificationAccessService();
    final queued = await service.getQueuedPayments();
    
    if (mounted) {
      if (queued.isNotEmpty) {
        final bridge = ref.read(upiNotificationBridgeProvider);
        for (final event in queued) {
          bridge.processEvent(event);
        }
      }

      setState(() => _scanning = false);
      if (showSnack) {
        final pending = ref.read(smsQueueProvider).where((e) => e.status == 'pending').length;
        context.showSnack(
          pending > 0 ? 'Found $pending payment(s)' : 'No new UPI notifications found',
        );
      }
    }
  }

  Future<void> _enable() async {
    setState(() => _scanning = true);
    final service = NotificationAccessService();
    await service.openSettings();
    // Permission check will happen in didChangeAppLifecycleState when user returns
    if (mounted) setState(() => _scanning = false);
  }

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final pending = ref.watch(smsQueueProvider)
        .where((e) => e.status == 'pending' && e.receivedAt.isAfter(cutoff))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('UPI Auto-Capture'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          if (_enabled)
            IconButton(
              icon: _scanning
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh',
              onPressed: _scanning ? null : () => _scan(),
            ),
          if (pending.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(smsQueueProvider.notifier).clear(),
              child: Text('Clear', style: AppTextStyles.bodySm.copyWith(color: AppColors.text3)),
            ),
        ],
      ),
      body: !_enabled
          ? _EnablePrompt(scanning: _scanning, onEnable: _enable)
          : pending.isEmpty
              ? _EmptyState(scanning: _scanning, onScan: () => _scan())
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Detected from your notifications. Assign each to a customer to record it.',
                              style: AppTextStyles.caption.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: pending.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _SmsTile(entry: pending[i]),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: const SangamBottomNav(currentIndex: 1),
    );
  }
}

class _EnablePrompt extends StatelessWidget {
  final bool scanning;
  final VoidCallback onEnable;

  const _EnablePrompt({required this.scanning, required this.onEnable});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.saffronLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 38,
                color: AppColors.saffron,
              ),
            ),
            const SizedBox(height: 24),
            Text('Auto-capture UPI payments', style: AppTextStyles.h3, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(
              'When someone sends you money via UPI, Sangam will automatically detect it from the notification and add it here — ready for you to assign to a customer.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.text3, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Step-by-step instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to enable:', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _step('1', 'Tap the button below to open settings'),
                  _step('2', 'Find "Sangam" in the list'),
                  _step('3', 'Toggle it ON and confirm'),
                  _step('4', 'Come back to this screen'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Supported apps
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.info),
                      const SizedBox(width: 8),
                      Text('Supported apps', style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w600, color: AppColors.info)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Google Pay • PhonePe • Paytm • BHIM • Amazon Pay • WhatsApp Pay • CRED • Bank Apps (SBI, HDFC, ICICI, etc.)',
                    style: AppTextStyles.caption.copyWith(color: AppColors.info),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Privacy note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined, size: 14, color: AppColors.text4),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Sangam only reads UPI payment notifications. No SMS or personal data is accessed. All data stays on your device.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.text4, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: scanning ? null : onEnable,
                icon: scanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Open Notification Settings'),
              ),
            ),
          ],
        ),
      );

  Widget _step(String num, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(color: AppColors.saffron, shape: BoxShape.circle),
              child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppTextStyles.bodySm)),
          ],
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final bool scanning;
  final VoidCallback onScan;

  const _EmptyState({required this.scanning, required this.onScan});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 48, color: AppColors.border),
            const SizedBox(height: 12),
            Text('No new payments', style: AppTextStyles.h4),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'New UPI payments from GPay, PhonePe and Paytm appear here automatically after notification access is enabled.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: scanning ? null : onScan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
}

class _SmsTile extends ConsumerStatefulWidget {
  final SmsEntry entry;
  const _SmsTile({required this.entry});
  @override
  ConsumerState<_SmsTile> createState() => _STS();
}

class _STS extends ConsumerState<_SmsTile> {
  String? _custId;             // null = new customer, '__walkin__' = walk-in
  late TextEditingController _nameCtrl;
  late TextEditingController _noteCtrl;
  TransactionType? _selectedSource;
  bool _saving = false;
  bool _nameMatched = false;   // true if _nameCtrl matched an existing customer

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.entry.parsedSource;
    _nameCtrl = TextEditingController(text: widget.entry.senderName ?? '');
    _noteCtrl = TextEditingController();
    // Auto-match after first frame when customers load
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoMatch());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  /// If the detected sender name fuzzy-matches an existing customer, pre-select them.
  void _autoMatch() {
    final custs = ref.read(customersStreamProvider).value ?? [];
    if (custs.isEmpty || _nameCtrl.text.isEmpty) return;
    final name = _nameCtrl.text.toLowerCase();
    final match = custs.firstWhereOrNull(
      (c) => c.name.toLowerCase().contains(name) || name.contains(c.name.toLowerCase()),
    );
    if (match != null && mounted) {
      setState(() {
        _custId = match.id;
        _nameCtrl.text = match.name;
        _nameMatched = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersStreamProvider);
    final e = widget.entry;
    final upiSources = [TransactionType.upiGpay, TransactionType.upiPhonePe, TransactionType.upiPaytm];
    final isNewCust = _custId == null && _nameCtrl.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Amount + source badge ──────────────────────
          Row(
            children: [
              if (e.parsedAmount != null)
                Text('₹${e.parsedAmount!.toStringAsFixed(0)}',
                    style: AppTextStyles.h4.copyWith(color: AppColors.success)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _sourceColor(_selectedSource).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedSource?.label ?? 'UPI',
                  style: AppTextStyles.caption.copyWith(
                      color: _sourceColor(_selectedSource), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(e.rawSms, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(_timeAgo(e.receivedAt),
              style: AppTextStyles.caption.copyWith(color: AppColors.text4, fontSize: 11)),
          const SizedBox(height: 14),

          // ── Sender Name (auto-detected, editable) ──────
          Row(
            children: [
              Text('Sender Name', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              if (e.senderName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome_rounded, size: 10, color: AppColors.info),
                    const SizedBox(width: 3),
                    Text('Auto-detected', style: AppTextStyles.caption.copyWith(color: AppColors.info, fontSize: 10)),
                  ]),
                ),
              if (_nameMatched) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.successBg, borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.person_rounded, size: 10, color: AppColors.success),
                    const SizedBox(width: 3),
                    Text('Matched', style: AppTextStyles.caption.copyWith(color: AppColors.success, fontSize: 10)),
                  ]),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          customersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (custs) => TextField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Enter sender name',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: isNewCust
                    ? Tooltip(
                        message: 'Will create new customer',
                        child: const Icon(Icons.person_add_rounded, size: 18, color: AppColors.saffron),
                      )
                    : _nameMatched
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success)
                        : null,
              ),
              onChanged: (val) {
                // Try to match against existing customers as user types
                final name = val.toLowerCase().trim();
                if (name.isEmpty) {
                  setState(() { _custId = null; _nameMatched = false; });
                  return;
                }
                final match = custs.firstWhereOrNull(
                  (c) => c.name.toLowerCase().contains(name) || name.contains(c.name.toLowerCase()),
                );
                setState(() {
                  if (match != null) {
                    _custId = match.id;
                    _nameMatched = true;
                  } else {
                    _custId = null;    // new customer will be created
                    _nameMatched = false;
                  }
                });
              },
            ),
          ),

          // ── Payment Source chips ────────────────────────
          const SizedBox(height: 14),
          Text('Payment Source', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: upiSources.map((src) {
              final isSelected = _selectedSource == src;
              return ChoiceChip(
                label: Text(src.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedSource = src),
                selectedColor: _sourceColor(src).withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: isSelected ? _sourceColor(src) : AppColors.text2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12,
                ),
                side: BorderSide(color: isSelected ? _sourceColor(src) : AppColors.borderLight),
                backgroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
                avatar: isSelected ? Icon(_sourceIcon(src), size: 14, color: _sourceColor(src)) : null,
              );
            }).toList(),
          ),

          // ── What was purchased (note) ───────────────────
          const SizedBox(height: 14),
          Text('Item / Note (optional)', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _noteCtrl,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Groceries, Chai, Atta…',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),

          // ── Walk-in option ──────────────────────────────
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => setState(() {
              _custId = '__walkin__';
              _nameCtrl.text = '';
              _nameMatched = false;
            }),
            child: Row(
              children: [
                Icon(Icons.storefront_rounded, size: 14,
                    color: _custId == '__walkin__' ? AppColors.saffron : AppColors.text4),
                const SizedBox(width: 6),
                Text('Save as Walk-in (no customer record)',
                    style: AppTextStyles.caption.copyWith(
                        color: _custId == '__walkin__' ? AppColors.saffron : AppColors.text4,
                        decoration: TextDecoration.underline)),
              ],
            ),
          ),

          // ── Action buttons ──────────────────────────────
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(smsQueueProvider.notifier).dismiss(e.id),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  child: _saving
                      ? const SizedBox(width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_custId == '__walkin__'
                          ? 'Save Walk-in'
                          : (_nameMatched ? 'Save' : 'Save & Add Customer')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool get _canSave =>
      !_saving &&
      (_custId == '__walkin__' ||
          _nameCtrl.text.trim().isNotEmpty);

  Color _sourceColor(TransactionType? type) {
    switch (type) {
      case TransactionType.upiGpay: return const Color(0xFF4285F4);
      case TransactionType.upiPhonePe: return const Color(0xFF5F259F);
      case TransactionType.upiPaytm: return const Color(0xFF00BAF2);
      default: return AppColors.saffron;
    }
  }

  IconData _sourceIcon(TransactionType? type) {
    switch (type) {
      case TransactionType.upiGpay: return Icons.g_mobiledata_rounded;
      case TransactionType.upiPhonePe: return Icons.phone_android_rounded;
      case TransactionType.upiPaytm: return Icons.account_balance_wallet_rounded;
      default: return Icons.payment_rounded;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final e = widget.entry;
    final isWalkin = _custId == '__walkin__';
    final inputName = _nameCtrl.text.trim();
    String finalCustId;
    String finalCustName;

    if (isWalkin) {
      // Walk-in — no customer record
      finalCustId = '';
      finalCustName = 'Walk-in';
    } else if (_nameMatched && _custId != null) {
      // Matched an existing customer
      final custs = ref.read(customersStreamProvider).value ?? [];
      final cust = custs.firstWhereOrNull((c) => c.id == _custId);
      finalCustId = _custId!;
      finalCustName = cust?.name ?? inputName;
    } else {
      // New customer — create them first so they appear in the Customers screen
      final newId = const Uuid().v4();
      await ref.read(addCustomerProvider)(Customer(
        id: newId,
        name: inputName,
        createdAt: DateTime.now(),
      ));
      finalCustId = newId;
      finalCustName = inputName;
    }

    // Save the UPI transaction linked to the customer
    final note = _noteCtrl.text.trim();
    await ref.read(addTransactionProvider)(
      Transaction(
        id: const Uuid().v4(),
        customerId: isWalkin ? null : finalCustId,
        customerName: finalCustName,
        amount: e.parsedAmount ?? 0,
        type: _selectedSource ?? e.parsedSource ?? TransactionType.upiPaytm,
        direction: TransactionDirection.incoming,
        note: note.isNotEmpty
            ? note
            : 'UPI via ${(_selectedSource ?? e.parsedSource)?.label ?? "UPI"}',
        date: e.receivedAt,
        source: 'notification',
      ),
    );

    ref.read(smsQueueProvider.notifier).dismiss(e.id);
    if (mounted) {
      setState(() => _saving = false);
      context.showSnack(isWalkin
          ? 'Walk-in payment saved!'
          : _nameMatched
              ? 'Payment saved to $finalCustName!'
              : 'Customer "$finalCustName" created & payment saved!');
    }
  }
}
