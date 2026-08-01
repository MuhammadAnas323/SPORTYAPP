/// Simple input validation helpers shared by auth and connection forms.
///
/// Each validator returns `null` when valid, or a user-facing error string,
/// matching Flutter's `FormFieldValidator<String>` contract.
abstract final class AppValidators {
  AppValidators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
  static final RegExp _uriPattern = RegExp(r'^https?://');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'That email does not look right';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'At least 8 characters';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    return null;
  }

  static String? connectionLabel(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Give this channel a name';
    if (v.length > 40) return 'Keep it under 40 characters';
    return null;
  }

  static String? baseUrl(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the API host';
    if (!_uriPattern.hasMatch(v)) return 'Must start with http:// or https://';
    return null;
  }

  static String? apiKey(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Paste your API key';
    return null;
  }

  static String? headerName(String? value, {required bool required}) {
    final v = value?.trim() ?? '';
    if (!required) return null;
    if (v.isEmpty) return 'Header name is required';
    if (!RegExp(r'^[\w\-]+$').hasMatch(v)) return 'Letters, numbers, - and _ only';
    return null;
  }
}
