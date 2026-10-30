import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/navigation.dart';
import '../services/profile_service.dart';

typedef StudentPasswordUpdate = Future<void> Function(
  String currentPassword,
  String newPassword,
);

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({
    super.key,
    required this.mode,
    this.profile,
    this.updatePassword,
  });

  final ProfileDetailMode mode;
  final StudentProfile? profile;
  final StudentPasswordUpdate? updatePassword;

  @override
  Widget build(BuildContext context) => mode == ProfileDetailMode.password
      ? PasswordUpdateView(updatePassword: updatePassword)
      : PersonalInformationView(profile: profile);
}

enum ProfileDetailMode { personal, password }

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({super.key, required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            color: const Color(0xff155bb2),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 26, 16, 28),
                child: child,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class PersonalInformationView extends StatelessWidget {
  const PersonalInformationView({super.key, this.profile});

  final StudentProfile? profile;

  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Personal Information',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 27,
          backgroundColor: Color(0xff72a1bc),
          child: Icon(Icons.person, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        DetailField(
          label: 'Full Name',
          value: profile?.fullName ?? 'Not provided',
        ),
        DetailField(label: 'Email', value: profile?.email ?? 'Not provided'),
        DetailField(
          label: 'Student No.',
          value: profile?.studentNumber ?? 'Not provided',
        ),
        DetailField(
          label: 'Section',
          value: profile?.section ?? 'Not provided',
        ),
        DetailField(
          label: 'Adviser',
          value: profile?.adviser ?? 'Not provided',
        ),
        DetailField(
          label: 'Account Status',
          value: profile?.accountStatus ?? 'Not provided',
        ),
      ],
    ),
  );
}

class PasswordUpdateView extends StatefulWidget {
  const PasswordUpdateView({super.key, this.updatePassword});

  final StudentPasswordUpdate? updatePassword;

  @override
  State<PasswordUpdateView> createState() => _PasswordUpdateViewState();
}

class _PasswordUpdateViewState extends State<PasswordUpdateView> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;
  bool isSubmitting = false;
  String? errorText;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Update Password',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _passwordField(
          label: 'Current Password',
          controller: _currentPasswordController,
          obscure: hideCurrent,
          toggle: () => setState(() => hideCurrent = !hideCurrent),
        ),
        _passwordField(
          label: 'New Password',
          controller: _newPasswordController,
          obscure: hideNew,
          toggle: () => setState(() => hideNew = !hideNew),
        ),
        _passwordField(
          label: 'Confirm New Password',
          controller: _confirmPasswordController,
          obscure: hideConfirm,
          toggle: () => setState(() => hideConfirm = !hideConfirm),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color(0xffb42318), fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),
        const PasswordRequirements(),
        const SizedBox(height: 14),
        ActionButton(
          label: isSubmitting ? 'Updating…' : 'Update Password',
          onPressed: isSubmitting ? null : _submit,
        ),
      ],
    ),
  );

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xff222222),
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              onPressed: toggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() => errorText = 'Enter your current and new password.');
      return;
    }
    if (newPassword.length < 8) {
      setState(
        () => errorText = 'Your new password must be at least 8 characters.',
      );
      return;
    }
    if (newPassword != _confirmPasswordController.text) {
      setState(() => errorText = 'The new passwords do not match.');
      return;
    }

    setState(() {
      errorText = null;
      isSubmitting = true;
    });
    try {
      await (widget.updatePassword ?? _updateFirebasePassword)(
        currentPassword,
        newPassword,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(noAnimationRoute((_) => const PasswordUpdatedScreen()));
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() => errorText = _passwordErrorMessage(error));
    } catch (_) {
      if (!mounted) return;
      setState(
        () => errorText = 'Could not update your password. Please try again.',
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _updateFirebasePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw FirebaseAuthException(code: 'no-current-user');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  String _passwordErrorMessage(
    FirebaseAuthException error,
  ) => switch (error.code) {
    'requires-recent-login' =>
      'For your security, sign in again before changing your password.',
    'wrong-password' ||
    'invalid-credential' => 'Your current password is incorrect.',
    'weak-password' => 'Choose a stronger password with at least 8 characters.',
    'network-request-failed' =>
      'Could not connect. Check your connection and try again.',
    'no-current-user' => 'Please sign in again before changing your password.',
    _ => 'Could not update your password. Please try again.',
  };
}

class PasswordUpdatedScreen extends StatelessWidget {
  const PasswordUpdatedScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: Color(0xff62ad5b),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 64),
              ),
              const SizedBox(height: 24),
              const Text(
                'Password Updated',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been\nsuccessfully updated.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 24),
              ActionButton(
                label: 'Back to Home',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class DetailField extends StatelessWidget {
  const DetailField({
    super.key,
    required this.label,
    required this.value,
    this.obscure = false,
    this.toggle,
  });
  final String label;
  final String value;
  final bool obscure;
  final VoidCallback? toggle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 5),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xff222222),
            ),
          ),
        ),
        TextField(
          controller: TextEditingController(text: value),
          obscureText: obscure,
          readOnly: toggle == null,
          style: const TextStyle(fontSize: 11, color: Color(0xff333333)),
          decoration: InputDecoration(
            suffixIcon: toggle == null
                ? null
                : IconButton(
                    onPressed: toggle,
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: const Color(0xff999999),
                    ),
                  ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffeeeeee)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xffeeeeee)),
            ),
          ),
        ),
      ],
    ),
  );
}

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xffeeeeee),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Choose a password with at least 8 characters.',
      style: TextStyle(
        color: Color(0xff20205b),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
