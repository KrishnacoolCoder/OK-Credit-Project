import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme.dart';
import '../../../core/context_extensions.dart';
import '../../providers/providers.dart';

class AutoReminderScreen extends ConsumerStatefulWidget {
  const AutoReminderScreen({super.key});

  @override
  ConsumerState<AutoReminderScreen> createState() => _AutoReminderScreenState();
}

class _AutoReminderScreenState extends ConsumerState<AutoReminderScreen> {
  bool _isEnabled = true;
  DateTime _startDate = DateTime.now();
  
  Set<String> _selectedIds = {};
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _sortBy = 'amount'; // 'amount' or 'days'

  @override
  Widget build(BuildContext context) {
    final overdueAsync = ref.watch(overdueCustomersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: _isSearchActive 
          ? TextField(
              autofocus: true,
              style: AppTextStyles.bodyMd,
              decoration: const InputDecoration(
                hintText: 'Search customers...',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
            )
          : const Text('Auto Reminder'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          IconButton(
            icon: Icon(_isSearchActive ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearchActive = !_isSearchActive;
                if (!_isSearchActive) _searchQuery = '';
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight, width: 0.5),
                boxShadow: AppShadows.sm,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text('Sent in last 7 days (0)', style: AppTextStyles.bodyMd),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: AppShadows.sm,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isEnabled = true);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _isEnabled ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: _isEnabled ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                          ),
                          child: Text('Enable', style: TextStyle(color: _isEnabled ? AppColors.success : AppColors.text2, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isEnabled = false);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: !_isEnabled ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: !_isEnabled ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : null,
                          ),
                          child: Text('Disable', style: TextStyle(color: !_isEnabled ? AppColors.error : AppColors.text2, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(icon: const Icon(Icons.filter_list), onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                    builder: (ctx) => Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('Filter Reminders', style: AppTextStyles.h4),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.sort_rounded, color: AppColors.saffron),
                          title: const Text('Sort by amount (high to low)'),
                          trailing: _sortBy == 'amount' ? const Icon(Icons.check, color: AppColors.success) : null,
                          onTap: () {
                            setState(() => _sortBy = 'amount');
                            Navigator.pop(ctx);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.calendar_today_rounded, color: AppColors.saffron),
                          title: const Text('Sort by days overdue'),
                          trailing: _sortBy == 'days' ? const Icon(Icons.check, color: AppColors.success) : null,
                          onTap: () {
                            setState(() => _sortBy = 'days');
                            Navigator.pop(ctx);
                          },
                        ),
                        const SizedBox(height: 8),
                      ]),
                    ),
                  );
                }),
                IconButton(icon: const Icon(Icons.select_all_rounded), onPressed: () {
                  HapticFeedback.selectionClick();
                  overdueAsync.whenData((overdue) {
                    setState(() {
                      if (_selectedIds.length == overdue.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds = overdue.map((e) => e.customerId).toSet();
                      }
                    });
                  });
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: overdueAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.success)),
              error: (e, _) => Center(child: Text('$e')),
              data: (overdue) {
                // Apply Search
                var filtered = overdue.where((o) => o.customerName.toLowerCase().contains(_searchQuery)).toList();
                
                // Apply Sort
                if (_sortBy == 'amount') {
                  filtered.sort((a, b) => b.balance.compareTo(a.balance));
                } else {
                  filtered.sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));
                }

                if (filtered.isEmpty) {
                  return const Center(child: Text('No customers found', style: AppTextStyles.bodyMd));
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final o = filtered[index];
                    final isSelected = _selectedIds.contains(o.customerId);
                    
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(o.customerId);
                          } else {
                            _selectedIds.add(o.customerId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF0F8F6) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? AppColors.success : AppColors.borderLight, width: isSelected ? 1.5 : 0.5),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.saffronLight,
                              child: Text(o.customerName[0].toUpperCase(), style: const TextStyle(color: AppColors.saffron)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.customerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('\u20b9${o.balance.toStringAsFixed(0)}', style: AppTextStyles.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.w600)),
                                      Text(' Due since ${o.daysOverdue}d', style: AppTextStyles.bodySm.copyWith(color: AppColors.text2)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                              color: isSelected ? AppColors.success : AppColors.text3,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: Duration(milliseconds: 20 * index)).slideX(begin: 0.05),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Start Date', style: AppTextStyles.bodyMd),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _startDate = date);
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 16, color: AppColors.success),
                        const SizedBox(width: 4),
                        Text(DateFormat('dd MMM yyyy').format(_startDate), style: AppTextStyles.bodyMd.copyWith(color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_selectedIds.isEmpty ? 'Auto Reminder Settings Saved' : 'Reminders queued for ${_selectedIds.length} customers'))
                    );
                    context.pop();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _selectedIds.isEmpty ? 'Confirm Settings' : 'Remind ${_selectedIds.length} Customers', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
