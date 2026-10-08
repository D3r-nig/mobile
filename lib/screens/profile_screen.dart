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
                const SectionTitle(text: 'Account settings'),
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
                const SectionTitle(text: 'Preferences & support'),
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
    transitionDuration: Duration.zero,
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
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              width: 340,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xffffeeee),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout, color: Colors.red, size: 30),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Log Out?',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You\'ll be signed out of your account and\nwill need to log in again to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xff66758a),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              side: const BorderSide(color: Color(0xffdddddd)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontSize: 13, color: Color(0xff344054), fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                              noAnimationRoute((_) => const AuthScreen()),
                              (_) => false,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Log Out',
                              style: TextStyle(
                                fontSize: 13,
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
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  );
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 22),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff155bb2),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xffe8f1fb),
          child: Icon(Icons.person, color: Color(0xff155bb2), size: 32),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sir Alexander', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              SizedBox(height: 4),
              Text('Teacher account', style: TextStyle(color: Color(0xffdbeafe), fontSize: 13, fontWeight: FontWeight.w700)),
              SizedBox(height: 3),
              Text('IT 2 • CITE Department', style: TextStyle(color: Color(0xffdbeafe), fontSize: 12)),
              Text('Teacher.juan@gmail.com', style: TextStyle(color: Color(0xffdbeafe), fontSize: 12)),
            ],
          ),
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
        fontSize: 13,
        color: Color(0xff66758a),
        fontWeight: FontWeight.w800,
        letterSpacing: .2,
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
      borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 62,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffe0e7ef)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: danger ? const Color(0xffffeeee) : const Color(0xffe8f1fb),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: danger ? Colors.red : const Color(0xff155bb2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: danger ? Colors.red : Colors.black,
              ),
            ),
          ),
          if (detail != null)
            Text(
              detail!,
                style: const TextStyle(fontSize: 12, color: Color(0xff66758a)),
            ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xff9aa7b5)),
        ],
      ),
    ),
  );
}
