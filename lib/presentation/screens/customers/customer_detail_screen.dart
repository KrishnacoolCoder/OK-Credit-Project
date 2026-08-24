import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/transaction.dart';
import '../../providers/providers.dart';
import '../../../core/context_extensions.dart';

class CustomerDetailScreen extends ConsumerStatefulWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});
  @override
  ConsumerState<CustomerDetailScreen> createState() => _S();
}

class _S extends ConsumerState<CustomerDetailScreen> {

  Future<void> _whatsapp(String name, String phone, double balance) async {
    final storeName = ref.read(storeProfileProvider).name;
    final shop = storeName.isEmpty ? 'our store' : storeName;
    final msg = Uri.encodeComponent('Namaste $name ji,\n\nAapka $shop mein \u20b9${balance.toStringAsFixed(0)} baaki hai.\n\nKripya jaldi payment karein.\n\n- $shop');
    final url = Uri.parse('https://wa.me/91$phone?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _showInputSheet(BuildContext context, bool isReceived, String customerName) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    TransactionType payType = isReceived ? TransactionType.upiPaytm : TransactionType.credit;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setStateSheet) {
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isReceived ? 'Payment Received' : 'Credit Given',
                      style: AppTextStyles.h4.copyWith(color: isReceived ? AppColors.success : AppColors.udhar),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),
                // Amount field
                TextField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.h1,
                  autofocus: true,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    hintText: '0',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: 12),
                // Items / Note field
                TextField(
                  controller: noteCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTextStyles.bodyMd,
                  decoration: InputDecoration(
                    hintText: isReceived ? 'Add note (e.g. Partial payment)' : 'Items given (e.g. Atta 10kg, Dal 2kg)',
                    hintStyle: AppTextStyles.body.copyWith(color: AppColors.text4),
                    prefixIcon: Icon(
                      isReceived ? Icons.note_alt_outlined : Icons.shopping_bag_outlined,
                      color: AppColors.text3, size: 20,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isReceived ? AppColors.success : AppColors.udhar, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                // Quick item chips for "Given"
                if (!isReceived)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Atta', 'Dal', 'Rice', 'Sugar', 'Oil', 'Soap', 'Tea', 'Milk'].map((item) {
                      return GestureDetector(
                        onTap: () {
                          final current = noteCtrl.text.trim();
                          noteCtrl.text = current.isEmpty ? item : '$current, $item';
                          noteCtrl.selection = TextSelection.fromPosition(TextPosition(offset: noteCtrl.text.length));
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceTinted,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Text(item, style: AppTextStyles.bodySm.copyWith(color: AppColors.text2, fontWeight: FontWeight.w500)),
                        ),
                      );
                    }).toList(),
                  ),
                if (!isReceived) const SizedBox(height: 16),
                // Payment type selector for received
                if (isReceived)
                  Row(children: [TransactionType.upiPaytm, TransactionType.upiGpay, TransactionType.upiPhonePe, TransactionType.cash].map((t) {
                    final colors = {TransactionType.upiPaytm: AppColors.paytm, TransactionType.upiGpay: AppColors.gpay, TransactionType.upiPhonePe: AppColors.phonePe, TransactionType.cash: AppColors.cash};
                    return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: GestureDetector(
                      onTap: () => setStateSheet(() => payType = t),
                      child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(color: payType == t ? colors[t] : AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: payType == t ? colors[t]! : AppColors.border)),
                        child: Text(t.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: payType == t ? Colors.white : AppColors.text2))),
                    )));
                  }).toList()),
                if (isReceived) const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      final amt = double.tryParse(amtCtrl.text.trim());
                      if (amt == null || amt <= 0) return;
                      setStateSheet(() => saving = true);
                      final note = noteCtrl.text.trim();
                      await ref.read(addTransactionProvider)(Transaction(
                        id: const Uuid().v4(), customerId: widget.customerId, customerName: customerName,
                        amount: amt, type: payType,
                        direction: isReceived ? TransactionDirection.incoming : TransactionDirection.outgoing,
                        note: note.isEmpty ? (isReceived ? 'Payment received' : 'Items on credit') : note,
                        date: DateTime.now(), source: 'manual',
                      ));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReceived ? AppColors.success : AppColors.udhar,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: saving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Save', style: AppTextStyles.btn),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }


  @override
  Widget build(BuildContext context) {
    final custsAsync = ref.watch(customersStreamProvider);
    final balAsync = ref.watch(customerBalanceProvider(widget.customerId));
    final txnsAsync = ref.watch(customerTransactionsProvider(widget.customerId));
    final customer = custsAsync.value?.where((c) => c.id == widget.customerId).firstOrNull;
    final canEdit = ref.watch(currentUserProvider)?.canEdit ?? true;

    final customerName = customer?.name ?? '…';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF8B6BCC),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer?.phone != null ? '$customerName (${customer?.phone})' : customerName,
                    style: AppTextStyles.h4.copyWith(color: AppColors.text1),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('View Profile', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.receipt_long_outlined, color: AppColors.text1), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.text1), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.borderLight, height: 1),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: txnsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (txns) {
                if (txns.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security_rounded, size: 80, color: AppColors.success),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            'All transactions between you and customers are totally private & secure.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMd.copyWith(color: AppColors.text1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Group by date
                final grouped = groupBy(txns, (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day));
                final sortedKeys = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, i) {
                    final date = sortedKeys[i];
                    final dayTxns = grouped[date]!;
                    dayTxns.sort((a, b) => a.date.compareTo(b.date));

                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF86A8A0), // Teal-ish pill
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...dayTxns.map((t) {
                          final isReceived = t.direction == TransactionDirection.incoming;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Column(
                              crossAxisAlignment: isReceived ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width * 0.6,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderLight),
                                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(isReceived ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, 
                                                size: 18, color: AppColors.text1),
                                              const SizedBox(width: 4),
                                              Text('₹${t.amount.toStringAsFixed(0)}', style: AppTextStyles.h4),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Text(DateFormat('hh:mm a').format(t.date), style: AppTextStyles.caption.copyWith(fontSize: 10)),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.check, size: 12, color: AppColors.text3),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(t.note ?? (isReceived ? 'Cash paid' : 'Items on credit'), style: AppTextStyles.caption),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Simplified running balance logic for UI (proper running balance needs full ledger calc)
                                Text('₹${t.amount.toStringAsFixed(0)} Due', style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          
          // Fixed Bottom Bar Area
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F6),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "More" mini bar
                Container(
                  color: const Color(0xFFD6E3DF),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _MiniIcon(Icons.receipt_long_outlined),
                      const SizedBox(width: 12),
                      _MiniIcon(Icons.chat_bubble_outline_rounded),
                      const SizedBox(width: 12),
                      _MiniIcon(Icons.phone_outlined),
                      const SizedBox(width: 12),
                      _MiniIcon(Icons.phone_android_rounded), // fallback for whatsapp
                      const Spacer(),
                      const Text('More •••', style: TextStyle(color: AppColors.text1, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF86A8A0)),
                            foregroundColor: const Color(0xFF1B4E3B),
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.calendar_month_outlined, size: 16),
                          label: const Text('Due Date', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4E3B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.phone, size: 16),
                          label: const Text('Call', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => customer?.phone != null ? _whatsapp(customerName, customer!.phone!, 0) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B4E3B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.chat, size: 16), // Using chat as whatsapp fallback
                          label: const Text('Remind', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Balance Due Row
                Container(
                  color: const Color(0xFFF3F7F6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Balance Due', style: TextStyle(color: AppColors.text2, fontWeight: FontWeight.w500)),
                      balAsync.when(
                        loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        error: (_, __) => const SizedBox(),
                        data: (bal) => Row(
                          children: [
                            Text(
                              bal > 0 ? '₹${bal.toStringAsFixed(0)}' : '₹0',
                              style: TextStyle(color: AppColors.udhar, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.udhar, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Primary Received / Given Buttons
                if (canEdit)
                  Container(
                    color: const Color(0xFFF3F7F6),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showInputSheet(context, true, customerName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.success,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                            label: const Text('Received', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showInputSheet(context, false, customerName),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.udhar,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                            label: const Text('Given', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIcon extends StatelessWidget {
  final IconData icon;
  const _MiniIcon(this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 14, color: AppColors.text3),
    );
  }
}
