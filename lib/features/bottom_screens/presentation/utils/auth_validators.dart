class AuthValidators {
  static String? login({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || password.isEmpty) {
      return "Please enter credentials";
    }
    return null;
  }

  static String? signup({
    required String name,
    required String email,
    required String pass,
    required String confirm,
  }) {
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        pass.isEmpty ||
        confirm.isEmpty) {
      return "Please fill all fields";
    }

    if (!email.trim().toLowerCase().endsWith('@gmail.com')) {
      return "Only Gmail addresses are allowed";
    }

    if (pass.length < 7) {
      return "Password must be at least 7 characters";
    }

    if (pass != confirm) {
      return "Passwords do not match";
    }

    return null;
  }
}
