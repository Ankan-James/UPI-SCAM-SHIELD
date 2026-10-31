import 'payment.dart';

class NumpeTransaction {
  const NumpeTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
    required this.date,
  });

  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final PaymentStatus status;
  final DateTime date;
}
