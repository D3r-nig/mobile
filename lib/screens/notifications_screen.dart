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

class _NotificationsScreenState extends State<NotificationsScreen> with WidgetsBindingObserver {
  late final NotificationsDataSource _dataSource = widget.dataSource ?? FirebaseNotificationsDataSource();
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
    _poller = Timer.periodic(const Duration(seconds: 10), (_) => _loadNotifications());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    if (_dataSource is FirebaseNotificationsDataSource) (_dataSource as FirebaseNotificationsDataSource).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _dataSource.loadNotifications();
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

  @override
  Widget build(BuildContext context) {
    final visible = _notifications.where((notice) => _filter == 'All' || notice.isUnread).toList();
    final unread = _notifications.where((notice) => notice.isUnread).length;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          const ScreenHeader(title: 'Notifications'),
          Expanded(child: RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 24), children: [
              Row(children: [
                const Expanded(child: Text('Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xff17243a)))),
                Text('$unread unread', style: const TextStyle(fontSize: 13, color: Color(0xff155bb2), fontWeight: FontWeight.w700)),
              ]),
              const Padding(padding: EdgeInsets.only(top: 4), child: Text('Live status updates', style: TextStyle(fontSize: 13, color: Color(0xff66758a), fontWeight: FontWeight.w700))),
              const SizedBox(height: 14),
              Row(children: ['All', 'Unread'].map((value) => Expanded(child: Padding(
                padding: EdgeInsets.only(right: value == 'All' ? 8 : 0),
                child: OutlinedButton(
                  onPressed: () => setState(() => _filter = value),
                  style: OutlinedButton.styleFrom(backgroundColor: _filter == value ? const Color(0xffe8f1fb) : Colors.white, foregroundColor: _filter == value ? const Color(0xff155bb2) : const Color(0xff66758a)),
                  child: Text(value),
                ),
              ))).toList()),
              if (_loading && _notifications.isEmpty) const Padding(padding: EdgeInsets.only(top: 42), child: Center(child: CircularProgressIndicator())),
              if (!_loading && visible.isEmpty && _error == null) const Padding(padding: EdgeInsets.only(top: 42), child: Center(child: Text('You are all caught up', style: TextStyle(fontSize: 14, color: Color(0xff52657f), fontWeight: FontWeight.w700)))),
              if (_error != null && _notifications.isEmpty) const Padding(padding: EdgeInsets.only(top: 42), child: Center(child: Text('Unable to load notifications. Pull to retry.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)))),
              ...visible.map((notice) => Notice(
                title: notice.title,
                body: notice.message,
                time: _formatDate(notice.createdAt),
                unread: notice.isUnread,
                onOpened: () => Navigator.of(context).push(noAnimationRoute((_) => NotificationDetailsScreen(title: notice.title, body: notice.message, time: _formatDate(notice.createdAt)))),
              )),
            ]),
          )),
          AppNavBar(selected: 3, onSelected: (index) => navigateFrom(context, index, 3)),
        ]),
      ),
    );
  }

  String _formatDate(String? value) => value == null ? 'Just now' : (DateTime.tryParse(value)?.toLocal().toString().split(' ').first ?? 'Just now');
}

class Notice extends StatelessWidget {
  const Notice({super.key, required this.title, required this.body, required this.time, required this.unread, required this.onOpened});
  final String title, body, time;
  final bool unread;
  final VoidCallback onOpened;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onOpened,
    child: Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: unread ? const Color(0xfff2f8ff) : Colors.white, border: Border.all(color: const Color(0xffeeeeee)), borderRadius: BorderRadius.circular(14)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(unread ? Icons.notifications_active_outlined : Icons.notifications_none, color: const Color(0xff155bb2), size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800))), Text(time, style: const TextStyle(fontSize: 10, color: Color(0xff7b8796)))]),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(fontSize: 13, color: Color(0xff52657f), height: 1.35)),
        ])),
      ]),
    ),
  );
}

class NotificationDetailsScreen extends StatelessWidget {
  const NotificationDetailsScreen({super.key, required this.title, required this.body, required this.time});
  final String title, body, time;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notification Details')),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Text(time, style: const TextStyle(color: Colors.grey)),
      const SizedBox(height: 20),
      Text(body, style: const TextStyle(fontSize: 16, height: 1.4)),
    ])),
  );
}
