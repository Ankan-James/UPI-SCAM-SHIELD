import 'package:flutter/material.dart';

import 'qr_scanner_screen.dart';
import 'scan_screen.dart';
import 'screenshot_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
