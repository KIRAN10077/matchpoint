import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import '../view_model/auth_view_model.dart';
import '../state/auth_state.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    // ✅ Side-effects registered once (LOGIC UNCHANGED)
    ref.listenManual<AuthState>(
      authViewModelProvider,
      (prev, next) {
        if (!mounted) return;

        if (next.status == AuthStatus.error && next.errorMessage != null) {
          _showSnack(next.errorMessage!);
        }

        if (next.status == AuthStatus.registered) {
          _showSnack("Registration successful. Please login.");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ✅ UI-only: themed decoration (green)
  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 20, 110, 80)),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      filled: true,
      fillColor: Colors.white.withOpacity(0.92),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 20, 110, 80),
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

    return Scaffold(
      backgroundColor: const Color.fromARGB(137, 255, 255, 255),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 145, 240, 211),
              Color.fromARGB(255, 108, 238, 158),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Unique header (different from login screen)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // mini logo tile
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: Colors.white.withOpacity(0.6)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              'assets/images/matchpoint_logo_final.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "MatchPoint",
                                style: GoogleFonts.audiowide(
                                  fontSize: 24,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "Create your account to get started",
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.65),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ✅ Form container (new shape + section divider)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Title row
                        Row(
                          children: [
                            Icon(Icons.person_add_alt_1,
                                color: Colors.black.withOpacity(0.75)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Sign Up",
                                style: GoogleFonts.audiowide(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.08),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _nameCtrl,
                          decoration:
                              _decoration("Full Name", Icons.person_outline),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              _decoration("Email Address", Icons.email_outlined),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: _decoration("Password", Icons.lock_outline),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _confirmCtrl,
                          obscureText: true,
                          decoration: _decoration(
                              "Confirm Password", Icons.lock_reset_outlined),
                        ),

                        const SizedBox(height: 18),

                        // ✅ Button (different label style)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 20, 110, 80),
                              foregroundColor: Colors.white,
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            onPressed: isLoading ? null : _onSignupPressed,
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
                                    "CREATE ACCOUNT",
                                    style: GoogleFonts.audiowide(
                                      fontSize: 14,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ Bottom link (clean + unique)
                  InkWell(
                    onTap: isLoading
                        ? null
                        : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()),
                            );
                          },
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.70),
                              fontSize: 14,
                            ),
                            children: const [
                              TextSpan(
                                text: "Log In",
                                style: TextStyle(
                                  color: Color.fromARGB(255, 20, 110, 80),
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

                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSignupPressed() async {
    FocusScope.of(context).unfocus();

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }

    if (!email.toLowerCase().endsWith('@gmail.com')) {
      _showSnack("Only Gmail addresses are allowed");
      return;
    }

    if (pass.length < 7) {
      _showSnack("Password must be at least 7 characters");
      return;
    }

    if (pass != confirm) {
      _showSnack("Passwords do not match");
      return;
    }

    await ref.read(authViewModelProvider.notifier).register(
          username: name,
          email: email,
          password: pass,
        );
  }
}
