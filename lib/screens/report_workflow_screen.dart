import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/navigation.dart';
import 'reports_screen.dart';

class ComputerDetailsScreen extends StatelessWidget {
  const ComputerDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Computer Details',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ComputerCard(),
        const SizedBox(height: 8),
        const InfoRow(
          label: 'Status',
          value: 'Working',
          valueColor: Color(0xff39a34a),
        ),
        const InfoRow(label: 'Brand', value: 'Dell OptiPlex'),
        const InfoRow(label: 'Processor', value: 'Intel Core i5'),
        const InfoRow(label: 'RAM', value: '50GB'),
        const InfoRow(label: 'Storage', value: '256 GB SSD'),
        const InfoRow(label: 'OS', value: 'Windows 11'),
        const SizedBox(height: 18),
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        WorkflowButton(
          label: 'Report a Problem',
          color: const Color(0xffffdede),
          textColor: const Color(0xffec6464),
          icon: Icons.warning_amber_outlined,
          onTap: (context) =>
              openDissolve(context, const ReportProblemScreen()),
        ),
        const SizedBox(height: 8),
        WorkflowButton(
          label: 'View Maintenance History',
          color: const Color(0xffe4eaff),
          textColor: const Color(0xff6685e9),
          icon: Icons.history,
          onTap: (context) =>
              openDissolve(context, const MaintenanceHistoryScreen()),
        ),
      ],
    ),
  );
}

class MaintenanceHistoryScreen extends StatelessWidget {
  const MaintenanceHistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Maintenance History',
    bottom: ActionButton(
      label: 'Report a Problem',
      onPressed: () => openDissolve(context, const ReportProblemScreen()),
    ),
    child: Column(
      children: [
        const ComputerCard(),
        const MaintenanceItem(
          date: 'Aug 10, 2026',
          title: 'Hardware Cleaning',
          technician: 'Technician: Lebron James',
          status: 'Completed',
        ),
        const MaintenanceItem(
          date: 'July 03, 2026',
          title: 'Replaced RAM',
          technician: 'Technician: Kyrie Irving',
          status: 'Mix Signals',
        ),
      ],
    ),
  );
}

class ReportProblemScreen extends StatelessWidget {
  const ReportProblemScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Report a Problem',
    bottom: ActionButton(
      label: 'Report a Problem',
      onPressed: () => openDissolve(context, const ReportSubmittedScreen()),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ComputerCard(),
        const SizedBox(height: 10),
        const Text(
          'Problem Category',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const ReportOptionField(
          initialValue: 'Hardware',
          options: ['Hardware', 'Software', 'Network', 'Peripheral', 'Other'],
          icon: Icons.category_outlined,
        ),
        const SizedBox(height: 10),
        const Text(
          'Describe the Problem',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Please describe the issue...',
            hintStyle: TextStyle(fontSize: 10),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Attach Photo (Optional)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        Container(
          height: 86,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xffdddddd)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 35,
                color: Color(0xff1264d6),
              ),
              Text(
                'Tap to add photo',
                style: TextStyle(fontSize: 8, color: Color(0xff777777)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Priority',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        const ReportOptionField(
          initialValue: 'Medium',
          options: ['Low', 'Medium', 'High'],
          icon: Icons.flag_outlined,
        ),
      ],
    ),
  );
}

class ReportOptionField extends StatelessWidget {
  const ReportOptionField({
    super.key,
    required this.initialValue,
    required this.options,
    required this.icon,
  });

  final String initialValue;
  final List<String> options;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: initialValue,
    items: [
      for (final option in options)
        DropdownMenuItem(
          value: option,
          child: Text(option, style: const TextStyle(fontSize: 14)),
        ),
    ],
    onChanged: (_) {},
    decoration: InputDecoration(
      labelStyle: const TextStyle(color: Color(0xff66758a), fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xff66758a), size: 20),
    ),
  );
}

class ReportSubmittedScreen extends StatelessWidget {
  const ReportSubmittedScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                size: 106,
                color: Color(0xff61ae5a),
              ),
              const SizedBox(height: 22),
              const Text(
                'Report Submitted!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your report has been successfully\nsubmitted.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 22),
              const InfoRow(label: 'Report ID', value: '#1021'),
              const InfoRow(label: 'Computer', value: 'PC - 001'),
              const InfoRow(label: 'Submitted', value: 'Aug 17, 2028'),
              const InfoRow(label: 'OS', value: 'Pending'),
              const SizedBox(height: 14),
              ActionButton(
                label: 'View My Reports',
                onPressed: () => Navigator.of(context).push(
                  noAnimationRoute((_) => const ReportsScreen()),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((route) => route.settings.name == '/dashboard'),
                child: const Text(
                  'Back to Home',
                  style: TextStyle(fontSize: 10, color: Color(0xff3937e8)),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class ReportTrackingScreen extends StatelessWidget {
  const ReportTrackingScreen({super.key});
  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Report Details',
    largeHeader: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ReportSummaryCard(),
        const SizedBox(height: 38),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'Status Timeline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 20),
        const StatusTimeline(),
      ],
    ),
  );
}

class WorkflowScaffold extends StatelessWidget {
  const WorkflowScaffold({
    super.key,
    required this.title,
    required this.child,
    this.bottom,
    this.largeHeader = false,
  });
  final String title;
  final Widget child;
  final Widget? bottom;
  final bool largeHeader;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            padding: largeHeader
                ? const EdgeInsets.fromLTRB(12, 44, 12, 34)
                : const EdgeInsets.fromLTRB(12, 22, 12, 22),
            decoration: largeHeader
                ? const BoxDecoration(
                    color: Color(0xff155bb2),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  )
                : const BoxDecoration(color: Color(0xff155bb2)),
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
              padding: EdgeInsets.fromLTRB(
                largeHeader ? 24 : 12,
                largeHeader ? 18 : 12,
                largeHeader ? 24 : 12,
                24,
              ),
              child: child,
            ),
          ),
          if (bottom != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: bottom!,
            ),
        ],
      ),
    ),
  );
}

class ComputerCard extends StatelessWidget {
  const ComputerCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.desktop_windows, size: 35),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PC - 001',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text('RW 306', style: TextStyle(fontSize: 9)),
          ],
        ),
      ],
    ),
  );
}

class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final String label, value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Container(
      height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xffeeeeee))),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 12, color: valueColor ?? const Color(0xff344054), fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class WorkflowButton extends StatelessWidget {
  const WorkflowButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Color color, textColor;
  final IconData icon;
  final void Function(BuildContext) onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onTap(context),
    child: Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: textColor.withAlpha(24),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: textColor),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: textColor),
        ],
      ),
    ),
  );
}

class MaintenanceItem extends StatelessWidget {
  const MaintenanceItem({
    super.key,
    required this.date,
    required this.title,
    required this.technician,
    required this.status,
  });
  final String date, title, technician, status;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(6),
      boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 6)],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(fontSize: 9)),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(technician, style: const TextStyle(fontSize: 8)),
              Text('Status: $status', style: const TextStyle(fontSize: 8)),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_outline,
          color: Color(0xff48ad5a),
          size: 16,
        ),
      ],
    ),
  );
}

class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('#1021', style: TextStyle(fontSize: 15)),
            Spacer(),
            _StatusBadge(),
          ],
        ),
        SizedBox(height: 10),
        Text(
          'PC - 001',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 8),
        const Text('No display on monitor', style: TextStyle(fontSize: 16)),
        SizedBox(height: 18),
        Row(
          children: [
            Text('Submitted', style: TextStyle(fontSize: 15)),
            Spacer(),
            Text('Aug 17, 2028 • 09:41 AM', style: TextStyle(fontSize: 12)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Text('Priority', style: TextStyle(fontSize: 15)),
            Spacer(),
            Text('Medium', style: TextStyle(fontSize: 12)),
          ],
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xfffff2cf),
      borderRadius: BorderRadius.circular(6),
    ),
    child: const Text(
      'Pending',
      style: TextStyle(color: Color(0xff967100), fontSize: 13),
    ),
  );
}

class StatusTimeline extends StatelessWidget {
  const StatusTimeline({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        _TimelineStep(
          title: 'Submitted',
          subtitle: 'Aug 17, 2028   09:41 AM',
          active: true,
          drawLine: true,
        ),
        _TimelineStep(
          title: 'Assigned',
          subtitle: 'Waiting for assignment',
          drawLine: true,
        ),
        _TimelineStep(
          title: 'In Progress',
          subtitle: 'Waiting for update',
          drawLine: true,
        ),
        _TimelineStep(title: 'Completed', subtitle: 'Waiting for completion'),
      ],
    ),
  );
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    this.active = false,
    this.drawLine = false,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool drawLine;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 66,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.topCenter,
            children: [
              if (drawLine)
                Positioned(
                  top: 34,
                  bottom: 0,
                  child: Container(width: 2, color: Colors.black),
                ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: active ? const Color(0xff078407) : Colors.white,
                  shape: BoxShape.circle,
                  border: active
                      ? null
                      : Border.all(color: Colors.black, width: 2),
                ),
                child: active
                    ? const Icon(Icons.check, color: Colors.white, size: 22)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 5),
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
              Text(subtitle, style: const TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    ),
  );
}

class TimelineRow extends StatelessWidget {
  const TimelineRow({super.key, required this.label, this.active = false});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? Colors.green : Colors.black,
        size: 22,
      ),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
