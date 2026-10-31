import 'package:flutter_test/flutter_test.dart';
import 'package:numpe/config/api_config.dart';
import 'package:numpe/models/payment.dart';
import 'package:numpe/models/risk_assessment.dart';
import 'package:numpe/services/api_service.dart';
import 'package:numpe/services/payment_service.dart';
import 'package:numpe/services/qr_service.dart';
import 'package:numpe/services/scam_shield_service.dart';
import 'package:numpe/services/session_service.dart';

void main() {
  group('Scam Shield demo assessments', () {
    final service = ScamShieldService();

    test('flags requests for sensitive credentials as high risk', () async {
      final result = await service.analyze(
        input: 'Urgent: share your OTP and PIN immediately',
        type: 'text',
        mode: AppMode.demo,
      );

      expect(result.score, greaterThanOrEqualTo(70));
      expect(result.level, RiskLevel.high);
      expect(result.explanation, contains('not proof of fraud'));
    });

    test('gives normal text a low demo risk assessment', () async {
      final result = await service.analyze(
        input: 'Lunch at 1 pm?',
        type: 'text',
        mode: AppMode.demo,
      );

      expect(result.score, lessThan(35));
      expect(result.level, RiskLevel.low);
      expect(result.indicators, isNotEmpty);
    });
  });

  group('QR payment payloads', () {
    final service = QrService();

    test('round trips a supported payment QR payload', () {
      final payload = service.createPaymentPayload(
        upiId: 'merchant@bank',
        name: 'Merchant',
        amount: 25,
      );

      final draft = service.parsePaymentPayload(payload);
      expect(draft?.recipient, 'merchant@bank');
      expect(draft?.amount, 25);
    });

    test('rejects malformed or non-payment QR payloads', () {
      expect(service.parsePaymentPayload('not a payment QR'), isNull);
      expect(
        service.parsePaymentPayload('upi://pay?pa=bad&am=-2'),
        isNull,
      );
    });
  });

  group('simulated payment submission', () {
    const lowRisk = RiskAssessment(
      score: 8,
      level: RiskLevel.low,
      explanation: 'Demo screening estimate.',
      indicators: ['No common warning patterns were found.'],
      recommendation: 'Verify the recipient independently.',
    );
    const highRisk = RiskAssessment(
      score: 92,
      level: RiskLevel.high,
      explanation: 'Demo screening estimate.',
      indicators: ['Sensitive credentials were requested.'],
      recommendation: 'Do not proceed without independent verification.',
    );

    setUp(() => SessionService.instance.setEmergencyLock(false));
    tearDown(() => SessionService.instance.setEmergencyLock(false));

    test('returns an explicitly simulated success for a confirmed demo payment',
        () async {
      final receipt = await PaymentService().submit(
        const PaymentDraft(recipient: 'person@bank', amount: 10),
        risk: lowRisk,
        mode: AppMode.demo,
      );

      expect(receipt.status, PaymentStatus.success);
      expect(receipt.id, startsWith('DEMO-'));
      expect(receipt.risk, lowRisk);
    });

    test('blocks high-risk demo payments', () async {
      final receipt = await PaymentService().submit(
        const PaymentDraft(recipient: 'person@bank', amount: 10),
        risk: highRisk,
        mode: AppMode.demo,
      );

      expect(receipt.status, PaymentStatus.blocked);
    });

    test('does not convert a live backend failure into a successful payment',
        () async {
      final service = PaymentService(api: _UnavailableApiService());

      expect(
        () => service.submit(
          const PaymentDraft(recipient: 'person@bank', amount: 10),
          risk: lowRisk,
          mode: AppMode.live,
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('does not submit when the emergency payment lock is on', () async {
      SessionService.instance.setEmergencyLock(true);

      expect(
        () => PaymentService().submit(
          const PaymentDraft(recipient: 'person@bank', amount: 10),
          risk: lowRisk,
          mode: AppMode.demo,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _UnavailableApiService extends ApiService {
  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    throw const ApiException('The backend is unavailable.');
  }
}
