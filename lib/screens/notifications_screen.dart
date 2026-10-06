import 'package:flutter/material.dart';

import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'scan_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Notification'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Status Timeline',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Mark all as read',
                      style: TextStyle(fontSize: 8, color: Color(0xff397eff)),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Notice(
                  icon: Icons.info_outline,
                  title: 'Report #1021 Updated',
                  body: 'Your report #1021 was updated. No display on monitor - PC - 001 has been changed to In Progress.',
                  time: 'Just now',
                  color: Color(0xff4c9df2),
                ),
                Notice(
                  icon: Icons.check_circle_outline,
                  title: 'Maintenance Completed',
                  body: 'Hardware diagnostics and updates successfully completed on PC - 001 in Lab 306.',
                  time: '2 hours ago',
                  color: Color(0xff54d769),
                ),
                Notice(
                  icon: Icons.warning_amber_rounded,
                  title: 'Lab 3 Temporary Closure',
                  body: 'Computer Lab 3 will be closed for scheduled hardware maintenance on Aug 20.',
                  time: '1 day ago',
                  color: Color(0xffe3b31f),
                ),
              ],
            ),
          ),
          AppNavBar(
            selected: 3,
            onSelected: (index) => navigateFrom(context, index, 3),
          ),
        ],
      ),
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
  });
  final IconData icon;
  final String title, body, time;
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => NotificationDetailsScreen(
          title: title,
          body: body,
          time: time,
          icon: icon,
          color: color,
        ),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    ),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffeeeeee)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 7,
                        color: Color(0xff777777),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xff0d0b8e),
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 22),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Notification Details',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
              color: const Color(0xffedf5ff),
              padding: const EdgeInsets.all(18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 600
                      ? (constraints.maxWidth - 36).clamp(300.0, 900.0)
                      : 300.0;
                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x18000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: color.withAlpha(40),
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Icon(icon, color: color, size: 28),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff777777),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff333333),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xfff2f2f2),
                                  foregroundColor: const Color(0xff333333),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          AppNavBar(
            selected: 3,
            onSelected: (index) => navigateFrom(context, index, 3),
          ),
        ],
      ),
    ),
  );
}
