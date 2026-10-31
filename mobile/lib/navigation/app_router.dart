import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/payment.dart';
import '../screens/awareness_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/payment_review_screen.dart';
import '../screens/payment_result_screen.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/receive_screen.dart';
import '../screens/register_screen.dart';
import '../screens/report_screen.dart';
import '../screens/request_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/send_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../widgets/numpe_page.dart';
import '../widgets/numpe_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/send',
      name: 'send',
      builder: (context, state) => SendScreen(
        initialDraft: state.extra is PaymentDraft
            ? state.extra! as PaymentDraft
            : null,
      ),
    ),
    GoRoute(
      path: '/review',
      name: 'payment-review',
      builder: (context, state) {
        final arguments = state.extra;
        if (arguments is! PaymentReviewArgs) {
          return const NumpePage(
            title: 'Payment review',
            child: Center(child: Text('Payment details are unavailable.')),
          );
        }
        return PaymentReviewScreen(arguments: arguments);
      },
    ),
    GoRoute(
      path: '/payment-result',
      name: 'payment-result',
      builder: (context, state) {
        final receipt = state.extra;
        if (receipt is! PaymentReceipt) {
          return const NumpePage(
            title: 'Payment result',
            child: Center(child: Text('Payment result is unavailable.')),
          );
        }
        return PaymentResultScreen(receipt: receipt);
      },
    ),
    GoRoute(
      path: '/receive',
      name: 'receive',
      builder: (context, state) => const ReceiveScreen(),
    ),
    GoRoute(
      path: '/request',
      name: 'request',
      builder: (context, state) => const RequestScreen(),
    ),
    GoRoute(
      path: '/scan',
      name: 'qr-scan',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/analyze',
      name: 'analysis',
      builder: (context, state) => ScanScreen(
        initialInput: state.extra is String ? state.extra! as String : null,
      ),
    ),
    GoRoute(
      path: '/report',
      name: 'report',
      builder: (context, state) => const ReportScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) =>
          NumpeShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeScreen()),
        ),
        GoRoute(
          path: '/activity',
          name: 'activity',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/shield',
          name: 'shield',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AwarenessScreen()),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
  ],
);
