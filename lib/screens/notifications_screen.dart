import 'package:flutter/material.dart';

import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'scan_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String filter = 'All';
  final unread = <String>{
    'Report #1021 Updated',
    'Maintenance Completed',
    'Lab 3 Temporary Closure',
  };

  static const notices = [
    _NoticeData(Icons.info_outline, 'Report #1021 Updated', 'Your report #1021 was updated. No display on monitor - PC - 001 has been changed to In Progress.', 'Just now', 'Today', Color(0xff4c9df2)),
    _NoticeData(Icons.check_circle_outline, 'Maintenance Completed', 'Hardware diagnostics and updates successfully completed on PC - 001 in Lab 306.', '2 hours ago', 'Today', Color(0xff248a49)),
    _NoticeData(Icons.warning_amber_rounded, 'Lab 3 Temporary Closure', 'Computer Lab 3 will be closed for scheduled hardware maintenance on Aug 20.', '1 day ago', 'Yesterday', Color(0xffb7791f)),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = notices.where((notice) => filter == 'All' || unread.contains(notice.title)).toList();
    final groups = visible.map((notice) => notice.group).toSet();

    return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const ScreenHeader(title: 'Notifications'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff17243a)))),
                    Text('${unread.length} unread', style: const TextStyle(fontSize: 13, color: Color(0xff155bb2), fontWeight: FontWeight.w700)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Status Timeline', style: TextStyle(fontSize: 13, color: Color(0xff66758a), fontWeight: FontWeight.w700)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: ['All', 'Unread'].map((value) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: value == 'All' ? 8 : 0),
                      child: OutlinedButton(
                        onPressed: () => setState(() => filter = value),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: filter == value ? const Color(0xffe8f1fb) : Colors.white,
                          foregroundColor: filter == value ? const Color(0xff155bb2) : const Color(0xff66758a),
                          side: BorderSide(color: filter == value ? const Color(0xffb9d4f0) : const Color(0xffe0e7ef)),
                        ),
                        child: Text(value),
                      ),
                    ),
                  )).toList(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: unread.isEmpty ? null : () => setState(unread.clear),
                    child: const Text('Mark all as read'),
                  ),
                ),
                if (visible.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 42),
                    child: Center(child: Text('You are all caught up', style: TextStyle(fontSize: 14, color: Color(0xff52657f), fontWeight: FontWeight.w700))),
                  )
                else
                  for (final group in groups) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Text(group, style: const TextStyle(fontSize: 13, color: Color(0xff66758a), fontWeight: FontWeight.w800)),
                    ),
                    ...visible.where((notice) => notice.group == group).map((notice) => Notice(
                      icon: notice.icon,
                      title: notice.title,
                      body: notice.body,
                      time: notice.time,
                      color: notice.color,
                      unread: unread.contains(notice.title),
                      onOpened: () => setState(() => unread.remove(notice.title)),
                    )),
                  ],
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
}

class _NoticeData {
  const _NoticeData(this.icon, this.title, this.body, this.time, this.group, this.color);
  final IconData icon;
  final String title, body, time, group;
  final Color color;
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    required this.unread,
    required this.onOpened,
  });
  final IconData icon;
  final String title, body, time;
  final Color color;
  final bool unread;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      onOpened();
      Navigator.of(context).push(
        noAnimationRoute(
          (_) => NotificationDetailsScreen(
            title: title,
            body: body,
            time: time,
            icon: icon,
            color: color,
          ),
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: unread ? const Color(0xfff2f8ff) : Colors.white,
        border: Border.all(color: const Color(0xffeeeeee)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(28),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))),
                    if (unread) const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: Color(0xff155bb2), shape: BoxShape.circle),
                        child: SizedBox(width: 8, height: 8),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff7b8796),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(body, style: const TextStyle(fontSize: 13, color: Color(0xff52657f), height: 1.35)),
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
            color: const Color(0xff155bb2),
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
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
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
