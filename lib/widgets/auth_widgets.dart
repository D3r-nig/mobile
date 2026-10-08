import 'package:flutter/material.dart';

class Field extends StatelessWidget {
  const Field({
    super.key,
    required this.label,
    this.obscure = false,
    this.toggle,
  });
  final String label;
  final bool obscure;
  final VoidCallback? toggle;

  IconData get icon => switch (label) {
    'Email or Username' || 'Email' => Icons.alternate_email,
    'Password' || 'Confirm Password' => Icons.lock_outline,
    'Full Name' => Icons.person_outline,
    _ => Icons.edit_outlined,
  };

  @override
  Widget build(BuildContext context) => TextField(
    obscureText: obscure,
    style: const TextStyle(fontSize: 14, color: Color(0xff17243a)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xff66758a), fontSize: 13),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xff66758a)),
      suffixIcon: toggle == null
          ? null
          : IconButton(
              onPressed: toggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: const Color(0xff66758a),
              ),
            ),
    ),
  );
}

class RoleField extends StatelessWidget {
  const RoleField({super.key});

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: 'Teacher',
    items: const [
      DropdownMenuItem(
        value: 'Teacher',
        child: Text('Teacher', style: TextStyle(fontSize: 14)),
      ),
      DropdownMenuItem(
        value: 'Student',
        child: Text('Student', style: TextStyle(fontSize: 14)),
      ),
    ],
    onChanged: (_) {},
    decoration: const InputDecoration(
      labelText: 'Role',
      labelStyle: TextStyle(color: Color(0xff66758a), fontSize: 12),
      prefixIcon: Icon(Icons.badge_outlined, color: Color(0xff66758a), size: 20),
    ),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff155bb2),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class Prompt extends StatelessWidget {
  const Prompt({
    super.key,
    required this.text,
    required this.action,
    required this.onPressed,
  });
  final String text;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(text, style: const TextStyle(fontSize: 13, color: Color(0xff66758a))),
      GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xff155bb2),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ],
  );
}

class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, required this.onBack});
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff11112a),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}
