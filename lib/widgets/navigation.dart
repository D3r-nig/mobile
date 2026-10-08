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
    Navigator.of(context).push(noAnimationRoute((_) => page));
  }
}

PageRoute<T> noAnimationRoute<T>(WidgetBuilder builder, {RouteSettings? settings}) =>
    PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, _, __) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      transitionsBuilder: (_, __, ___, child) => child,
    );

void openDissolve(BuildContext context, Widget page) {
  Navigator.of(context).push(noAnimationRoute((_) => page));
}
