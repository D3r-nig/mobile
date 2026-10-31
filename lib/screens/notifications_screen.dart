import 'dart:async';

import 'package:flutter/material.dart';

import '../services/notifications_service.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'scan_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.dataSource});
  final NotificationsDataSource? dataSource;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  late final NotificationsDataSource _dataSource =
      widget.dataSource ?? FirebaseNotificationsDataSource();
  Timer? _poller;
  List<StudentNotification> _notifications = const [];
  Object? _error;
  bool _loading = true;
  String _filter = 'All';

  List<StudentNotification> get _cachedNotifications =>
      FirebaseNotificationsDataSource.cachedNotifications ?? const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifications = _cachedNotifications;
    _loading = _notifications.isEmpty;
    _loadNotifications();
    _poller = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadNotifications(forceRefresh: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    if (_dataSource case final FirebaseNotificationsDataSource source) {
      source.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotifications(forceRefresh: true);
    }
  }

  Future<void> _loadNotifications({bool forceRefresh = false}) async {
    try {
      final notifications = await _dataSource.loadNotifications(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _openNotification(StudentNotification notice) async {
    if (notice.isUnread) {
      setState(() {
        _notifications = _notifications
            .map(
              (item) =>
                  item.id == notice.id ? item.copyWith(status: 'read') : item,
            )
            .toList();
      });
      try {
        await _dataSource.markAsRead(notice.id);
      } catch (_) {
        // Keep the optimistic visual state; the next refresh will reconcile it.
      }
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      noAnimationRoute(
        (_) => NotificationDetailsScreen(
          title: notice.title,
          body: notice.message,
          time: _formatDate(notice.createdAt),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      await _dataSource.markAllAsRead();
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((notice) => notice.copyWith(status: 'read'))
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to mark notifications as read.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _notifications
        .where((notice) => _filter == 'All' || notice.isUnread)
        .toList();
    final unread = _notifications.where((notice) => notice.isUnread).length;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Notifications'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadNotifications(forceRefresh: true),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Inbox',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xff17243a),
                            ),
                          ),
                        ),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xffe8f1fb),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$unread unread',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xff155bb2),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        if (unread > 0)
                          TextButton(
                            onPressed: _markAllAsRead,
                            child: const Text('Mark all read'),
                          ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Live status updates',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xff66758a),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: ['All', 'Unread']
                          .map(
                            (value) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: value == 'All' ? 8 : 0,
                                ),
                                child: OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _filter = value),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: _filter == value
                                        ? const Color(0xffe8f1fb)
                                        : Colors.white,
                                    foregroundColor: _filter == value
                                        ? const Color(0xff155bb2)
                                        : const Color(0xff66758a),
                                  ),
                                  child: Text(value),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    if (_loading && _notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 42),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!_loading && visible.isEmpty && _error == null)
                      const Padding(
                        padding: EdgeInsets.only(top: 42),
                        child: Center(
                          child: Text(
                            'You are all caught up',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xff52657f),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (_error != null && _notifications.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 42),
                        child: Center(
                          child: Text(
                            'Unable to load notifications. Pull to retry.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ...visible.map(
                      (notice) => Notice(
                        title: notice.title,
                        body: notice.message,
                        time: _formatDate(notice.createdAt),
                        unread: notice.isUnread,
                        onOpened: () => _openNotification(notice),
                      ),
                    ),
                  ],
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

  String _formatDate(String? value) => value == null
      ? 'Just now'
      : (DateTime.tryParse(value)?.toLocal().toString().split(' ').first ??
            'Just now');
}

class Notice extends StatelessWidget {
  const Notice({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
    required this.onOpened,
  });
  final String title, body, time;
  final bool unread;
  final Future<void> Function() onOpened;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onOpened(),
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unread ? const Color(0xfff1f7ff) : Colors.white,
        border: Border.all(
          color: unread ? const Color(0xffb9d5f5) : const Color(0xffe6ebf2),
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0d155bb2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unread ? const Color(0xffdcecff) : const Color(0xfff0f3f7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              unread
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
              color: const Color(0xff155bb2),
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff17243a),
                        ),
                      ),
                    ),
                    if (unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xff155bb2),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xff52657f),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff7b8796),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
  });
  final String title, body, time;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff5f8fc),
    appBar: AppBar(
      title: const Text(
        'Notification Details',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xff155bb2),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14155bb2),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xffe4efff),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: Color(0xff155bb2),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xff17243a),
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xfff0f5fa),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 16,
                      color: Color(0xff60738c),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(0xff60738c),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Divider(height: 1, color: Color(0xffe7edf4)),
              const SizedBox(height: 20),
              Text(
                body,
                style: const TextStyle(
                  color: Color(0xff52657f),
                  fontSize: 17,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
