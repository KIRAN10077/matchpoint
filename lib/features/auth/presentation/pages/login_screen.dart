import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:local_auth/local_auth.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';

import 'signup_screen.dart';
import '../../../dashboard/presentation/pages/home_screen.dart';
import '../view_model/auth_view_model.dart';
import '../state/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();

    // ✅ Listener added once (safe)
    ref.listenManual<AuthState>(authViewModelProvider, (prev, next) {
      if (!mounted) return;

      if (next.status == AuthStatus.error && next.errorMessage != null) {
        _showSnack(next.errorMessage!);
      }

      if (next.status == AuthStatus.authenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });

    Future.microtask(_loadBiometricPreference);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricPreference() async {
    final session = ref.read(userSessionServiceProvider);
    if (!mounted) return;
    setState(() {
      _biometricsEnabled = session.isBiometricsEnabled();
    });
  }

  Future<void> _loginWithBiometrics() async {
    final session = ref.read(userSessionServiceProvider);

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();

      if (!canCheck || !supported) {
        _showSnack('Biometric authentication is not available on this device.');
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to login to MatchPoint',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) return;

      final token = await session.getToken();
      if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
        _showSnack('Saved biometric session expired. Please login with email/password.');
        return;
      }

      await session.setLoggedIn(true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on PlatformException catch (_) {
      _showSnack('Unable to use biometrics right now.');
    }
  }

  InputDecoration _decoration(String hint, IconData icon) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final accent = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);
    final inputBg = isDarkTheme
        ? const Color.fromARGB(255, 39, 49, 58)
        : Colors.white.withOpacity(0.92);
    final hintColor = isDarkTheme ? Colors.white70 : Colors.black54;

    return InputDecoration(
      prefixIcon: Icon(icon, color: accent),
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 14),
      filled: true,
      fillColor: inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDarkTheme ? Colors.white24 : Colors.white.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: accent,
          width: 2,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: const Color.fromARGB(255, 20, 110, 80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final gradientTop = isDarkTheme
        ? const Color.fromARGB(255, 32, 39, 46)
        : const Color.fromARGB(255, 145, 240, 211);
    final gradientBottom = isDarkTheme
        ? const Color.fromARGB(255, 18, 23, 30)
        : const Color.fromARGB(255, 108, 238, 158);
    final cardColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withOpacity(0.65);
    final cardBorder = isDarkTheme ? Colors.white24 : Colors.white.withOpacity(0.6);
    final titleColor = isDarkTheme ? Colors.white : Colors.black;
    final subtitleColor = isDarkTheme ? Colors.white70 : Colors.black.withOpacity(0.65);
    final accent = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);

    return Scaffold(
      backgroundColor: isDarkTheme
          ? const Color.fromARGB(255, 16, 22, 28)
          : const Color.fromARGB(137, 255, 255, 255),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientTop,
              gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Logo Block (new layout)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Image.asset(
                          'assets/images/matchpoint_logo_final.png',
                          height: 140,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "MatchPoint",
                          style: GoogleFonts.audiowide(
                            fontSize: 30,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Sign in to continue",
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Main Card (different design: glass card + side accent)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: cardBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkTheme ? 0.20 : 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Small header row (teacher won't see copied layout)
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Login",
                                style: GoogleFonts.audiowide(
                                  fontSize: 22,
                                  color: titleColor,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoration(
                            "Email Address",
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: _decoration(
                            "Password",
                            Icons.lock_outline,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Button (new look)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: isLoading
                                ? null
                                : () async {
                                    final email = _emailCtrl.text.trim();
                                    final password = _passCtrl.text;
                                    if (email.isEmpty || password.isEmpty) {
                                      _showSnack("Please enter credentials");
                                      return;
                                    }
                                    await ref
                                        .read(authViewModelProvider.notifier)
                                        .login(email: email, password: password);
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    "LOGIN",
                                    style: GoogleFonts.audiowide(
                                      fontSize: 16,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),

                        if (_biometricsEnabled) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isLoading ? null : _loginWithBiometrics,
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Tap to login with fingerprint'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: accent,
                                side: BorderSide(color: accent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Bottom link (new styling)
                  InkWell(
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SignupScreen()),
                            );
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            text: "New here? ",
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Create an account",
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
