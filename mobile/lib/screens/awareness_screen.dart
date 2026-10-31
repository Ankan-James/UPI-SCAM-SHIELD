import 'package:flutter/material.dart';

class AwarenessScreen extends StatelessWidget {
  const AwarenessScreen({super.key});

  static const _tips = [
    (
      Icons.password_outlined,
      'Keep your PIN and OTP private',
      'Your bank, UPI app, and legitimate support staff will never ask you to reveal your UPI PIN or OTP.',
    ),
    (
      Icons.south_west,
      'A PIN sends money',
      'Entering a UPI PIN authorizes a payment. You do not need a PIN to receive money.',
    ),
    (
      Icons.link_outlined,
      'Check links independently',
      'Do not use links in urgent messages. Open your bank or service using its official app or a saved address.',
    ),
    (
      Icons.support_agent_outlined,
      'Beware of remote access requests',
      'Do not install screen-sharing or remote-control apps at the request of an unknown caller.',
    ),
    (
      Icons.verified_outlined,
      'Verify the recipient',
      'Before paying, check the recipient name and UPI ID inside your UPI app. A QR code can request a payment.',
    ),
    (
      Icons.report_outlined,
      'Act quickly if money is lost',
      'Contact your bank through its official number and report suspected financial cybercrime using your local official channels.',
    ),
  ];

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Stay one step ahead',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Small checks can help stop common payment scams.'),
          const SizedBox(height: 18),
          ..._tips.map(
            (tip) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Icon(tip.$1, color: const Color(0xFF087F5B)),
                title: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(tip.$2,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                subtitle: Text(tip.$3, style: const TextStyle(height: 1.4)),
              ),
            ),
          ),
        ],
      );
}
