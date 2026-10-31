String? requiredInput(String? value, {String label = 'This field'}) {
  if (value == null || value.trim().isEmpty) return '$label is required.';
  return null;
}

String? validEmail(String? value) {
  final requiredError = requiredInput(value, label: 'Email');
  if (requiredError != null) return requiredError;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim())) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? validPassword(String? value) {
  if (value == null || value.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}

String? validUsername(String? value) {
  if (value == null || value.trim().length < 3) {
    return 'Name must be at least 3 characters.';
  }
  return null;
}
