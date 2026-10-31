import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:numpe/config/api_config.dart';
import 'package:numpe/app.dart';
import 'package:numpe/navigation/app_router.dart';
import 'package:numpe/services/session_service.dart';

void main() {
  setUp(() {
    SessionService.instance.setMode(AppMode.demo);
    appRouter.go('/welcome');
  });

  testWidgets('shows the NUMPE welcome and simulated app disclaimer',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NumpeApp());
    await tester.pumpAndSettle();

    expect(find.text('NUMPE'), findsOneWidget);
    expect(find.text('Smart Payments.\nSafer Transactions.'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Demo only. No real money, bank accounts or UPI network.'),
        findsOneWidget);
  });

  testWidgets('user can enter demo mode and open Scam Shield',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const NumpeApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue in demo mode'));
    await tester.pumpAndSettle();

    expect(find.text('Demo balance'), findsOneWidget);
    expect(find.text('₹12450.75'), findsOneWidget);
    await tester.tap(find.text('Shield'));
    await tester.pumpAndSettle();
    expect(find.text('UPI Scam Shield'), findsOneWidget);
    expect(find.text('Check suspicious content'), findsOneWidget);
  });

  testWidgets('live dashboard hides fabricated demo balances and payments',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SessionService.instance.setMode(AppMode.live);
    appRouter.go('/home');
    await tester.pumpWidget(const NumpeApp());
    await tester.pumpAndSettle();

    expect(find.text('No backend balance endpoint'), findsOneWidget);
    expect(find.text('Coffee House'), findsNothing);
    expect(find.text('No account or balance endpoint is configured.'),
        findsOneWidget);
  });
}
