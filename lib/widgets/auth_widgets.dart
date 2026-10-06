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

  @override
  Widget build(BuildContext context) => TextField(
    obscureText: obscure,
    style: const TextStyle(fontSize: 12),
    decoration: InputDecoration(
      hintText: label,
      hintStyle: const TextStyle(color: Color(0xffa4a4a4), fontSize: 10),
      suffixIcon: toggle == null
          ? null
          : IconButton(
              onPressed: toggle,
              icon: Icon(
                obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 17,
                color: const Color(0xff999999),
              ),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xffeeeeee)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xffeeeeee)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xff3937e8)),
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
        child: Text('Teacher', style: TextStyle(fontSize: 11)),
      ),
      DropdownMenuItem(
        value: 'Student',
        child: Text('Student', style: TextStyle(fontSize: 11)),
      ),
    ],
    onChanged: (_) {},
    decoration: const InputDecoration(
      labelText: 'Role',
      labelStyle: TextStyle(color: Color(0xffaaaaaa), fontSize: 9),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xffeeeeee)),
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xffeeeeee)),
        borderRadius: BorderRadius.all(Radius.circular(7)),
      ),
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
    height: 42,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff3937e8),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
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
      Text(text, style: const TextStyle(fontSize: 10)),
      GestureDetector(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.only(left: 3),
          child: Text(
            action,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xff3937e8),
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
        icon: const Icon(Icons.arrow_back_ios_new, size: 17),
      ),
      Expanded(
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff11112a),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}
