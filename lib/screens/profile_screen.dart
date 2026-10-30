import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/profile_service.dart';
import '../services/notifications_service.dart';
import '../services/memory_cache.dart';
import '../services/dashboard_service.dart';
import '../services/reports_service.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'auth_screen.dart';
import 'preference_screens.dart';
import 'profile_detail_screen.dart';
import 'scan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.repository, this.signOut});

  final StudentProfileRepository? repository;
  final Future<void> Function()? signOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final StudentProfileRepository _repository =
      widget.repository ?? StudentProfileRepository.session;
  StudentProfile? _profile;
  Object? _loadError;
  bool _isLoading = true;
  bool _isSigningOut = false;
  String? _observedUserId;

  @override
  void initState() {
    super.initState();
    _observedUserId = _repository.currentUserId;
    _profile = _repository.cachedProfile;
    _isLoading = _profile == null;
    _repository.addListener(_handleRepositoryChange);
    _loadProfile();
  }

  Future<void> _loadProfile({bool forceRefresh = false}) async {
    final cachedProfile = _repository.cachedProfile;
    setState(() {
      _isLoading = cachedProfile == null;
      _profile = cachedProfile;
      _loadError = null;
    });
    try {
      final profile = await _repository.loadProfile(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final currentProfile = _repository.cachedProfile;
      setState(() {
        _profile = currentProfile;
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  void _handleRepositoryChange() {
    if (!mounted) return;
    final currentUserId = _repository.currentUserId;
    final accountChanged = currentUserId != _observedUserId;
    _observedUserId = currentUserId;
    final profile = _repository.cachedProfile;
    if (identical(profile, _profile)) return;
    setState(() {
      _profile = profile;
      _loadError = null;
      _isLoading = profile == null;
    });
    if (profile == null && accountChanged && currentUserId != null) {
      _loadProfile();
    }
  }

  Future<void> _logout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);
    try {
      await (widget.signOut ?? FirebaseAuth.instance.signOut)();
      _repository.clear();
      FirebaseDashboardDataSource.clearCache();
      FirebaseStudentReportsDataSource.clearCache();
      FirebaseNotificationsDataSource.clearCache();
      MemoryCache.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        noAnimationRoute((_) => const AuthScreen()),
        (_) => false,
      );
    } on FirebaseAuthException {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSigningOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not sign out. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _repository.removeListener(_handleRepositoryChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff6f8fb),
    body: SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Profile'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProfile(forceRefresh: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                children: [
                  _buildProfileContent(),
                  const SectionTitle(text: 'Account settings'),
                  SettingRow(
                    icon: Icons.person_outline,
                    label: 'Personal Information',
                    onTap: _profile == null
                        ? null
                        : () => openDissolve(
                            context,
                            ProfileDetailScreen(
                              mode: ProfileDetailMode.personal,
                              profile: _profile,
                            ),
                          ),
                  ),
                  SettingRow(
                    icon: Icons.lock_outline,
                    label: 'Change Password',
                    onTap: () => openDissolve(
                      context,
                      const ProfileDetailScreen(
                        mode: ProfileDetailMode.password,
                      ),
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
                    onTap: () =>
                        openDissolve(context, const SupportDeskScreen()),
                  ),
                  SettingRow(
                    icon: Icons.info_outline,
                    label: 'About ITLabCare',
                    onTap: () => openDissolve(context, const AboutUsScreen()),
                  ),
                  const SizedBox(height: 15),
                  SettingRow(
                    icon: Icons.logout,
                    label: _isSigningOut ? 'Signing Out…' : 'Log Out',
                    danger: true,
                    onTap: _isSigningOut
                        ? null
                        : () => _showLogoutDialog(context, _logout),
                  ),
                ],
              ),
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

  Widget _buildProfileContent() {
    if (_profile == null && _isLoading) {
      return const SizedBox(
        key: Key('profile-loading'),
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_profile == null && _loadError != null) {
      return _ProfileError(
        message: profileLoadErrorMessage(_loadError!),
        onRetry: () => _loadProfile(forceRefresh: true),
      );
    }

    final profile = _profile;
    if (profile == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_loadError != null)
          _ProfileRefreshError(
            message: profileLoadErrorMessage(_loadError!),
            onRetry: () => _loadProfile(forceRefresh: true),
          ),
        ProfileCard(profile: profile),
        if (profile.isIncomplete)
          Container(
            key: const Key('profile-empty-state'),
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfffff8e7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Your profile information is incomplete. Please contact your school administrator.',
              style: TextStyle(color: Color(0xff755b17), fontSize: 13),
            ),
          ),
        const SectionTitle(text: 'Student information'),
        _ProfileInfoCard(profile: profile),
      ],
    );
  }
}

void _showLogoutDialog(BuildContext context, VoidCallback onConfirm) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close logout dialog',
    barrierColor: Colors.transparent,
    transitionDuration: Duration.zero,
    pageBuilder: (dialogContext, animation, secondaryAnimation) => Stack(
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
                      decoration: const BoxDecoration(
                        color: Color(0xffffeeee),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: 30,
                      ),
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
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onConfirm();
                            },
                            child: const Text('Log Out'),
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
  const ProfileCard({super.key, required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xff155bb2),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 30,
          backgroundColor: Color(0xffe8f1fb),
          child: Icon(Icons.person, color: Color(0xff155bb2), size: 32),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.fullName ?? 'Name unavailable',
                key: const Key('profile-full-name'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Student account',
                style: TextStyle(
                  color: Color(0xffdbeafe),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                profile.email ?? 'Not provided',
                style: const TextStyle(color: Color(0xffdbeafe), fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffe0e7ef)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        _ProfileInfoRow(label: 'Student number', value: profile.studentNumber),
        _ProfileInfoRow(label: 'Section', value: profile.section),
        _ProfileInfoRow(label: 'Adviser', value: profile.adviser),
        _ProfileInfoRow(
          label: 'Account status',
          value: profile.accountStatus == null
              ? null
              : _titleCase(profile.accountStatus!),
          last: true,
        ),
      ],
    ),
  );
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 48),
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      border: last
          ? null
          : const Border(bottom: BorderSide(color: Color(0xffedf0f4))),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Color(0xff66758a), fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value ?? 'Not provided',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xff17243a),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

String _titleCase(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('profile-error'),
    margin: const EdgeInsets.only(bottom: 18),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xfffff5f5),
      border: Border.all(color: const Color(0xfff1caca)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xffb42318)),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ProfileRefreshError extends StatelessWidget {
  const _ProfileRefreshError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('profile-refresh-error'),
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xfffff5f5),
      border: Border.all(color: const Color(0xfff1caca)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xffb42318), size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 12))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
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
            Flexible(
              child: Text(
                detail!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xff66758a)),
              ),
            ),
          const SizedBox(width: 5),
          const Icon(Icons.chevron_right, size: 20, color: Color(0xff9aa7b5)),
        ],
      ),
    ),
  );
}
