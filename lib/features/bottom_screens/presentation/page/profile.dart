import 'package:matchpoint/features/auth/presentation/pages/signup_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:matchpoint/core/providers/profile_provider.dart';
import 'package:matchpoint/core/providers/theme_mode_provider.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _biometricsEnabled = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileProvider.notifier).loadProfile();
      final session = ref.read(userSessionServiceProvider);
      if (!mounted) return;
      setState(() {
        _biometricsEnabled = session.isBiometricsEnabled();
      });
    });
  }

  Future<void> _onBiometricsToggle(
    UserSessionService session,
    bool value,
  ) async {
    if (!value) {
      setState(() {
        _biometricsEnabled = false;
      });
      await session.setBiometricsEnabled(false);
      _showSnack('Biometrics disabled');
      return;
    }

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!canCheck || !supported) {
        if (!mounted) return;
        setState(() {
          _biometricsEnabled = false;
        });
        _showSnack('Biometric authentication is not available on this device.');
        return;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        if (!mounted) return;
        setState(() {
          _biometricsEnabled = false;
        });
        _showSnack('No biometrics are enrolled on this device.');
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable biometric login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!mounted) return;

      if (!authenticated) {
        setState(() {
          _biometricsEnabled = false;
        });
        _showSnack('Biometric verification cancelled.');
        return;
      }

      setState(() {
        _biometricsEnabled = true;
      });
      await session.setBiometricsEnabled(true);
      _showSnack('Biometrics enabled successfully.');
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _biometricsEnabled = false;
      });
      _showSnack('Unable to enable biometrics right now.');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(userSessionServiceProvider);
    final state = ref.watch(profileProvider);
    final controller = ref.read(profileProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    final appBarColor = isDarkTheme
      ? const Color.fromARGB(255, 24, 30, 36)
      : const Color.fromARGB(255, 20, 110, 80);
    final gradientTop = isDarkTheme
      ? const Color.fromARGB(255, 32, 39, 46)
      : const Color.fromARGB(255, 145, 240, 211);
    final gradientBottom = isDarkTheme
      ? const Color.fromARGB(255, 18, 23, 30)
      : const Color.fromARGB(255, 108, 238, 158);
    final cardColor = isDarkTheme
      ? const Color.fromARGB(255, 33, 42, 50)
      : const Color.fromARGB(255, 230, 247, 239);
    final cardColorSoft = isDarkTheme
      ? const Color.fromARGB(255, 39, 49, 58)
      : const Color.fromARGB(255, 236, 250, 243);
    final titleColor = isDarkTheme
      ? Colors.white
      : const Color.fromARGB(255, 20, 44, 35);
    final subtitleColor = isDarkTheme
      ? Colors.white70
      : const Color.fromARGB(255, 54, 86, 74);
    final iconColor = isDarkTheme
      ? const Color.fromARGB(255, 126, 215, 181)
      : const Color.fromARGB(255, 20, 110, 80);
    final trailingColor = isDarkTheme
      ? Colors.white70
      : const Color.fromARGB(255, 44, 84, 68);

    final name = session.getCurrentUserFullName() ?? "User";
    final email = session.getCurrentUserEmail() ?? "";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        title: const Text("Profile"),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            // ✅ ONLY background theme changed
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
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
              const SizedBox(height: 20),

              // ❌ UNCHANGED: avatar + name + email
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor:
                      isDarkTheme ? Colors.white12 : Colors.grey.shade300,
                    backgroundImage:
                        (state.imageUrl != null && state.imageUrl!.isNotEmpty)
                            ? NetworkImage(state.imageUrl!)
                            : null,
                    child: (state.imageUrl == null ||
                            state.imageUrl!.isEmpty)
                      ? Icon(Icons.person,
                        size: 55,
                        color: isDarkTheme ? Colors.white70 : Colors.white)
                        : null,
                  ),
                  FloatingActionButton.small(
                    backgroundColor: iconColor,
                    onPressed: state.loading
                        ? null
                        : () => _showPicker(context, controller),
                    child: const Icon(Icons.camera_alt),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(email,
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white70 : Colors.grey.shade700,
                  )),

              const SizedBox(height: 16),

              Card(
                elevation: 3,
                shadowColor: isDarkTheme
                    ? Colors.black26
                    : const Color.fromARGB(70, 16, 94, 67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: cardColorSoft,
                child: ListTile(
                  leading: Icon(
                    Icons.edit,
                    color: iconColor,
                  ),
                  title: Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    "Update your name and email",
                    style: TextStyle(
                      color: subtitleColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: trailingColor,
                  ),
                  onTap: state.loading
                      ? null
                      : () => _showEditProfileDialog(
                            context,
                            controller,
                            initialName: name,
                            initialEmail: email,
                          ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 3,
                shadowColor: isDarkTheme
                    ? Colors.black26
                    : const Color.fromARGB(70, 16, 94, 67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(
                    Icons.lock,
                    color: iconColor,
                  ),
                  title: Text(
                    "Change Password",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    "Update your account password",
                    style: TextStyle(
                      color: subtitleColor,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: trailingColor,
                  ),
                  onTap: state.loading
                      ? null
                      : () => _showChangePasswordDialog(context, controller),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 3,
                shadowColor: isDarkTheme
                    ? Colors.black26
                    : const Color.fromARGB(70, 16, 94, 67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(
                    _biometricsEnabled ? Icons.fingerprint : Icons.fingerprint_outlined,
                    color: iconColor,
                  ),
                  title: Text(
                    "Enable Biometrics",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    _biometricsEnabled ? "Biometrics enabled" : "Biometrics disabled",
                    style: TextStyle(
                      color: subtitleColor,
                    ),
                  ),
                  trailing: Switch(
                    value: _biometricsEnabled,
                    onChanged: (value) async {
                      await _onBiometricsToggle(session, value);
                    },
                    activeThumbColor: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Card(
                elevation: 3,
                shadowColor: isDarkTheme
                    ? Colors.black26
                    : const Color.fromARGB(70, 16, 94, 67),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: cardColor,
                child: ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: iconColor,
                  ),
                  title: Text(
                    "Theme Mode",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  subtitle: Text(
                    isDarkMode ? "Dark mode" : "Light mode",
                    style: TextStyle(
                      color: subtitleColor,
                    ),
                  ),
                  trailing: Switch(
                    value: isDarkMode,
                    onChanged: (_) {
                      ref.read(themeModeProvider.notifier).toggle();
                    },
                    activeThumbColor: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              if (state.loading) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 10),
                Text(
                  "Saving...",
                  style: TextStyle(color: titleColor),
                ),
              ],

              if (state.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const Spacer(),

              // ✅ ONLY logout button redesigned
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final shouldLogout = await _showLogoutConfirmation(context);
                    if (!shouldLogout) return;

                    await session.clearSession(
                      preserveBiometricLogin: session.isBiometricsEnabled(),
                    );
                    ref.read(profileProvider.notifier).clear();
                    if (!mounted) return;
                    navigator.pushReplacement(
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen()),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout),
                      SizedBox(width: 10),
                      Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _showLogoutConfirmation(BuildContext context) async {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDarkTheme
      ? const Color.fromARGB(255, 24, 30, 36)
      : const Color.fromARGB(255, 236, 250, 243);
    final dialogBorder = isDarkTheme
      ? Colors.white24
      : const Color.fromARGB(255, 178, 223, 205);
    final titleColor = isDarkTheme
      ? Colors.white
      : const Color.fromARGB(255, 20, 44, 35);
    final bodyColor = isDarkTheme ? Colors.white70 : Colors.black87;
    final accent = isDarkTheme
      ? const Color.fromARGB(255, 126, 215, 181)
      : const Color.fromARGB(255, 20, 110, 80);

    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Confirm Logout',
      barrierColor: Colors.black.withValues(alpha: 0.15),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
            Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                  decoration: BoxDecoration(
                    color: dialogBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: dialogBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirm Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(color: bodyColor),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            style: TextButton.styleFrom(
                              foregroundColor: accent,
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );

    return result ?? false;
  }

  // ❌ LOGIC NOT TOUCHED
  void _showPicker(BuildContext context, ProfileController controller) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text("Take photo"),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.pickAndUpload(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from gallery"),
              onTap: () {
                Navigator.pop(sheetContext);
                controller.pickAndUpload(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    BuildContext context,
    ProfileController controller, {
    required String initialName,
    required String initialEmail,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDarkTheme
        ? const Color.fromARGB(255, 24, 30, 36)
        : const Color.fromARGB(255, 236, 250, 243);
    final sheetBorder = isDarkTheme
        ? Colors.white24
        : const Color.fromARGB(255, 178, 223, 205);
    final titleColor = isDarkTheme
        ? Colors.white
        : const Color.fromARGB(255, 20, 44, 35);
    final fieldTextColor = isDarkTheme ? Colors.white : Colors.black87;
    final fieldLabelColor = isDarkTheme ? Colors.white70 : Colors.black54;
    final fieldBorderColor = isDarkTheme ? Colors.white24 : Colors.black26;
    final fieldFocusColor = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);

    InputDecoration fieldDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: fieldLabelColor),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: fieldFocusColor, width: 1.5),
        ),
      );
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialName);
    final emailController = TextEditingController(text: initialEmail);

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Edit Profile',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (sheetContext, _, __) {
        final sheetHeight = MediaQuery.of(context).size.height * 0.4;
        final keyboardInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: sheetHeight,
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color: sheetBackground,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: sheetBorder,
                        ),
                      ),
                      child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nameController,
                              style: TextStyle(color: fieldTextColor),
                              cursorColor: fieldFocusColor,
                              decoration: fieldDecoration('Name'),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.isEmpty) return 'Name is required';
                                if (name.length < 2) return 'Enter a valid name';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: emailController,
                              style: TextStyle(color: fieldTextColor),
                              cursorColor: fieldFocusColor,
                              decoration: fieldDecoration('Email'),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                final emailRegex = RegExp(
                                  r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
                                );
                                if (email.isEmpty) return 'Email is required';
                                if (!emailRegex.hasMatch(email)) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  style: TextButton.styleFrom(
                                    foregroundColor: fieldFocusColor,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (!(formKey.currentState?.validate() ?? false)) {
                                      return;
                                    }

                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(sheetContext);

                                    final success = await controller.updateProfileInfo(
                                      name: nameController.text.trim(),
                                      email: emailController.text.trim(),
                                    );

                                    if (!mounted) return;
                                    setState(() {});

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Profile updated successfully'
                                              : 'Failed to update profile',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: fieldFocusColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final sheetBackground = isDarkTheme
        ? const Color.fromARGB(255, 24, 30, 36)
        : const Color.fromARGB(255, 230, 247, 239);
    final sheetBorder = isDarkTheme
        ? Colors.white24
        : const Color.fromARGB(255, 178, 223, 205);
    final titleColor = isDarkTheme
        ? Colors.white
        : const Color.fromARGB(255, 20, 44, 35);
    final fieldTextColor = isDarkTheme ? Colors.white : Colors.black87;
    final fieldLabelColor = isDarkTheme ? Colors.white70 : Colors.black54;
    final fieldBorderColor = isDarkTheme ? Colors.white24 : Colors.black26;
    final fieldFocusColor = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);

    InputDecoration fieldDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: fieldLabelColor),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: fieldBorderColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: fieldFocusColor, width: 1.5),
        ),
      );
    }

    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Change Password',
      barrierColor: Colors.black.withValues(alpha: 0.2),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (sheetContext, _, __) {
        final sheetHeight = MediaQuery.of(context).size.height * 0.4;
        final keyboardInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: const SizedBox.expand(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: keyboardInset),
                child: SafeArea(
                  top: false,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      height: sheetHeight,
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color: sheetBackground,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        border: Border.all(
                          color: sheetBorder,
                        ),
                      ),
                      child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: currentPasswordController,
                              style: TextStyle(color: fieldTextColor),
                              cursorColor: fieldFocusColor,
                              decoration: fieldDecoration('Current Password'),
                              obscureText: true,
                              validator: (value) {
                                final password = (value ?? '').trim();
                                if (password.isEmpty) {
                                  return 'Current password is required';
                                }
                                if (password.length < 6) {
                                  return 'Current password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: newPasswordController,
                              style: TextStyle(color: fieldTextColor),
                              cursorColor: fieldFocusColor,
                              decoration: fieldDecoration('New Password'),
                              obscureText: true,
                              validator: (value) {
                                final password = (value ?? '').trim();
                                if (password.isEmpty) {
                                  return 'New password is required';
                                }
                                if (password.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                if (password == currentPasswordController.text.trim()) {
                                  return 'New password must be different from current password';
                                }
                                final hasLetter = RegExp(r'[A-Za-z]').hasMatch(password);
                                final hasNumber = RegExp(r'\d').hasMatch(password);
                                if (!hasLetter || !hasNumber) {
                                  return 'Password must contain letters and numbers';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: confirmPasswordController,
                              style: TextStyle(color: fieldTextColor),
                              cursorColor: fieldFocusColor,
                              decoration: fieldDecoration('Confirm Password'),
                              obscureText: true,
                              validator: (value) {
                                final confirm = (value ?? '').trim();
                                if (confirm.isEmpty) {
                                  return 'Confirm password is required';
                                }
                                if (confirm != newPasswordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  style: TextButton.styleFrom(
                                    foregroundColor: fieldFocusColor,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    if (!(formKey.currentState?.validate() ?? false)) {
                                      return;
                                    }

                                    final messenger = ScaffoldMessenger.of(context);
                                    Navigator.pop(sheetContext);

                                    final success = await controller.changePassword(
                                      currentPassword:
                                          currentPasswordController.text.trim(),
                                      newPassword: newPasswordController.text.trim(),
                                    );

                                    if (!mounted) return;

                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? 'Password changed successfully'
                                              : 'Failed to change password',
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: fieldFocusColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Update'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }
}
