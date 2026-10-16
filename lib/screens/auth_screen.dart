import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/navigation.dart';
import '../widgets/brand_mark.dart';
import 'dashboard_screen.dart';

enum AuthView { login, resetPassword, resetSent }

typedef StudentSignIn = Future<void> Function(String email, String password);
typedef StudentPasswordReset = Future<void> Function(String email);
typedef StudentEmailLookup = Future<bool> Function(String email);

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.signIn,
    this.passwordReset,
    this.emailLookup,
  });

  final StudentSignIn? signIn;
  final StudentPasswordReset? passwordReset;
  final StudentEmailLookup? emailLookup;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  AuthView view = AuthView.login;
  bool hidePassword = true;
  bool signingIn = false;
  bool sendingReset = false;
  String? errorText;
  int _activeResetRequestId = 0;
  static const navy = Color(0xff11112a);
  static const action = Color(0xff155bb2);
  static const apiBaseUrl = String.fromEnvironment('ITLABCARE_API_BASE_URL');

  @override
  void initState() {
    super.initState();
    emailController.addListener(_handleEmailChanged);
  }

  void _handleEmailChanged() {
    if (mounted && (errorText != null || sendingReset)) {
      setState(() {
        errorText = null;
        if (sendingReset) {
          _activeResetRequestId++;
          sendingReset = false;
        }
      });
    }
  }

  void showView(AuthView next) => setState(() => view = next);

  void backToLogin() => setState(() {
    errorText = null;
    view = AuthView.login;
  });

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorText = 'Please enter your email and password.');
      return;
    }

    setState(() {
      signingIn = true;
      errorText = null;
    });

    try {
      final signIn =
          widget.signIn ??
          (String email, String password) async {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
          };
      await signIn(email, password);
      if (!mounted) return;
      Navigator.of(context).push(
        noAnimationRoute(
          settings: const RouteSettings(name: '/dashboard'),
          (_) => const DashboardScreen(),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(
        () => errorText = switch (error.code) {
          'user-not-found' ||
          'wrong-password' ||
          'invalid-credential' => 'Invalid email or password.',
          'invalid-email' => 'Please enter a valid email address.',
          'user-disabled' => 'This student account is disabled.',
          _ => error.message ?? 'Sign in failed. Please try again.',
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => errorText = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  Future<void> sendPasswordReset() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorText = 'Please enter a valid email address.');
      return;
    }

    final requestId = ++_activeResetRequestId;
    bool isCurrentRequest() =>
        mounted &&
        requestId == _activeResetRequestId &&
        email == emailController.text.trim();

    setState(() {
      sendingReset = true;
      errorText = null;
    });

    final emailLookup = widget.emailLookup ?? _checkEmailRegistration;
    try {
      bool registered;
      try {
        registered = await emailLookup(email);
      } catch (error) {
        if (isCurrentRequest()) {
          setState(() => errorText = _emailLookupErrorMessage(error));
        }
        return;
      }

      if (!isCurrentRequest()) return;
      if (!registered) {
        setState(
          () => errorText = 'This email address is not registered in our database. Please enter a valid email address.',
        );
        return;
      }

      final passwordReset =
          widget.passwordReset ??
          (String email) async {
            await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
          };
      await passwordReset(email);
      if (!isCurrentRequest()) return;
      showView(AuthView.resetSent);
    } on FirebaseAuthException catch (error) {
      if (!isCurrentRequest()) return;
      setState(
        () => errorText = switch (error.code) {
          'user-not-found' => 'This email address is not registered in our database. Please enter a valid email address.',
          'invalid-email' => 'Please enter a valid email address.',
          'too-many-requests' =>
            'Too many requests. Please wait a while and try again.',
          'network-request-failed' =>
            'Could not connect. Check your internet connection and try again.',
          _ => 'Could not send a password reset email. Please try again.',
        },
      );
    } catch (_) {
      if (!isCurrentRequest()) return;
      setState(
        () => errorText =
            'Could not send a password reset email. Please try again.',
      );
    } finally {
      if (mounted && requestId == _activeResetRequestId) {
        setState(() => sendingReset = false);
      }
    }
  }

  Future<bool> _checkEmailRegistration(String email) async {
    final baseUrl = apiBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw StateError('ITLABCARE_API_BASE_URL is not configured.');
    }

    final response = await http
        .post(
          Uri.parse(
            '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/password-reset/check-email',
          ),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'email': email}),
        )
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError(
        'Email registration check failed with status ${response.statusCode}.',
      );
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic> || payload['registered'] is! bool) {
      throw const FormatException('Invalid email registration response.');
    }
    if (payload['email'] is String && payload['email'] != email.toLowerCase()) {
      throw const FormatException('Email registration response mismatch.');
    }

    return payload['registered'] as bool;
  }

  String _emailLookupErrorMessage(Object error) {
    final details = error.toString().toLowerCase();
    if (details.contains('itlabcare_api_base_url')) {
      return 'Mobile API URL is not configured. Please rebuild the app with the Laravel API URL.';
    }
    if (details.contains('failed with status 500')) {
      return 'Server could not verify emails. Please start/fix MySQL, then try again.';
    }
    if (details.contains('socket') ||
        details.contains('connection') ||
        details.contains('timed out') ||
        details.contains('xmlhttprequest')) {
      return 'Could not connect to the server. Please make sure Laravel API is running.';
    }

    return 'Could not verify your email address. Please try again.';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            MediaQuery.sizeOf(context).height < 700 ? 24 : 48,
            24,
            28,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width >= 600 ? 720 : 390,
            ),
            child: switch (view) {
              AuthView.login => loginView(),
              AuthView.resetPassword => resetPasswordView(),
              AuthView.resetSent => resetSentView(),
            },
          ),
        ),
      ),
    ),
  );

  Widget loginView() => Column(
    children: [
      const SizedBox(height: 10),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutBack,
        builder: (context, value, child) => Opacity(
          opacity: value.clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: 0.86 + (value * 0.14), child: child),
        ),
        child: const BrandMark(size: 104),
      ),
      const SizedBox(height: 12),
      const Text(
        'ITLABCARE',
        style: TextStyle(
          color: Color(0xff155bb2),
          fontSize: 19,
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
      const SizedBox(height: 22),
      const Text(
        'Welcome Back!',
        style: TextStyle(
          color: navy,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Please sign in to continue',
        style: TextStyle(color: Color(0xff66758a), fontSize: 14),
      ),
      const SizedBox(height: 22),
      Field(
        label: 'Email',
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) {
          if (errorText != null) setState(() => errorText = null);
        },
      ),
      const SizedBox(height: 9),
      Field(
        label: 'Password',
        controller: passwordController,
        obscure: hidePassword,
        toggle: () => setState(() => hidePassword = !hidePassword),
      ),
      if (errorText != null) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xffc2414b),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () {
            setState(() {
              errorText = null;
              view = AuthView.resetPassword;
            });
          },
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
        label: signingIn ? 'Signing In...' : 'Sign In',
        onPressed: signingIn ? null : signIn,
      ),
      const SizedBox(height: 16),
    ],
  );

  Widget resetPasswordView() => Column(
    children: [
      const SizedBox(height: 28),
      const Text(
        'Reset Your Password',
        style: TextStyle(
          color: navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 68),
      const Icon(Icons.lock_reset_rounded, size: 96, color: Color(0xff3f8ef5)),
      const Text(
        'Enter your account email',
        style: TextStyle(
          color: navy,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      const Text(
        'and we’ll send you a password reset link.',
        style: TextStyle(color: Color(0xff444444), fontSize: 14),
      ),
      const SizedBox(height: 24),
      Field(
        label: 'Email',
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        onChanged: (_) {
          if (errorText != null) setState(() => errorText = null);
        },
      ),
      if (errorText != null) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            errorText!,
            style: const TextStyle(
              color: Color(0xffc2414b),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      ActionButton(
        label: sendingReset ? 'Sending...' : 'Send Reset Link',
        onPressed: sendingReset ? null : sendPasswordReset,
      ),
      TextButton(onPressed: backToLogin, child: const Text('Back to Login')),
    ],
  );

  Widget resetSentView() => Column(
    children: [
      const SizedBox(height: 28),
      const Text(
        'Password Reset Email Sent',
        style: TextStyle(
          color: navy,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 24),
      const Icon(
        Icons.mark_email_read_rounded,
        size: 96,
        color: Color(0xff3f8ef5),
      ),
      const SizedBox(height: 20),
      const Text(
        'Password reset instructions have been sent successfully. Please check your email.',
        style: TextStyle(color: Color(0xff444444), fontSize: 13),
      ),
      const SizedBox(height: 32),
      ActionButton(
        label: 'Back to Login',
        onPressed: () => showView(AuthView.login),
      ),
    ],
  );
}
