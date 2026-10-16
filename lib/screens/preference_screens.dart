import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/brand_mark.dart';

class AppNotificationsScreen extends StatefulWidget {
  const AppNotificationsScreen({super.key});
  @override
  State<AppNotificationsScreen> createState() => _AppNotificationsScreenState();
}

class _AppNotificationsScreenState extends State<AppNotificationsScreen> {
  bool reportUpdates = true;
  bool maintenanceAlerts = true;
  bool systemAnnouncements = false;
  bool dailySummary = true;
  bool directCommunications = true;

  @override
  Widget build(BuildContext context) => PreferenceScaffold(
    title: 'App Notifications',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PreferenceGroupTitle(title: 'REPORT UPDATES'),
        NotificationToggle(
          title: 'Report Status Updates',
          subtitle: 'Get notified when your computer ticket changes status',
          value: reportUpdates,
          onChanged: (value) => setState(() => reportUpdates = value),
        ),
        NotificationToggle(
          title: 'Maintenance Alerts',
          subtitle: 'Get notified about scheduled hardware maintenance',
          value: maintenanceAlerts,
          onChanged: (value) => setState(() => maintenanceAlerts = value),
        ),
        NotificationToggle(
          title: 'Lab Closure Notices',
          subtitle: 'Get notified about temporary lab closures',
          value: systemAnnouncements,
          onChanged: (value) => setState(() => systemAnnouncements = value),
        ),
        const PreferenceGroupTitle(title: 'EMAIL NOTIFICATIONS'),
        NotificationToggle(
          title: 'Daily Summary Reports',
          subtitle: 'Receive a summary of reported issues each day',
          value: dailySummary,
          onChanged: (value) => setState(() => dailySummary = value),
        ),
        NotificationToggle(
          title: 'Direct Communications',
          subtitle: 'Receive direct messages and updates',
          value: directCommunications,
          onChanged: (value) => setState(() => directCommunications = value),
        ),
      ],
    ),
  );
}

class SupportDeskScreen extends StatelessWidget {
  const SupportDeskScreen({super.key});
  @override
  Widget build(BuildContext context) => PreferenceScaffold(
    title: 'Support Desk',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PreferenceGroupTitle(title: 'FREQUENTLY ASKED QUESTIONS'),
        const FaqRow(question: 'How to scan a QR code?'),
        const FaqRow(question: 'How to report a problem?'),
        const FaqRow(question: 'How to track my report?'),
        const SizedBox(height: 14),
        const PreferenceGroupTitle(title: 'DIRECT CHANNELS'),
        const ContactRow(
          icon: Icons.email_outlined,
          title: 'IT instructional support line',
          value: 'support@itlabcare.edu',
        ),
        const ContactRow(
          icon: Icons.phone_outlined,
          title: 'IT Help Line',
          value: '+1 (555) 020-4000',
        ),
        const SizedBox(height: 16),
        ActionButton(label: 'Submit a Ticket', onPressed: _submitTicket),
      ],
    ),
  );

  static void _submitTicket() {}
}

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  @override
  Widget build(BuildContext context) => PreferenceScaffold(
    title: 'About Us',
    child: Column(
      children: [
        const SizedBox(height: 10),
        const BrandMark(size: 120),
        const SizedBox(height: 6),
        const Text(
          'ITLABCARE',
          style: TextStyle(
            color: Color(0xff155bb2),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Text(
          'VERSION V1.0.0',
          style: TextStyle(
            color: Color(0xff3937e8),
            fontSize: 8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'ITLabCare is a computer laboratory management system designed to help students report, monitor, and resolve laboratory equipment concerns. Our goal is to keep every lab reliable, organized, and ready for learning.',
          textAlign: TextAlign.justify,
          style: TextStyle(fontSize: 9, height: 1.5, color: Color(0xff555555)),
        ),
        const SizedBox(height: 38),
        const Text(
          '© 2026 ITLabCare. All rights reserved.',
          style: TextStyle(fontSize: 8, color: Color(0xff777777)),
        ),
        const Text(
          'Designed for Computer Laboratory Management',
          style: TextStyle(fontSize: 7, color: Color(0xff999999)),
        ),
      ],
    ),
  );
}

class PreferenceScaffold extends StatelessWidget {
  const PreferenceScaffold({
    super.key,
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xff155bb2),
            padding: const EdgeInsets.fromLTRB(12, 22, 12, 22),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

class PreferenceGroupTitle extends StatelessWidget {
  const PreferenceGroupTitle({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 7),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        color: Color(0xff66758a),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class NotificationToggle extends StatelessWidget {
  const NotificationToggle({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 7),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xff66758a)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xff299d31),
          activeTrackColor: const Color(0xff299d31).withAlpha(180),
        ),
      ],
    ),
  );
}

class FaqRow extends StatelessWidget {
  const FaqRow({super.key, required this.question});
  final String question;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(
      question,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
    children: const [
      Text(
        'Open the Scan tab from the bottom navigation and follow the instructions shown on screen.',
        style: TextStyle(fontSize: 12, color: Color(0xff66758a), height: 1.4),
      ),
    ],
  );
}

class ContactRow extends StatelessWidget {
  const ContactRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });
  final IconData icon;
  final String title, value;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: const Color(0xff155bb2), size: 22),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    ),
    subtitle: Text(
      value,
      style: const TextStyle(fontSize: 11, color: Color(0xff66758a)),
    ),
  );
}
