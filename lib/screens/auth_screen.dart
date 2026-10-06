import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/brand_mark.dart';
import 'dashboard_screen.dart';

enum AuthView { login, signUp, verify }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthView view = AuthView.login;
  bool hidePassword = true;
  bool hideConfirm = true;
  static const navy = Color(0xff11112a);
  static const action = Color(0xff3937e8);

  void showView(AuthView next) => setState(() => view = next);

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.sizeOf(context).height < 700
                ? 24
                : (view == AuthView.signUp ? 32 : 80),
            24,
            28,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width >= 600 ? 720 : 390,
            ),
            child: switch (view) {
              AuthView.login => loginView(),
              AuthView.signUp => signUpView(),
              AuthView.verify => verifyView(),
            },
          ),
        ),
      ),
    ),
  );

  Widget loginView() => Column(
    children: [
      const SizedBox(height: 22),
      const BrandMark(size: 132),
      const SizedBox(height: 18),
      const Text(
        'ITLABCARE',
        style: TextStyle(
          color: Color(0xff155bb2),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: .5,
        ),
      ),
      const Text(
        'Computer Laboratory',
        style: TextStyle(
          color: navy,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const Text(
        'Management System',
        style: TextStyle(
          color: navy,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 18),
      const Text(
        'Welcome Back!',
        style: TextStyle(
          color: navy,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      const Text(
        'Please sign in to continue',
        style: TextStyle(color: Color(0xff747474), fontSize: 11),
      ),
      const SizedBox(height: 24),
      const Field(label: 'Email or Username'),
      const SizedBox(height: 9),
      Field(
        label: 'Password',
        obscure: hidePassword,
        toggle: () => setState(() => hidePassword = !hidePassword),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => showView(AuthView.verify),
          child: const Text(
            'Forgot Password?',
            style: TextStyle(
              color: action,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      ActionButton(
        label: 'Sign In',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: '/dashboard'),
            builder: (_) => const DashboardScreen(),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Prompt(
        text: "Don't have an account?",
        action: 'Sign Up',
        onPressed: () => showView(AuthView.signUp),
      ),
    ],
  );

  Widget signUpView() => Column(
    children: [
      BackHeader(
        title: 'Create Account',
        onBack: () => showView(AuthView.login),
      ),
      const SizedBox(height: 10),
      const SizedBox(
        width: 82,
        height: 82,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 78,
              color: Color(0xffd8d8d8),
            ),
            Positioned(
              right: 0,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xff333333),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.camera_alt, size: 11, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Field(label: 'Full Name'),
      const SizedBox(height: 9),
      const Field(label: 'Email'),
      const SizedBox(height: 9),
      const RoleField(),
      const SizedBox(height: 9),
      Field(
        label: 'Password',
        obscure: hidePassword,
        toggle: () => setState(() => hidePassword = !hidePassword),
      ),
      const SizedBox(height: 9),
      Field(
        label: 'Confirm Password',
        obscure: hideConfirm,
        toggle: () => setState(() => hideConfirm = !hideConfirm),
      ),
      const SizedBox(height: 16),
      ActionButton(
        label: 'Sign Up',
        onPressed: () => showView(AuthView.verify),
      ),
      const SizedBox(height: 16),
      Prompt(
        text: 'Already have an account?',
        action: 'Sign In',
        onPressed: () => showView(AuthView.login),
      ),
    ],
  );

  Widget verifyView() => Column(
    children: [
      const SizedBox(height: 28),
      const Text(
        'Verify Your Account',
        style: TextStyle(
          color: navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 68),
      const Icon(
        Icons.mark_email_read_rounded,
        size: 122,
        color: Color(0xff3f8ef5),
      ),
      const SizedBox(height: 30),
      const Text(
        "We've sent a verification link",
        style: TextStyle(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text(
        'to your email.',
        style: TextStyle(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 20),
      const Text(
        'Please check your inbox and click the',
        style: TextStyle(color: Color(0xff444444), fontSize: 11),
      ),
      const Text(
        'link to verify your account.',
        style: TextStyle(color: Color(0xff444444), fontSize: 11),
      ),
      const SizedBox(height: 54),
      ActionButton(
        label: 'Go to Login',
        onPressed: () => showView(AuthView.login),
      ),
      const SizedBox(height: 13),
      TextButton(
        onPressed: () {},
        child: const Text(
          'Resend Email (00:45)',
          style: TextStyle(
            color: Color(0xff6d6af0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}
