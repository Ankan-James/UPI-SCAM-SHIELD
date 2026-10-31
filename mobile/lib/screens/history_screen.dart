import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:go_router/go_router.dart';

import '../config/api_config.dart';
import '../models/payment.dart';
import '../models/risk_assessment.dart';
import '../models/transaction.dart';
import '../services/mock_data_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
=======

import '../models/scan_result.dart';
import '../services/api_service.dart';
import '../widgets/risk_badge.dart';
import 'result_screen.dart';
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
<<<<<<< HEAD
  final _search = TextEditingController();
  PaymentStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SessionService.instance.mode == AppMode.live) {
      return const _LiveHistoryNotice();
    }
    final transactions = MockDataService.transactions.where((transaction) {
      final matchesText =
          '${transaction.title} ${transaction.id} ${transaction.subtitle}'
              .toLowerCase()
              .contains(_search.text.toLowerCase());
      final matchesFilter = _filter == null || transaction.status == _filter;
      return matchesText && matchesFilter;
    }).toList()
      ..sort((first, second) => second.date.compareTo(first.date));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search name or reference',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == null,
                onTap: () => setState(() => _filter = null),
              ),
              for (final (label, status) in const [
                ('Success', PaymentStatus.success),
                ('Pending', PaymentStatus.pending),
                ('Blocked', PaymentStatus.blocked),
                ('Failed', PaymentStatus.failed),
              ])
                _FilterChip(
                  label: label,
                  selected: _filter == status,
                  onTap: () => setState(() => _filter = status),
                ),
            ],
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'No matching activity.\nTry another search or filter.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: transactions.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      child: ListTile(
                        onTap: () => context.push(
                          '/payment-result',
                          extra: _receiptFromTransaction(transaction),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(transaction.status)
                              .withValues(alpha: 0.1),
                          child: Icon(
                            transaction.amount < 0
                                ? Icons.north_east
                                : Icons.south_west,
                            color: _statusColor(transaction.status),
                          ),
                        ),
                        title: Text(transaction.title),
                        subtitle: Text(
                          '${transaction.subtitle} · '
                          '${MaterialLocalizations.of(context).formatMediumDate(transaction.date)}',
                        ),
                        trailing: SizedBox(
                          width: 100,
                          child: Text(
                            '${transaction.amount < 0 ? '−' : '+'}₹'
                            '${transaction.amount.abs().toStringAsFixed(2)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w700,
                            ),
=======
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
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
                          ),
                        ),
                      ),
                    );
<<<<<<< HEAD
                  },
                ),
        ),
      ],
    );
  }

  static Color _statusColor(PaymentStatus status) => switch (status) {
        PaymentStatus.success => AppColors.emerald,
        PaymentStatus.pending => AppColors.amber,
        PaymentStatus.failed || PaymentStatus.blocked => AppColors.red,
      };

  static PaymentReceipt _receiptFromTransaction(
    NumpeTransaction transaction,
  ) {
    final level = transaction.status == PaymentStatus.blocked
        ? RiskLevel.high
        : RiskLevel.low;
    return PaymentReceipt(
      id: transaction.id,
      status: transaction.status,
      recipient: transaction.title,
      amount: transaction.amount.abs(),
      createdAt: transaction.date,
      risk: RiskAssessment(
        score: level == RiskLevel.high ? 85 : 8,
        level: level,
        explanation: 'Historical demo transaction details.',
        indicators: const ['Historical details are simulated.'],
        recommendation: 'Verify payment details independently.',
      ),
    );
  }
}

class _LiveHistoryNotice extends StatelessWidget {
  const _LiveHistoryNotice();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Payment history is unavailable in live mode. The backend history '
          'route currently returns Scam Shield analysis records, not payment '
          'transactions, so sample payments are hidden.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
=======
                  }),
              ],
            );
          },
        ),
      );
}
>>>>>>> d3313048cdd92374dc04c11de22b2a9f06ec34e3
