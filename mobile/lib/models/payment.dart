import 'risk_assessment.dart';

enum PaymentStatus { success, pending, failed, blocked }

class PaymentDraft {
  const PaymentDraft({
    required this.recipient,
    required this.amount,
    this.note = '',
  });

  final String recipient;
  final double amount;
  final String note;
}

class PaymentReceipt {
  const PaymentReceipt({
    required this.id,
    required this.status,
    required this.recipient,
    required this.amount,
    required this.createdAt,
    required this.risk,
  });

  final String id;
  final PaymentStatus status;
  final String recipient;
  final double amount;
  final DateTime createdAt;
  final RiskAssessment risk;
}

class PaymentReviewArgs {
  const PaymentReviewArgs({required this.draft, required this.risk});

  final PaymentDraft draft;
  final RiskAssessment risk;
}
