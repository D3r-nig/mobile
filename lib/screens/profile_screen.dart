import 'dart:ui';

import 'package:flutter/material.dart';

import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'auth_screen.dart';
import 'profile_detail_screen.dart';
import 'preference_screens.dart';
import 'scan_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Profile'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const ProfileCard(),
                const SectionTitle(text: 'ACCOUNT SETTINGS'),
                SettingRow(
                  icon: Icons.person_outline,
                  label: 'Personal Information',
                  onTap: () => openDissolve(
                    context,
                    const ProfileDetailScreen(mode: ProfileDetailMode.personal),
                  ),
                ),
                SettingRow(
                  icon: Icons.business_outlined,
                  label: 'My Department',
                  detail: 'CITE Dept.',
                  onTap: () => openDissolve(
                    context,
                    const ProfileDetailScreen(mode: ProfileDetailMode.personal),
                  ),
                ),
                SettingRow(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () => openDissolve(
                    context,
                    const ProfileDetailScreen(mode: ProfileDetailMode.password),
                  ),
                ),
                const SizedBox(height: 15),
                const SectionTitle(text: 'PREFERENCES & SUPPORT'),
                SettingRow(
                  icon: Icons.notifications_none,
                  label: 'App Notifications',
                  onTap: () =>
                      openDissolve(context, const AppNotificationsScreen()),
                ),
                SettingRow(
                  icon: Icons.help_outline,
                  label: 'Help & Support Desk',
                  onTap: () => openDissolve(context, const SupportDeskScreen()),
                ),
                SettingRow(
                  icon: Icons.info_outline,
                  label: 'About ITLabCare',
                  onTap: () => openDissolve(context, const AboutUsScreen()),
                ),
                const SizedBox(height: 15),
                SettingRow(
                  icon: Icons.logout,
                  label: 'Log Out Account',
                  danger: true,
                  onTap: () => _showLogoutDialog(context),
                ),
              ],
            ),
          ),
          AppNavBar(
            selected: 4,
            onSelected: (index) => navigateFrom(context, index, 4),
          ),
        ],
      ),
    ),
  );
}

void _showLogoutDialog(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close logout dialog',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withAlpha(70)),
          ),
        ),
        Center(
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 220,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 28),
                    const SizedBox(height: 8),
                    const Text(
                      'Log Out?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You\'ll be signed out of your account and\nwill need to log in again to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 8, color: Color(0xff555555)),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(30),
                              padding: EdgeInsets.zero,
                              side: const BorderSide(color: Color(0xffdddddd)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 9, color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const AuthScreen(),
                              ),
                              (_) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(30),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            ),
            child: child,
          ),
        ),
  );
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: const Color(0xffeeeeee),
      borderRadius: BorderRadius.circular(7),
    ),
    child: const Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xff72a1bc),
          child: Icon(Icons.person, color: Colors.white),
        ),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sir Alexander',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
            Text(
              'IT 2 (CITE Department)',
              style: TextStyle(fontSize: 8, color: Color(0xff2479d0)),
            ),
            Text(
              'Teacher.juan@gmail.com',
              style: TextStyle(fontSize: 8, color: Color(0xff888888)),
            ),
          ],
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 8,
        color: Color(0xff777777),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.label,
    this.detail,
    this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(5),
    child: Container(
      height: 39,
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffeeeeee)),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: danger ? Colors.red : const Color(0xff2920d8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: danger ? Colors.red : Colors.black,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: const TextStyle(fontSize: 7, color: Color(0xff777777)),
            ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, size: 15),
        ],
      ),
    ),
  );
}
