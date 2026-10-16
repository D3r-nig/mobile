import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'widgets/brand_mark.dart';

class ItlabcareApp extends StatelessWidget {
  const ItlabcareApp({
    super.key,
    this.signIn,
    this.passwordReset,
    this.emailLookup,
  });

  final StudentSignIn? signIn;
  final StudentPasswordReset? passwordReset;
  final StudentEmailLookup? emailLookup;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ITLABCARE',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xff155bb2),
        primary: const Color(0xff155bb2),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Arial',
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          height: 1.08,
          fontWeight: FontWeight.w800,
          color: Color(0xff17243a),
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: Color(0xff17243a),
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          height: 1.2,
          fontWeight: FontWeight.w800,
          color: Color(0xff17243a),
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: Color(0xff17243a),
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Color(0xff344054),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: Color(0xff66758a),
        ),
        labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(44, 44),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    ),
    builder: (context, child) => child ?? const SizedBox.shrink(),
    home: OpeningScreen(
      signIn: signIn,
      passwordReset: passwordReset,
      emailLookup: emailLookup,
    ),
  );
}

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({
    super.key,
    this.signIn,
    this.passwordReset,
    this.emailLookup,
  });

  final StudentSignIn? signIn;
  final StudentPasswordReset? passwordReset;
  final StudentEmailLookup? emailLookup;

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with SingleTickerProviderStateMixin {
  static const handoffDelay = Duration(milliseconds: 450);
  static const openingDuration = Duration(milliseconds: 1800);

  late final AnimationController _controller;
  Timer? _startTimer;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: openingDuration);
    _startTimer = Timer(handoffDelay, _controller.forward);
    _timer = Timer(handoffDelay + const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (_, _, _) => AuthScreen(
            signIn: widget.signIn,
            passwordReset: widget.passwordReset,
            emailLookup: widget.emailLookup,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (_, _, _, child) => child,
        ),
      );
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = Curves.easeOutBack.transform(_controller.value);
          final textOpacity = const Interval(
            0.48,
            1,
            curve: Curves.easeOut,
          ).transform(_controller.value);
          return Opacity(
            opacity: _controller.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: 0.72 + (value * 0.28),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.rotate(
                        angle: _controller.value * 6.28318,
                        child: const SizedBox(
                          width: 238,
                          height: 238,
                          child: CircularProgressIndicator(
                            value: 0.72,
                            strokeWidth: 2,
                            color: Color(0xff3f8ef5),
                            backgroundColor: Color(0xff263044),
                          ),
                        ),
                      ),
                      child!,
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: textOpacity,
                  child: const Column(
                    children: [
                      Text(
                        'ITLABCARE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.2,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Computer Laboratory Management System',
                        style: TextStyle(
                          color: Color(0xff9aa7bd),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        child: Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(34),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x553f8ef5),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const BrandMark(size: 152),
        ),
      ),
    ),
  );
}

abstract final class AppColors {
  static const primary = Color(0xff155bb2);
  static const background = Color(0xfff6f8fb);
  static const surface = Colors.white;
  static const ink = Color(0xff17243a);
  static const muted = Color(0xff66758a);
  static const border = Color(0xffd9e1ea);
  static const success = Color(0xff248a49);
  static const warning = Color(0xffb7791f);
  static const danger = Color(0xffc2414b);
}
