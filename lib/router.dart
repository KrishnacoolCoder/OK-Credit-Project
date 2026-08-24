import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/onboarding/permission_screen.dart';
import 'presentation/screens/store_setup/store_setup_screen.dart';
import 'presentation/screens/auth/google_login_screen.dart';
import 'presentation/screens/auth/staff_join_screen.dart';
import 'presentation/screens/auth/language_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/add_transaction/add_transaction_screen.dart';
import 'presentation/screens/customers/customers_screen.dart';
import 'presentation/screens/customers/customer_detail_screen.dart';
import 'presentation/screens/report/report_screen.dart';
import 'presentation/screens/staff/staff_screen.dart';
import 'presentation/screens/sms_queue/sms_queue_screen.dart';
import 'presentation/screens/paste_sms/paste_sms_screen.dart';
import 'presentation/screens/auto_reminder/auto_reminder_screen.dart';
import 'presentation/screens/bill/bill_screen.dart';
import 'presentation/screens/bill/create_bill_screen.dart';
import 'presentation/screens/store_details/store_details_screen.dart';
import 'presentation/screens/stock/stock_screen.dart';
import 'presentation/screens/multi_device/multi_device_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/team_screen.dart';
import 'presentation/screens/settings/change_mobile_screen.dart';
import 'presentation/screens/settings/backup_screen.dart';
import 'presentation/screens/settings/upi_qr_screen.dart';
import 'presentation/screens/settings/security_checkup_screen.dart';
import 'presentation/screens/settings/security_settings_screen.dart';
import 'presentation/screens/notifications/notifications_screen.dart';

import 'presentation/screens/account/account_screen.dart';
import 'presentation/screens/help/help_screen.dart';

GoRouter buildRouter() => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',       builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding',   builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/permissions',  builder: (_, __) => const PermissionScreen()),
    GoRoute(path: '/store-setup',  builder: (_, __) => const StoreSetupScreen()),
    GoRoute(path: '/language',     builder: (_, __) => const LanguageScreen()),
    GoRoute(path: '/login',        builder: (_, __) => const GoogleLoginScreen()),
    GoRoute(path: '/staff-signup', builder: (_, __) => const StaffSignupScreen()),
    GoRoute(path: '/dashboard',    builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/add',          builder: (_, __) => const AddTransactionScreen()),
    GoRoute(path: '/customers',    builder: (_, __) => const CustomersScreen()),
    GoRoute(path: '/customer/:id', builder: (_, state) => CustomerDetailScreen(customerId: state.pathParameters['id']!)),
    GoRoute(path: '/report',       builder: (_, __) => const ReportScreen()),
    GoRoute(path: '/staff',        builder: (_, __) => const StaffScreen()),
    GoRoute(path: '/sms-queue',    builder: (_, __) => const SmsQueueScreen()),
    GoRoute(path: '/paste-sms',    builder: (_, __) => const PasteSmsScreen()),
    GoRoute(path: '/auto-reminder',builder: (_, __) => const AutoReminderScreen()),
    GoRoute(path: '/bill',         builder: (_, __) => const BillScreen()),
    GoRoute(path: '/create-bill',  builder: (_, __) => const CreateBillScreen()),
    GoRoute(path: '/store-details',builder: (_, __) => const StoreDetailsScreen()),
    GoRoute(path: '/stock',        builder: (_, __) => const StockScreen()),
    GoRoute(path: '/multi-device', builder: (_, __) => const MultiDeviceScreen()),
    GoRoute(path: '/profile',      builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/account',      builder: (_, __) => const AccountScreen()),
    GoRoute(path: '/help',          builder: (_, __) => const HelpScreen()),
    GoRoute(path: '/settings',     builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/team',         builder: (_, __) => const TeamScreen()),
    GoRoute(path: '/change-mobile',builder: (_, __) => const ChangeMobileScreen()),
    GoRoute(path: '/backup',       builder: (_, __) => const BackupScreen()),
    GoRoute(path: '/upi-qr',       builder: (_, __) => const UpiQrScreen()),
    GoRoute(path: '/security-checkup', builder: (_, __) => const SecurityCheckupScreen()),
    GoRoute(path: '/security',     builder: (_, __) => const SecuritySettingsScreen()),
    GoRoute(path: '/notifications',builder: (_, __) => const NotificationsScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Not found: ${state.error}'))),
);
