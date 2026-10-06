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
  static const blue = Color(0xff0d0b8e);

  void open(Widget page, int target) =>
      Navigator.of(context).push(slideRoute(page, from: 0, to: target));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff222222),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          color: Colors.white,
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
                                color: Color(0xff3896ff),
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
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTablet ? 22 : 30),
                        const Text(
                          'Hello, Teacher Juan!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'What would you like to do today?',
                          style: TextStyle(color: Colors.white, fontSize: 12),
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
                          'Quick Actions',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            QuickAction(
                              icon: Icons.qr_code_2,
                              label: 'Scan QR Code',
                              color: blue,
                              height: actionHeight,
                              onTap: () => open(const ScanScreen(), 2),
                            ),
                            const SizedBox(width: 12),
                            QuickAction(
                              icon: Icons.assignment_outlined,
                              label: 'My Reports',
                              color: const Color(0xff3d781c),
                              height: actionHeight,
                              onTap: () => open(const ReportsScreen(), 1),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            QuickAction(
                              icon: Icons.notifications_none,
                              label: 'Notifications',
                              color: const Color(0xffa9a900),
                              height: actionHeight,
                              onTap: () => open(const NotificationsScreen(), 3),
                            ),
                            const SizedBox(width: 12),
                            QuickAction(
                              icon: Icons.desktop_windows_outlined,
                              label: 'Lab Computers',
                              color: const Color(0xff3e1398),
                              height: actionHeight,
                              onTap: () => open(const ComputerListScreen(), 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Summary',
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
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
      elevation: 3,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 31),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    margin: const EdgeInsets.only(bottom: 5),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
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
        Icon(icon, size: 19, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          count,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
