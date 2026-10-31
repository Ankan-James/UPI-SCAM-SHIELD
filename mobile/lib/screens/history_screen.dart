import 'package:flutter/material.dart';

import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../widgets/risk_badge.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _api = ApiService();
  late Future<List<Map<String, dynamic>>> _history;

  @override
  void initState() {
    super.initState();
    _history = _api.history();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _history = _api.history());
    await _history;
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _history,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.cloud_off_outlined, size: 44),
                  const SizedBox(height: 12),
                  Text('Could not load history.\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  TextButton(
                    onPressed: () => setState(() => _history = _api.history()),
                    child: const Text('Try again'),
                  ),
                ],
              );
            }
            final items = snapshot.data ?? const [];
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Recent checks',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'The current server history endpoint is shared and is not tied to your account. It shows only scan type, risk level, score, and date.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Text('No checks yet.', textAlign: TextAlign.center),
                  )
                else
                  ...items.map((item) {
                    final result = ScanResult.fromHistory(item);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.fact_check_outlined),
                        title: Text(
                          '${result.type.toUpperCase()} check',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${item['created_at'] ?? 'Date unavailable'} · ${result.score}/100',
                        ),
                        trailing: RiskBadge(level: result.level),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ResultScreen(result: result),
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      );
}
