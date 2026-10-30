import 'package:flutter/material.dart';

import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/scan_screen.dart';

void navigateFrom(BuildContext context, int index, int selected) {
  if (index == selected) return;

  final navigator = Navigator.of(context);
  navigator.popUntil(
    (route) => route.settings.name == '/dashboard' || route.isFirst,
  );
  if (index == 0) return;

  final page = switch (index) {
    1 => const ReportsScreen(),
    2 => const ScanScreen(),
    3 => const NotificationsScreen(),
    4 => const ProfileScreen(),
    _ => null,
  };
  if (page != null) {
    navigator.push(noAnimationRoute((_) => page));
  }
}

PageRoute<T> noAnimationRoute<T>(
  WidgetBuilder builder, {
  RouteSettings? settings,
}) => PageRouteBuilder<T>(
  settings: settings,
  pageBuilder: (context, _, _) => builder(context),
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, _, _, child) => child,
);

void openDissolve(BuildContext context, Widget page) {
  Navigator.of(context).push(noAnimationRoute((_) => page));
}
