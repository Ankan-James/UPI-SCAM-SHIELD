import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:upi_scam_shield/models/scan_result.dart';
import 'package:upi_scam_shield/services/api_service.dart';
import 'package:upi_scam_shield/utils/validators.dart';

void main() {
  group('ScanResult', () {
    test('parses backend analysis response and indicators', () {
      final result = ScanResult.fromJson({
        'score': 82,
        'level': 'high',
        'indicators': [
          'Urgent payment request',
          {'evidence': 'Suspicious link'},
        ],
        'recommendation': 'Do not pay.',
        'type': 'text',
      });

      expect(result.score, 82);
      expect(result.level, 'HIGH');
      expect(result.indicators, [
        'Urgent payment request',
        'Suspicious link',
      ]);
      expect(result.recommendation, 'Do not pay.');
    });

    test('parses historical rows', () {
      final result = ScanResult.fromHistory({
        'risk_score': 25,
        'risk_level': 'low',
        'input_type': 'url',
      });

      expect(result.score, 25);
      expect(result.level, 'LOW');
      expect(result.type, 'url');
    });
  });

  group('form validators', () {
    test('rejects invalid email and short passwords', () {
      expect(validEmail('not-an-email'), isNotNull);
      expect(validPassword('12345'), isNotNull);
    });

    test('accepts a valid email and six-character password', () {
      expect(validEmail('user@example.com'), isNull);
      expect(validPassword('123456'), isNull);
    });
  });

  group('ApiService', () {
    test('posts analysis and parses the backend response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/analyze');
        expect(jsonDecode(request.body), {
          'type': 'text',
          'input': 'Suspicious payment message',
        });
        return http.Response(
          jsonEncode({
            'score': 70,
            'level': 'high',
            'indicators': ['Urgent payment request'],
            'recommendation': 'Verify with your bank.',
            'type': 'text',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final api = ApiService(
        client: client,
        baseUrl: 'http://example.test/api/',
      );

      final result = await api.analyze('text', 'Suspicious payment message');

      expect(result.score, 70);
      expect(result.level, 'HIGH');
      api.close();
    });

    test('surfaces backend errors instead of returning a fake result',
        () async {
      final api = ApiService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'input is required'}),
            400,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        api.analyze('text', ' '),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 400)
              .having((error) => error.message, 'message', 'input is required'),
        ),
      );
      api.close();
    });
  });
}
