import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme.dart';
import '../../../domain/entities/bill.dart';
import '../../providers/providers.dart';
import '../../../core/context_extensions.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _customerNameCtrl = TextEditingController();
  final _discountCtrl = TextEditingController();
  final _deliveryCtrl = TextEditingController();
  List<BillItem> _items = [];

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _discountCtrl.dispose();
    _deliveryCtrl.dispose();
    super.dispose();
  }

  void _addItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Add Item', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Item Name *'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(
              controller: rateCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(labelText: 'Rate', prefixText: '\u20b9 '),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: const InputDecoration(labelText: 'Quantity'),
            )),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final rate = double.tryParse(rateCtrl.text.trim()) ?? 0.0;
                final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
                if (name.isEmpty) {
                  context.showSnack('Enter item name', isError: true);
                  return;
                }
                setState(() {
                  _items.add(BillItem(id: const Uuid().v4(), name: name, rate: rate, quantity: qty));
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffron, foregroundColor: Colors.white),
              child: const Text('Add to Bill'),
            ),
          ),
        ]),
      ),
    );
  }

  void _saveBill() async {
    final customer = _customerNameCtrl.text.trim();
    if (customer.isEmpty) {
      context.showSnack('Enter customer name', isError: true);
      return;
    }
    if (_items.isEmpty) {
      context.showSnack('Add at least one item', isError: true);
      return;
    }

    final discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    final delivery = double.tryParse(_deliveryCtrl.text.trim()) ?? 0.0;

    final bill = Bill(
      id: const Uuid().v4(),
      customerName: customer,
      items: _items,
      discount: discount,
      deliveryCharge: delivery,
      date: DateTime.now(),
      status: BillStatus.unpaid,
    );

    await ref.read(addBillProvider)(bill);
    if (mounted) {
      context.pop();
      context.showSnack('Bill created successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = _items.fold(0, (sum, item) => sum + item.total);
    double discount = double.tryParse(_discountCtrl.text.trim()) ?? 0.0;
    double delivery = double.tryParse(_deliveryCtrl.text.trim()) ?? 0.0;
    double total = (subtotal + delivery) - discount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Bill'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderLight, width: 0.5),
            ),
            child: TextField(
              controller: _customerNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ITEMS', style: AppTextStyles.labelCaps),
              TextButton.icon(
                onPressed: () => _addItemSheet(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(foregroundColor: AppColors.saffron),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_items.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceTinted,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: const Center(child: Text('No items added yet', style: AppTextStyles.body)),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return ListTile(
                    title: Text(item.name, style: AppTextStyles.bodyMd),
                    subtitle: Text('${item.quantity} x \u20b9${item.rate}', style: AppTextStyles.caption),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\u20b9${item.total.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                          onPressed: () => setState(() => _items.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          const Text('CHARGES & DISCOUNTS', style: AppTextStyles.labelCaps),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _deliveryCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Delivery (+)', border: InputBorder.none),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => setState(() {}),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    decoration: const InputDecoration(labelText: 'Discount (-)', border: InputBorder.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bill Total', style: AppTextStyles.caption),
                Text('\u20b9${total.toStringAsFixed(0)}', style: AppTextStyles.h2),
              ],
            ),
            ElevatedButton(
              onPressed: _saveBill,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
