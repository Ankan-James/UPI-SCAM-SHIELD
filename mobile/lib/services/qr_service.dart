import '../models/payment.dart';

class QrService {
  String createPaymentPayload({
    required String upiId,
    required String name,
    double? amount,
    String? note,
  }) {
    final values = <String, String>{
      'pa': upiId,
      'pn': name,
      'cu': 'INR',
      if (amount != null && amount > 0) 'am': amount.toStringAsFixed(2),
      if (note != null && note.trim().isNotEmpty) 'tn': note.trim(),
    };
    return Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: values,
    ).toString();
  }

  PaymentDraft? parsePaymentPayload(String payload) {
    final uri = Uri.tryParse(payload.trim());
    if (uri == null || uri.scheme != 'upi' || uri.host != 'pay') return null;
    final recipient = uri.queryParameters['pa'];
    final amountValue = uri.queryParameters['am'];
    final amount = amountValue == null ? 0.0 : double.tryParse(amountValue);
    if (recipient == null ||
        !RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z0-9.-]{2,}$')
            .hasMatch(recipient) ||
        amount == null ||
        !amount.isFinite ||
        amount < 0) {
      return null;
    }
    return PaymentDraft(
      recipient: recipient,
      amount: amount,
      note: uri.queryParameters['tn'] ?? '',
    );
  }
}
