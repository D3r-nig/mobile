import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/navigation.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key, required this.mode});
  final ProfileDetailMode mode;

  @override
  Widget build(BuildContext context) => mode == ProfileDetailMode.password
      ? const PasswordUpdateView()
      : const PersonalInformationView();
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
  const PersonalInformationView({super.key});

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
        const DetailField(label: 'Full Name', value: 'Alexander John Aspiras'),
        const DetailField(label: 'Email', value: 'alexander.aspiras@student.edu'),
        const DetailField(label: 'Student No.', value: '2026-0001'),
        const DetailField(label: 'Course / Year', value: 'BSIT 2'),
        const DetailField(label: 'Department', value: 'CITE'),
        const SizedBox(height: 14),
        ActionButton(label: 'Save Changes', onPressed: _showSaved),
      ],
    ),
  );

  static void _showSaved() {}
}

class PasswordUpdateView extends StatefulWidget {
  const PasswordUpdateView({super.key});
  @override
  State<PasswordUpdateView> createState() => _PasswordUpdateViewState();
}

class _PasswordUpdateViewState extends State<PasswordUpdateView> {
  bool hideCurrent = true;
  bool hideNew = true;
  bool hideConfirm = true;

  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Update Password',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailField(
          label: 'Current Password',
          value: 'Labcare2026!',
          obscure: hideCurrent,
          toggle: () => setState(() => hideCurrent = !hideCurrent),
        ),
        DetailField(
          label: 'New Password',
          value: 'NewLabcare8!',
          obscure: hideNew,
          toggle: () => setState(() => hideNew = !hideNew),
        ),
        DetailField(
          label: 'Confirm New Password',
          value: 'NewLabcare8!',
          obscure: hideConfirm,
          toggle: () => setState(() => hideConfirm = !hideConfirm),
        ),
        const SizedBox(height: 12),
        const PasswordRequirements(),
        const SizedBox(height: 14),
        ActionButton(label: 'Update Password', onPressed: _showUpdated),
      ],
    ),
  );

  void _showUpdated() => Navigator.of(context).pushReplacement(
    noAnimationRoute((_) => const PasswordUpdatedScreen()),
  );
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
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
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
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
    decoration: BoxDecoration(
      color: const Color(0xffeeeeee),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Requirements',
          style: TextStyle(
            color: Color(0xff20205b),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        RequirementRow(text: 'Minimum 8 characters', valid: true),
        RequirementRow(text: 'At least one uppercase letter'),
        RequirementRow(text: 'At least one number'),
        RequirementRow(text: 'At least one special character (!@#\$%)'),
      ],
    ),
  );
}

class RequirementRow extends StatelessWidget {
  const RequirementRow({super.key, required this.text, this.valid = false});
  final String text;
  final bool valid;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        valid ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 14,
        color: valid ? const Color(0xff41b94f) : const Color(0xffa3a3a3),
      ),
      const SizedBox(width: 5),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: valid ? const Color(0xff39751e) : const Color(0xff777777),
            fontSize: 10,
          ),
        ),
      ),
    ],
  );
}
