abstract final class Validators {
  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Enter your email.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if ((value ?? '').length < 6) return 'Use at least 6 characters.';
    return null;
  }

  static String? upiId(String? value) {
    final recipient = value?.trim() ?? '';
    if (recipient.isEmpty) return 'Enter the recipient UPI ID.';
    if (!RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z0-9.-]{2,}$')
        .hasMatch(recipient)) {
      return 'Enter a valid UPI ID, for example name@bank.';
    }
    return null;
  }

  static String? amount(String? value) {
    final amount = double.tryParse((value ?? '').trim());
    if (amount == null || !amount.isFinite || amount <= 0) {
      return 'Enter an amount greater than zero.';
    }
    return null;
  }
}