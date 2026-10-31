import '../models/payment.dart';
import '../models/transaction.dart';

class MockDataService {
  static const demoBalance = 12450.75;
  static const demoUpiId = 'disha@numpe';
  static final demoReports = <({String type, String description, DateTime date})>[];

  static final transactions = <NumpeTransaction>[
    NumpeTransaction(
      id: 'NP-2401',
      title: 'Coffee House',
      subtitle: 'Paid · simulated',
      amount: -245,
      status: PaymentStatus.success,
      date: DateTime(2026, 10, 28, 10, 14),
    ),
    NumpeTransaction(
      id: 'NP-2398',
      title: 'From Ananya',
      subtitle: 'Received · simulated',
      amount: 1200,
      status: PaymentStatus.success,
      date: DateTime(2026, 10, 27, 18, 30),
    ),
    NumpeTransaction(
      id: 'NP-2391',
      title: 'Metro Recharge',
      subtitle: 'Paid · simulated',
      amount: -500,
      status: PaymentStatus.success,
      date: DateTime(2026, 10, 25, 9, 5),
    ),
  ];

  static void recordPayment({
    required String id,
    required String recipient,
    required double amount,
    required PaymentStatus status,
    required DateTime date,
  }) {
    transactions.insert(
      0,
      NumpeTransaction(
        id: id,
        title: recipient,
        subtitle: 'Payment · simulated',
        amount: -amount,
        status: status,
        date: date,
      ),
    );
  }
}
