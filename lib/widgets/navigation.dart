import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/scan_screen.dart';

void navigateFrom(BuildContext context, int index, int selected) {
  if (index == selected) return;
  if (index == 0) {
    Navigator.of(context)
        .popUntil((route) => route.settings.name == '/dashboard');
    return;
  }

  final page = switch (index) {
    1 => const ReportsScreen(),
    2 => const ScanScreen(),
    3 => const NotificationsScreen(),
    4 => const ProfileScreen(),
    _ => null,
  };
  if (page != null) {
    Navigator.of(context).push(slideRoute(page, from: selected, to: index));
  }
}

PageRouteBuilder<void> slideRoute(
  Widget page, {
  required int from,
  required int to,
}) {
  return PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => page,
    transitionDuration: const Duration(milliseconds: 180),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (_, animation, _, child) {
      final eased = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: eased,
        child: ScaleTransition(
          scale: Tween<double>(begin: .985, end: 1).animate(eased),
          child: child,
        ),
      );
    },
  );
}

void openDissolve(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 225),
      reverseTransitionDuration: const Duration(milliseconds: 225),
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      ),
    ),
  );
}
