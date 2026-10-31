import '../config/api_config.dart';
import '../models/payment.dart';
import '../models/risk_assessment.dart';
import 'api_service.dart';
import 'mock_data_service.dart';
import 'session_service.dart';

class PaymentService {
  PaymentService({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  static int _demoReferenceFor(String recipient) {
    var value = 0;
    for (final codeUnit in recipient.codeUnits) {
      value = (value * 31 + codeUnit) & 0x7fffffff;
    }
    return value;
  }

  Future<PaymentReceipt> submit(
    PaymentDraft draft, {
    required RiskAssessment risk,
    required AppMode mode,
  }) async {
    if (!RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z0-9.-]{2,}$')
        .hasMatch(draft.recipient.trim())) {
      throw const ApiException('Enter a valid recipient UPI ID.');
    }
    if (draft.amount <= 0 || !draft.amount.isFinite) {
      throw const ApiException('Enter a valid amount greater than zero.');
    }
    if (SessionService.instance.emergencyLockEnabled) {
    throw const ApiException(
      'Emergency Payment Lock is enabled for this app session.',
    );
    }
    if (risk.level == RiskLevel.high) {
      final receipt = PaymentReceipt(
        id: 'BLOCKED-${_demoReferenceFor(draft.recipient)}',
        status: PaymentStatus.blocked,
        recipient: draft.recipient,
        amount: draft.amount,
        createdAt: DateTime.now(),
        risk: risk,
      );
      MockDataService.recordPayment(
        id: receipt.id,
        recipient: receipt.recipient,
        amount: receipt.amount,
        status: receipt.status,
        date: receipt.createdAt,
      );
      return receipt;
    }

    if (mode == AppMode.demo) {
      final receipt = PaymentReceipt(
        id: 'DEMO-${_demoReferenceFor(draft.recipient).toString().padLeft(6, '0')}',
        status: PaymentStatus.success,
        recipient: draft.recipient,
        amount: draft.amount,
        createdAt: DateTime.now(),
        risk: risk,
      );
      MockDataService.recordPayment(
        id: receipt.id,
        recipient: receipt.recipient,
        amount: receipt.amount,
        status: receipt.status,
        date: receipt.createdAt,
      );
      return receipt;
    }

    final response = await _api.post('payments/send', body: {
      'recipient': draft.recipient.trim(),
      'amount': draft.amount,
      'note': draft.note.trim().isEmpty ? null : draft.note.trim(),
    });
    final status = switch (response['status']) {
      'success' => PaymentStatus.success,
      'pending' => PaymentStatus.pending,
      'failed' => PaymentStatus.failed,
      'blocked' => PaymentStatus.blocked,
      _ => throw const ApiException(
          'The server returned an unknown payment status.',
        ),
    };

    final receipt = PaymentReceipt(
      id: response['id']?.toString() ??
          (throw const ApiException('The server omitted the payment reference.')),
      status: status,
      recipient: draft.recipient,
      amount: draft.amount,
      createdAt: DateTime.now(),
      risk: risk,
    );
    MockDataService.recordPayment(
      id: receipt.id,
      recipient: receipt.recipient,
      amount: receipt.amount,
      status: receipt.status,
      date: receipt.createdAt,
    );
    return receipt;
  }
}
