import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'constants.dart';

// ── Formatting ──────────────────────────────────────
String fmtRupee(num amount) {
  final formatter = NumberFormat('#,##,###', 'en_IN');
  return '₹${formatter.format(amount.abs())}';
}

String fmtDate(DateTime dt) => DateFormat('d MMM yy').format(dt);
String fmtDateFull(DateTime dt) => DateFormat('EEEE, d MMMM yyyy').format(dt);
String fmtTime(DateTime dt) => DateFormat('h:mm a').format(dt);

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

// ── Customer status ──────────────────────────────────
enum CustomerStatus { settled, dueSoon, overdue, pending }

CustomerStatus getCustomerStatus(num balance, DateTime? lastCreditDate) {
  if (balance <= 0) return CustomerStatus.settled;
  if (lastCreditDate == null) return CustomerStatus.pending;
  final days = DateTime.now().difference(lastCreditDate).inDays;
  if (days > AppConstants.creditDueDays) return CustomerStatus.overdue;
  if (days > AppConstants.creditDueDays - 3) return CustomerStatus.dueSoon;
  return CustomerStatus.pending;
}

String statusLabel(CustomerStatus status, DateTime? lastCreditDate) {
  switch (status) {
    case CustomerStatus.settled: return 'Settled';
    case CustomerStatus.pending: return 'Pending';
    case CustomerStatus.dueSoon:
      if (lastCreditDate == null) return 'Due soon';
      final remaining = AppConstants.creditDueDays - DateTime.now().difference(lastCreditDate).inDays;
      return 'Due in ${remaining}d';
    case CustomerStatus.overdue:
      if (lastCreditDate == null) return 'Overdue';
      final over = DateTime.now().difference(lastCreditDate).inDays - AppConstants.creditDueDays;
      return '${over}d overdue';
  }
}

Color statusColor(CustomerStatus status) {
  switch (status) {
    case CustomerStatus.settled: return AppColors.cash;
    case CustomerStatus.pending: return const Color(0xFFC2410C);
    case CustomerStatus.dueSoon: return AppColors.warning;
    case CustomerStatus.overdue: return AppColors.udhar;
  }
}

Color statusBg(CustomerStatus status) {
  switch (status) {
    case CustomerStatus.settled: return AppColors.cashBg;
    case CustomerStatus.pending: return const Color(0xFFFFF7ED);
    case CustomerStatus.dueSoon: return const Color(0xFFFEF3C7);
    case CustomerStatus.overdue: return AppColors.udharBg;
  }
}

// ── Extensions ──────────────────────────────────────
extension StringExt on String {
  String get initials {
    final parts = trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isValidPhone => RegExp(r'^[6-9]\d{9}$').hasMatch(replaceAll(RegExp(r'\s'), ''));
}

extension ContextExt on BuildContext {
  void showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
      backgroundColor: isError ? AppColors.danger : AppColors.text1,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  bool get isMobile => width < 600;
}
