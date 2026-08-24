import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme.dart';
import '../../../core/l10n.dart';
import '../../providers/providers.dart';
import '../../widgets/bottom_nav.dart';
import '../../../core/context_extensions.dart';

import '../../../domain/entities/app_notification.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedFilter = 0; // 0: Customer, 1: Supplier, 2: Due Today
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
      _searchQuery = '';
      _searchController.clear();
    });
    Future.delayed(const Duration(milliseconds: 100), () => _searchFocus.requestFocus());
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _shareStore() {
    final store = ref.read(storeProfileProvider);
    final name = store.name.isEmpty ? 'My Store' : store.name;
    final phone = (store.phone ?? '').isEmpty ? '' : '\n📞 ${store.phone}';
    Share.share(
      '📒 $name uses Sangam Pro to manage credit, UPI payments & customer ledger.$phone\n\n'
      'Download Sangam Pro now 👇\n'
      'https://play.google.com/store/apps/details?id=com.sangam.pro',
      subject: '$name - Sangam Pro',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(storeProfileProvider);
    final customersAsync = ref.watch(customersStreamProvider);
    final totalsAsync = ref.watch(todayTotalsProvider);
    final overdueAsync = ref.watch(overdueCustomersProvider);
    final hi = ref.watch(languageProvider);
    final canEdit = ref.watch(currentUserProvider)?.canEdit ?? true;
    final pendingUpi = ref.watch(smsQueueProvider).where((e) => e.status == 'pending').length;
    final unreadNotifications = ref.watch(appNotificationsProvider).where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFFF3F7F6),
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: true,
            snap: true,
            leadingWidth: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.saffron,
                      child: Text(
                        store.name.isNotEmpty ? store.name[0].toUpperCase() : 'S',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      hintText: tr('Search customers...', 'ग्राहक खोजें...', hi),
                      hintStyle: AppTextStyles.body.copyWith(color: AppColors.text3),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                : GestureDetector(
                    onTap: () => context.push('/store-details'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name.isEmpty ? tr('My Store', 'मेरी दुकान', hi) : store.name,
                          style: AppTextStyles.h4.copyWith(color: AppColors.text1),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        Text(tr('Tap to manage', 'दुकान देखें', hi), style: AppTextStyles.caption),
                      ],
                    ),
                  ),
            actions: _isSearching
                ? [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.text2,
                      onPressed: _closeSearch,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.share_rounded),
                      color: AppColors.text2,
                      style: IconButton.styleFrom(backgroundColor: AppColors.borderLight, shape: const CircleBorder()),
                      onPressed: _shareStore,
                    ),
                    const SizedBox(width: 4),
                    // Notifications badge
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded),
                          color: AppColors.text2,
                          style: IconButton.styleFrom(backgroundColor: AppColors.borderLight, shape: const CircleBorder()),
                          onPressed: () => context.push('/notifications'),
                        ),
                        if (unreadNotifications > 0)
                          Positioned(
                            right: 4, top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                              child: Text('$unreadNotifications', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.search_rounded),
                      color: AppColors.text2,
                      style: IconButton.styleFrom(backgroundColor: AppColors.borderLight, shape: const CircleBorder()),
                      onPressed: _openSearch,
                    ),
                    const SizedBox(width: 16),
                  ],
          ),
        ],
        body: CustomScrollView(
          slivers: [
            // ── Today's Collection Card ──
            SliverToBoxAdapter(
              child: totalsAsync.when(
                loading: () => const SizedBox(height: 8),
                error: (_, __) => const SizedBox(),
                data: (totals) => Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppGradients.saffron,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.saffron,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr("Today's Collection", 'आज की वसूली', hi),
                          style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(
                        '₹${totals.totalIn.toStringAsFixed(0)}',
                        style: AppTextStyles.amount.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(children: [
                        _SummaryChip(
                          label: tr('Received', 'प्राप्त', hi),
                          value: '₹${totals.totalIn.toStringAsFixed(0)}',
                          icon: Icons.arrow_downward_rounded,
                        ),
                        const SizedBox(width: 12),
                        _SummaryChip(
                          label: tr('Credit Out', 'उधार', hi),
                          value: '₹${totals.creditOut.toStringAsFixed(0)}',
                          icon: Icons.arrow_upward_rounded,
                          isNegative: true,
                        ),
                      ]),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
              ),
            ),

            // ── Overdue Warning ──
            SliverToBoxAdapter(
              child: overdueAsync.when(
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
                data: (overdue) => overdue.isEmpty ? const SizedBox() : Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(
                      '${overdue.length} ${tr("customers overdue", "ग्राहक बाकी हैं", hi)}',
                      style: AppTextStyles.bodySm.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                    )),
                    TextButton(
                      onPressed: () => context.push('/report'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                      child: Text(tr('View', 'देखें', hi),
                          style: AppTextStyles.btnSm.copyWith(color: AppColors.error)),
                    ),
                  ]),
                ),
              ),
            ),

            // ── White container with filter + list ──
            SliverFillRemaining(
              hasScrollBody: true,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Filter tabs
                    if (!_isSearching)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(children: [
                          _FilterChip(label: tr('Customer', 'ग्राहक', hi), active: _selectedFilter == 0, onTap: () => setState(() => _selectedFilter = 0)),
                          const SizedBox(width: 8),
                          _FilterChip(label: tr('Supplier', 'सप्लायर', hi), active: _selectedFilter == 1, onTap: () => setState(() => _selectedFilter = 1)),
                          const SizedBox(width: 8),
                          _FilterChip(label: tr('Due Today', 'आज बाकी', hi), active: _selectedFilter == 2, onTap: () => setState(() => _selectedFilter = 2)),
                          const SizedBox(width: 8),
                          _FilterChip(label: '+', active: false, onTap: () {}),
                        ]),
                      ),
                    if (!_isSearching) const SizedBox(height: 16),

                    // Net Balance Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F7F6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: customersAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox(),
                          data: (customers) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_isSearching ? 'Search Results' : 'Net Balance',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.text1)),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.text3),
                                        const SizedBox(width: 4),
                                        Text('${customers.length} Accounts', style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                                      ]),
                                    ],
                                  ),
                                ),
                                if (!_isSearching)
                                  totalsAsync.when(
                                    loading: () => const SizedBox(),
                                    error: (_, __) => const SizedBox(),
                                    data: (totals) {
                                      final net = totals.creditOut - totals.totalIn;
                                      final isDue = net > 0;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('₹${net.abs().toStringAsFixed(0)}',
                                              style: AppTextStyles.h3.copyWith(color: isDue ? AppColors.udhar : AppColors.success)),
                                          Text(isDue ? 'You Get' : 'You Give',
                                              style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                                        ],
                                      );
                                    },
                                  ),
                                if (!_isSearching) ...[
                                  const SizedBox(width: 16),
                                  Container(width: 1, height: 32, color: AppColors.border),
                                  const SizedBox(width: 12),
                                  const Icon(Icons.filter_list_rounded, color: AppColors.text1),
                                ],
                              ],
                            );
                          },
                        ),
                      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
                    ),
                    const SizedBox(height: 8),

                    // Customer List
                    Expanded(
                      child: customersAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (customers) {
                          // Apply search filter
                          var filtered = customers;
                          if (_isSearching && _searchQuery.isNotEmpty) {
                            filtered = customers.where((c) {
                              return c.name.toLowerCase().contains(_searchQuery) ||
                                     (c.phone ?? '').contains(_searchQuery);
                            }).toList();
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: SingleChildScrollView(
                                child: Column(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded, size: 64, color: AppColors.border),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isSearching
                                        ? tr('No results for "$_searchQuery"', 'कोई परिणाम नहीं', hi)
                                        : tr('No customers yet', 'अभी कोई ग्राहक नहीं', hi),
                                    style: AppTextStyles.body,
                                  ),
                                ]),
                              ),
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: filtered.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, indent: 70),
                            itemBuilder: (context, i) {
                              final c = filtered[i];
                              return _DashboardCustomerTile(
                                customerId: c.id,
                                customerName: c.name,
                                phone: c.phone ?? '',
                                dateAdded: c.createdAt,
                              ).animate(delay: Duration(milliseconds: i * 40)).fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => context.go('/customers'),
              backgroundColor: const Color(0xFFCDE0D9),
              foregroundColor: const Color(0xFF1B4E3B),
              elevation: 4,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(tr('Add Customer', 'ग्राहक जोड़ें', hi),
                  style: AppTextStyles.btn.copyWith(color: const Color(0xFF1B4E3B))),
            )
          : null,
      bottomNavigationBar: const SangamBottomNav(currentIndex: 0),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool isNegative;
  const _SummaryChip({required this.label, required this.value, required this.icon, this.isNegative = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Poppins')),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Poppins')),
        ]),
      ]),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFFF3F7F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.success : const Color(0xFFE5EBE9), width: active ? 1.5 : 1),
        ),
        child: Text(label, style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: active ? AppColors.success : AppColors.text2,
        )),
      ),
    );
  }
}

class _DashboardCustomerTile extends ConsumerWidget {
  final String customerId, customerName, phone;
  final DateTime dateAdded;
  const _DashboardCustomerTile({required this.customerId, required this.customerName, required this.phone, required this.dateAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balAsync = ref.watch(customerBalanceProvider(customerId));

    // Generate a stable color from the customer name
    final colors = [
      const Color(0xFF8B6BCC), // Purple
      const Color(0xFFE29578), // Coral
      const Color(0xFF006D77), // Teal
      const Color(0xFFD97706), // Amber
      const Color(0xFF059669), // Green
      const Color(0xFFE11D48), // Rose
      const Color(0xFF1A73E8), // Blue
    ];
    final avatarColor = colors[customerName.hashCode.abs() % colors.length];

    return InkWell(
      onTap: () => context.push('/customer/$customerId'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                customerName.isNotEmpty ? customerName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20, fontFamily: 'Poppins'),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Name + subtitle
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              phone.isNotEmpty ? '$customerName ($phone)' : customerName,
              style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            balAsync.when(
              loading: () => Container(height: 10, width: 80, decoration: BoxDecoration(color: AppColors.borderLight, borderRadius: BorderRadius.circular(4))),
              error: (_, __) => const SizedBox(),
              data: (bal) {
                if (bal > 0) {
                  return Row(children: [
                    const Icon(Icons.check_rounded, size: 12, color: AppColors.text3),
                    const SizedBox(width: 4),
                    Text('₹${bal.toStringAsFixed(0)} Payment Added on ${DateFormat('dd MMM, yyyy').format(dateAdded)}',
                        style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                  ]);
                }
                return Row(children: [
                  const Icon(Icons.person_outline_rounded, size: 12, color: AppColors.text3),
                  const SizedBox(width: 4),
                  Text('Added On ${DateFormat('dd MMM, yyyy').format(dateAdded)}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.text3)),
                ]);
              },
            ),
          ])),
          // Balance
          balAsync.when(
            loading: () => const SizedBox(width: 40, child: LinearProgressIndicator()),
            error: (_, __) => const SizedBox(),
            data: (bal) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                '₹${bal.abs().toStringAsFixed(0)}',
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: bal > 0 ? AppColors.udhar : AppColors.success,
                ),
              ),
              Text(
                bal > 0 ? 'Due' : (bal < 0 ? 'Advance' : ''),
                style: AppTextStyles.caption.copyWith(color: AppColors.text3),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
