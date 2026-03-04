import 'package:flutter/material.dart';
import 'package:matchpoint/features/onboarding/data/models/onboarding_model.dart';
import '../../../auth/presentation/pages/signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  void _goNext() {
    if (_index < onboardingPages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == onboardingPages.length - 1;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final gradientTop = isDarkTheme
        ? const Color.fromARGB(255, 32, 39, 46)
        : const Color.fromARGB(255, 145, 240, 211);
    final gradientBottom = isDarkTheme
        ? const Color.fromARGB(255, 18, 23, 30)
        : const Color.fromARGB(255, 108, 238, 158);
    final panelColor = isDarkTheme
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.white.withOpacity(0.55);
    final panelBorder = isDarkTheme
        ? Colors.white24
        : Colors.white.withOpacity(0.6);
    final titleColor = isDarkTheme ? Colors.white : Colors.black;
    final subtitleColor = isDarkTheme ? Colors.white70 : Colors.black.withOpacity(0.65);
    final accentColor = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);

    return Scaffold(
      body: Container(
        // ✅ UI ONLY: new gradient theme (same screen logic)
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
          child: Column(
            children: [
              // ✅ UI ONLY: top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Logo capsule (unique look)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: panelBorder),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            "assets/images/matchpoint_logo_final.png",
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "MatchPoint",
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        "Skip",
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: subtitleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingPages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = onboardingPages[i];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),

                          // ✅ UI ONLY: logo inside a soft card
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: panelBorder,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              "assets/images/matchpoint_logo_final.png",
                              width: 110,
                              height: 110,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const Spacer(),

                          // ✅ UI ONLY: icon in rounded square (not circle)
                          Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: panelBorder,
                              ),
                            ),
                            child: Icon(
                              page.icon,
                              size: 72,
                              color: accentColor,
                            ),
                          ),

                          const SizedBox(height: 26),

                          // ✅ UI ONLY: title in its own card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: panelColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: panelBorder,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  page.subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 15,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ✅ UI ONLY: indicators themed
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingPages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    height: 8,
                    width: _index == i ? 26 : 8,
                    decoration: BoxDecoration(
                      color: _index == i
                          ? accentColor
                          : Colors.white.withOpacity(isDarkTheme ? 0.25 : 0.55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ✅ UI ONLY: button style, same onPressed
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _goNext,
                    child: Text(
                      isLast ? "Get Started" : "Next",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
