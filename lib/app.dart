import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';

class ItlabcareApp extends StatelessWidget {
  const ItlabcareApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ITLABCARE',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3937e8)),
      scaffoldBackgroundColor: const Color(0xfffdfdfd),
      fontFamily: 'Arial',
    ),
    builder: (context, child) =>
        ResponsiveAppShell(child: child ?? const SizedBox.shrink()),
    home: const AuthScreen(),
  );
}

/// Provides the available viewport to every screen so each layout can respond
/// to the current phone, tablet, or desktop width.
class ResponsiveAppShell extends StatelessWidget {
  const ResponsiveAppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isTablet = constraints.maxWidth >= 600;
      final isLargePhone = !isTablet && constraints.maxWidth >= 380;
      final textScale = isTablet ? 0.92 : (isLargePhone ? 1.05 : 1.0);

      return ColoredBox(
        color: const Color(0xfffdfdfd),
        child: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
