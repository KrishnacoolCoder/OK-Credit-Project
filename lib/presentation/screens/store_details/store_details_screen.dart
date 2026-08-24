import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../providers/providers.dart';
import '../../../core/context_extensions.dart';

class StoreDetailsScreen extends ConsumerWidget {
  const StoreDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProfileProvider);
    final customersAsync = ref.watch(customersStreamProvider);
    final txnsAsync = ref.watch(transactionsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(store.name.isEmpty ? 'General Store' : store.name),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () => context.push('/help')),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
        error: (e, _) => Center(child: Text('$e')),
        data: (customers) {
          final customerCount = customers.length;
          
          return txnsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.saffron)),
            error: (e, _) => Center(child: Text('$e')),
            data: (txns) {
              // Calculate total balance from all transactions
              // Outgoing (credit given) adds to balance we GET. Incoming (payments) subtracts.
              final totalBalance = txns.fold<double>(0.0, (sum, t) {
                // Ignore cash/upi directly received that wasn't tied to credit if we want pure Khata,
                // but standard ledger math:
                if (t.type.name.contains('upi') || t.type.name == 'cash') {
                   return t.direction.name == 'incoming' ? sum - t.amount : sum + t.amount;
                } else if (t.type.name == 'credit') {
                   return t.direction.name == 'outgoing' ? sum + t.amount : sum - t.amount;
                }
                return sum;
              });

              final balanceLabel = totalBalance >= 0 ? 'You Get' : 'You Give';
              final balanceColor = totalBalance >= 0 ? AppColors.success : AppColors.error;
              final balanceStr = '₹${totalBalance.abs().toStringAsFixed(0)}';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildKhataCard(
                      title: 'Customer Khata',
                      subtitle: '$customerCount Customer${customerCount != 1 ? 's' : ''}',
                      balanceLabel: balanceLabel,
                      balance: balanceStr,
                      balanceColor: balanceColor,
                      icon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildKhataCard(
                      title: 'Supplier Khata',
                      subtitle: '0 Suppliers',
                      balanceLabel: 'You Give',
                      balance: '₹0',
                      balanceColor: AppColors.text3,
                      icon: Icons.local_shipping_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      title: 'View All Customers',
                      icon: Icons.people_outline_rounded,
                      onTap: () => context.push('/customers'),
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      title: 'View Reports',
                      icon: Icons.bar_chart_rounded,
                      onTap: () => context.push('/report'),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildKhataCard({
    required String title,
    required String subtitle,
    required String balanceLabel,
    required String balance,
    required Color balanceColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 0.5),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.success),
              const SizedBox(width: 8),
              const Text('Net Balance', style: AppTextStyles.bodySm),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.text3),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600, color: AppColors.text1)),
              Text(balance, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w700, color: balanceColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppColors.text2),
                  const SizedBox(width: 4),
                  Text(subtitle, style: AppTextStyles.bodySm),
                ],
              ),
              Text(balanceLabel, style: AppTextStyles.bodySm),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required String title, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight, width: 0.5),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: AppColors.success),
            const SizedBox(width: 16),
            Text(title, style: AppTextStyles.bodyMd.copyWith(color: AppColors.text1)),
          ],
        ),
      ),
    );
  }
}
