import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/l10n.dart';
import '../providers/providers.dart';

class SangamBottomNav extends ConsumerStatefulWidget {
  final int currentIndex;
  const SangamBottomNav({super.key, required this.currentIndex});

  @override
  ConsumerState<SangamBottomNav> createState() => _SangamBottomNavState();
}

class _SangamBottomNavState extends ConsumerState<SangamBottomNav> {
  bool _isMoreMenuOpen = false;

  void _showMoreMenu(BuildContext context, bool isHi) {
    setState(() => _isMoreMenuOpen = true);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 4,
              mainAxisSpacing: 24,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75, // Give more vertical space for text
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MoreMenuItem(
                  icon: Icons.account_circle_outlined,
                  label: tr('Account', 'खाता', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/account');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.person_outline_rounded,
                  label: tr('Profile', 'प्रोफ़ाइल', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/profile');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.help_outline_rounded,
                  label: tr('Help', 'सहायता', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/help');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.settings_outlined,
                  label: tr('Settings', 'सेटिंग्स', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/settings');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.receipt_outlined,
                  label: tr('Bills', 'बिल', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/bill');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.inventory_2_outlined,
                  label: tr('Stock Management', 'स्टॉक', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/stock');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.devices_rounded,
                  label: tr('Multi Device', 'मल्टी डिवाइस', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/multi-device');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.edit_calendar_rounded,
                  label: tr('Auto Reminder', 'ऑटो रिमाइंडर', isHi),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/auto-reminder');
                  },
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() => _isMoreMenuOpen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hi = ref.watch(languageProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(color: AppColors.saffron.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.menu_book_rounded,
                activeIcon: Icons.menu_book_rounded,
                label: tr('Ledger', 'लेजर', hi),
                index: 0,
                current: widget.currentIndex,
                onTap: () {
                  if (widget.currentIndex != 0) context.go('/dashboard');
                },
              ),
              _NavItem(
                icon: Icons.account_balance_outlined,
                activeIcon: Icons.account_balance_rounded,
                label: tr('Bank/UPI', 'बैंक/UPI', hi),
                index: 1,
                current: widget.currentIndex,
                onTap: () {
                  if (widget.currentIndex != 1) context.go('/sms-queue');
                },
              ),
              _NavItem(
                icon: Icons.paste_rounded,
                activeIcon: Icons.paste_rounded,
                label: tr('Paste SMS', 'SMS चिपकाएं', hi),
                index: 2,
                current: widget.currentIndex,
                onTap: () {
                  if (widget.currentIndex != 2) context.go('/paste-sms');
                },
              ),
              _NavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart_rounded,
                label: tr('Report', 'रिपोर्ट', hi),
                index: 3,
                current: widget.currentIndex,
                onTap: () {
                  if (widget.currentIndex != 3) context.go('/report');
                },
              ),
              _NavItem(
                icon: _isMoreMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                activeIcon: Icons.close_rounded,
                label: tr('More', 'और', hi),
                index: 4,
                current: _isMoreMenuOpen ? 4 : -1,
                onTap: () {
                  if (!_isMoreMenuOpen) {
                    _showMoreMenu(context, hi);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index, current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(horizontal: active ? 20 : 8, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.saffronLight : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                active ? activeIcon : icon,
                size: 24,
                color: active ? AppColors.saffron : AppColors.text3,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.saffron : AppColors.text3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.saffronLight.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.saffron, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              color: AppColors.text2,
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
