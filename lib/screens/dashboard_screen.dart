import 'package:flutter/material.dart';

import '../widgets/brand_mark.dart';
import '../widgets/navigation.dart';
import '../widgets/app_nav_bar.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'reports_screen.dart';
import 'scan_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const ink = Color(0xff11112a);
  static const blue = Color(0xff155bb2);

  void open(Widget page, int target) =>
      Navigator.of(context).push(noAnimationRoute((_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff6f8fb),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          color: const Color(0xfff6f8fb),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Keep phones fluid while giving tablets a wider centered dashboard.
              final isTablet = constraints.maxWidth >= 600;
              final isLargePhone = !isTablet && constraints.maxWidth >= 380;
              final compactTablet = isTablet && constraints.maxHeight < 720;
              final logoSize = isTablet
                  ? (compactTablet ? 48.0 : 56.0)
                  : (isLargePhone ? 60.0 : 54.0);
              final actionHeight = isTablet
                  ? (compactTablet ? 70.0 : 84.0)
                  : (isLargePhone ? 82.0 : 76.0);
              final summaryHeight = isTablet
                  ? (compactTablet ? 34.0 : 40.0)
                  : (isLargePhone ? 38.0 : 36.0);

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 25),
                    decoration: const BoxDecoration(
                      color: blue,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: logoSize,
                              height: logoSize,
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: BrandMark(size: logoSize - 4),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'IT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTablet ? 18 : 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'LABCARE',
                              style: TextStyle(
                              color: Color(0xff8cc5ff),
                                fontSize: isTablet ? 18 : 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () =>
                                  open(const NotificationsScreen(), 3),
                              icon: const Icon(
                                Icons.notifications_none,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 22 : 30),
                        const Text(
                          'Hello, Student Xander!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'What would you like to do today?',
                          style: TextStyle(color: Color(0xffdbeafe), fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Start with a scan',
                          style: TextStyle(
                            color: ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FeaturedAction(
                          onTap: () => open(const ScanScreen(), 2),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            QuickAction(
                              icon: Icons.assignment_outlined,
                              label: 'My Reports',
                              color: const Color(0xff248a49),
                              height: actionHeight,
                              onTap: () => open(const ReportsScreen(), 1),
                            ),
                            const SizedBox(width: 12),
                            QuickAction(
                              icon: Icons.desktop_windows_outlined,
                              label: 'Lab Computers',
                              color: const Color(0xff6b4acb),
                              height: actionHeight,
                              onTap: () => open(const ComputerListScreen(), 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            QuickAction(
                              icon: Icons.notifications_none,
                              label: 'Notifications',
                              color: const Color(0xffb7791f),
                              height: actionHeight,
                              onTap: () =>
                                  open(const NotificationsScreen(), 3),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Summary',
                          style: TextStyle(
                            color: ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4, bottom: 5),
                          child: Text(
                            'Activity overview',
                            style: TextStyle(
                              color: Color(0xff66758a),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SummaryRow(
                          icon: Icons.assignment_outlined,
                          label: 'My Reports',
                          count: '2',
                          color: Color(0xff39751e),
                          height: summaryHeight,
                        ),
                        SummaryRow(
                          icon: Icons.timelapse,
                          label: 'In Progress',
                          count: '1',
                          color: Color(0xffaeae00),
                          height: summaryHeight,
                        ),
                        SummaryRow(
                          icon: Icons.done_all,
                          label: 'Resolved',
                          count: '1',
                          color: Color(0xff397eff),
                          height: summaryHeight,
                        ),
                      ],
                    ),
                  ),
                        ],
                      ),
                    ),
                  ),
                  AppNavBar(
                    selected: 0,
                    onSelected: (index) {
                      switch (index) {
                        case 1:
                          open(const ReportsScreen(), 1);
                          break;
                        case 2:
                          open(const ScanScreen(), 2);
                          break;
                        case 3:
                          open(const NotificationsScreen(), 3);
                          break;
                        case 4:
                          open(const ProfileScreen(), 4);
                          break;
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}

class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.height,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double height;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffe0e7ef)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withAlpha(24),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 25),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class FeaturedAction extends StatelessWidget {
  const FeaturedAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xff155bb2),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0x26ffffff),
              child: Icon(Icons.qr_code_scanner, color: Colors.white, size: 27),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Identify a lab computer and report an issue',
                    style: TextStyle(color: Color(0xffdbeafe), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    ),
  );
}

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.height,
  });
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xffe0e7ef)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withAlpha(24),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
