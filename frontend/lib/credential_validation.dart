class CredentialValidator {
  final RegExp _re = RegExp(r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+');

  String? username(String? value) {
    if (value == null) {
      return 'Please enter a username';
    }

    if (!_re.hasMatch(value)) {
      return 'Email format is incorrect';
    }

    return null;
  }

  String? password(String? value) {
    if (value == null) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password is too short';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain an uppercase letter';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain a lowercase letter';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain a digit';
    }

    if (!value.contains(RegExp(r'[!@#%^&*(),.?":{}|<>~]'))) {
      return 'Password must contain a special character';
    }

    return null;
  }

  String? confirmPassword(String? value, String? password) {
    if (value == null || password == null) {
      return 'Please enter a password';
    }

    if (value != password) {
      return 'Password does not match';
    }

    return null;
  }
}
