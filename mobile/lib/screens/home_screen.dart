import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../services/mock_data_service.dart';
import '../services/notification_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
=======

import 'qr_scanner_screen.dart';
import 'scan_screen.dart';
import 'screenshot_screen.dart';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

<<<<<<< HEAD
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SessionService.instance,
      builder: (context, _) {
        final demoMode = SessionService.instance.mode == AppMode.demo;
        final recent = demoMode
            ? MockDataService.transactions.take(3).toList()
            : const [];
        return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Good day, Disha',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        const Text('Your safer payments space'),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(context, demoMode),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _BalanceCard(
                showDemoBalance: demoMode,
                onTap: () => context.push('/receive'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Quick actions',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _QuickAction(
                    label: 'Send',
                    icon: Icons.north_east_rounded,
                    onTap: () => context.push('/send'),
                  ),
                  _QuickAction(
                    label: 'Receive',
                    icon: Icons.south_west_rounded,
                    onTap: () => context.push('/receive'),
                  ),
                  _QuickAction(
                    label: 'Request',
                    icon: Icons.request_quote_outlined,
                    onTap: () => context.push('/request'),
                  ),
                  _QuickAction(
                    label: 'Scan QR',
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: () => context.push('/scan'),
                  ),
                  _QuickAction(
                    label: 'Check risk',
                    icon: Icons.shield_outlined,
                    onTap: () => context.go('/analyze'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go('/shield'),
                  child: const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.blue),
                        SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('UPI Scam Shield',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                'Check messages, links and recipient IDs.',
                                style: TextStyle(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent activity',
                      style: Theme.of(context).textTheme.titleLarge),
                  TextButton(
                    onPressed: () => context.go('/activity'),
                    child: const Text('See all'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Card(
                child: recent.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          demoMode
                              ? 'No activity yet.'
                              : 'Sample payments are hidden in live mode. '
                                  'Payment history is not available from the backend yet.',
                        ),
                      )
                    : Column(
                        children: [
                          for (final (index, transaction)
                              in recent.indexed) ...[
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    const Color(0x1A4361EE),
                                child: Icon(
                                  transaction.amount < 0
                                      ? Icons.north_east_rounded
                                      : Icons.south_west_rounded,
                                  color: AppColors.blue,
                                  size: 19,
                                ),
                              ),
                              title: Text(transaction.title),
                              subtitle: Text(transaction.subtitle),
                              trailing: Text(
                                '${transaction.amount < 0 ? '−' : '+'}₹'
                                '${transaction.amount.abs().toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (index < recent.length - 1)
                              const Divider(height: 1, indent: 72),
                          ],
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (demoMode)
                const _DemoNotice()
              else
                const _LiveModeNotice(),
            ],
          ),
        ),
      ),
        );
      },
    );
  }

  static void _showNotifications(BuildContext context, bool demoMode) {
    final messages = demoMode
        ? const NotificationService().getDemoNotifications()
        : const ['Live notification integration is not available yet.'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Text('Notifications',
                style: Theme.of(context).textTheme.titleLarge),
            for (final message in messages)
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: Text(message),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.showDemoBalance,
    required this.onTap,
  });

  final bool showDemoBalance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, Color(0xFF243A79)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Color(0xFFDCE4FF)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                showDemoBalance ? 'Demo balance' : 'Balance unavailable',
                style: const TextStyle(color: Color(0xFFDCE4FF)),
              ),
              const Spacer(),
              if (showDemoBalance) ...[
                const Icon(Icons.science_outlined,
                    size: 16, color: Color(0xFFDCE4FF)),
                const SizedBox(width: 4),
                const Text('SIMULATED',
                    style: TextStyle(
                      color: Color(0xFFDCE4FF),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    )),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            showDemoBalance
                ? '₹${MockDataService.demoBalance.toStringAsFixed(2)}'
                : 'No backend balance endpoint',
            style: TextStyle(
              color: Colors.white,
              fontSize: showDemoBalance ? 32 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (showDemoBalance)
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'UPI ID  ${MockDataService.demoUpiId}',
                    style: TextStyle(color: Color(0xFFDCE4FF)),
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('My QR'),
                ),
              ],
            )
          else
            const Text(
              'No account or balance endpoint is configured.',
              style: TextStyle(color: Color(0xFFDCE4FF)),
            ),
        ],
      ),
    );
  }
=======
  void _openScan(BuildContext context, {String? type}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanScreen(initialType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFF103D35),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_moon_outlined,
                    color: Colors.white, size: 34),
                const SizedBox(height: 18),
                Text(
                  'Pause. Check. Pay safely.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check suspicious messages, links, UPI IDs, and QR codes before you act.',
                  style: TextStyle(color: Color(0xFFDCECE5), height: 1.5),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openScan(context),
                  icon: const Icon(Icons.search),
                  label: const Text('Check something'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text('Quick checks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 12),
          _QuickAction(
            icon: Icons.message_outlined,
            title: 'Message or link',
            subtitle: 'Paste a message, URL, or payment request',
            onTap: () => _openScan(context, type: 'text'),
          ),
          _QuickAction(
            icon: Icons.qr_code_scanner,
            title: 'Scan a QR code',
            subtitle: 'Inspect the code before opening or paying',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const QrScannerScreen(),
              ),
            ),
          ),
          _QuickAction(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Check a UPI ID',
            subtitle: 'Look for suspicious recipient details',
            onTap: () => _openScan(context, type: 'recipient'),
          ),
          _QuickAction(
            icon: Icons.image_search_outlined,
            title: 'Check text from a screenshot',
            subtitle: 'Copy the visible text and paste it for analysis',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ScreenshotScreen(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.tips_and_updates_outlined,
                      color: Color(0xFF087F5B)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Never share your UPI PIN or OTP. You do not need to enter a PIN to receive money.',
                      style: TextStyle(height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
<<<<<<< HEAD
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: AppColors.blue),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'NUMPE is a demonstration. Balances, receipts and transactions are '
      'simulated and do not represent real money.',
      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
    );
  }
}

class _LiveModeNotice extends StatelessWidget {
  const _LiveModeNotice();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Live mode uses configured backend responses. No demo balance or sample '
      'transactions are shown. Banking and real UPI are not connected.',
      style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
    );
  }
}
=======
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE7F3ED),
            child: Icon(icon, color: const Color(0xFF087F5B)),
          ),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
