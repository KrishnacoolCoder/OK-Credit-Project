import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';
import '../../providers/providers.dart';

class BillScreen extends ConsumerStatefulWidget {
  const BillScreen({super.key});

  @override
  ConsumerState<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends ConsumerState<BillScreen> {
  int _selectedIndex = 0; // 0 = Bill, 1 = Quote

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billsStreamProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: AppShadows.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = 0);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 0 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _selectedIndex == 0 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                    ),
                    child: Center(
                      child: Text('Bill', style: TextStyle(color: _selectedIndex == 0 ? AppColors.success : AppColors.text2, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedIndex = 1);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _selectedIndex == 1 ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _selectedIndex == 1 ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null,
                    ),
                    child: Center(
                      child: Text('Quote', style: TextStyle(color: _selectedIndex == 1 ? AppColors.success : AppColors.text2, fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => context.showSnack('Use the filter below to search bills')),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.push('/settings')),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.text2),
                      SizedBox(width: 8),
                      Text('All Time', style: AppTextStyles.bodyMd),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: AppColors.text2),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.filter_list, size: 20, color: AppColors.text1),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceTinted,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: const TextSpan(
                    style: AppTextStyles.bodyMd,
                    children: [
                      TextSpan(text: '₹0 ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      TextSpan(text: 'total Sales', style: TextStyle(color: AppColors.text2)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('₹0', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.text1)),
                    Row(
                      children: [
                        Text('Total GST', style: AppTextStyles.caption.copyWith(color: AppColors.text2)),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.text2),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: billsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
              error: (e, _) => Center(child: Text('$e')),
              data: (bills) {
                if (bills.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(color: AppColors.saffronLight, shape: BoxShape.circle),
                          child: const Center(child: Icon(Icons.receipt_long, size: 64, color: AppColors.saffron)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Create your first kaccha, pakka or GST bills and share',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.saffron,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              context.push('/create-bill');
                            },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add, size: 20),
                                SizedBox(width: 8),
                                Text('Create Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: bills.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final bill = bills[i];
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(bill.customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                              Text('\u20b9${bill.total.toStringAsFixed(0)}', style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${bill.items.length} items', style: AppTextStyles.caption),
                              Text(DateFormat('dd MMM, yyyy').format(bill.date), style: AppTextStyles.caption),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: billsAsync.value?.isNotEmpty == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/create-bill'),
              backgroundColor: AppColors.saffron,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }
}
