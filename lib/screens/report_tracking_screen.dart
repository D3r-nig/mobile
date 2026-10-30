import 'package:flutter/material.dart';

import '../services/reports_service.dart';
import 'report_workflow_screen.dart';

class ReportTrackingScreen extends StatefulWidget {
  const ReportTrackingScreen({
    super.key,
    required this.report,
    required this.dataSource,
  });

  final StudentReport report;
  final StudentReportsDataSource dataSource;

  @override
  State<ReportTrackingScreen> createState() => _ReportTrackingScreenState();
}

class _ReportTrackingScreenState extends State<ReportTrackingScreen> {
  late StudentReport _report = widget.report;
  Object? _loadError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      final id = widget.report.id;
      if (id == null || id.isEmpty) {
        throw const FormatException('The report identifier is missing.');
      }
      final report = await widget.dataSource.loadReport(id);
      if (!mounted) return;
      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Report Details',
    largeHeader: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isLoading)
          const _DetailLoading()
        else if (_loadError != null)
          _DetailError(
            message: reportsErrorMessage(_loadError!, isDetail: true),
            onRetry: _loadDetails,
          )
        else ...[
          _ReportDetailsCard(report: _report),
          const SizedBox(height: 26),
          const Text(
            'Status Timeline',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _ReportStatusTimeline(report: _report),
        ],
      ],
    ),
  );
}

class _ReportDetailsCard extends StatelessWidget {
  const _ReportDetailsCard({required this.report});

  final StudentReport report;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('report-detail-card'),
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe0e7ef)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                report.displayReportNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xff17243a),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _DetailStatusBadge(report: report),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          report.description,
          style: const TextStyle(
            color: Color(0xff17243a),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _DetailInfoRow(label: 'Computer', value: report.computer),
        _DetailInfoRow(label: 'Laboratory', value: report.lab ?? 'Unknown lab'),
        _DetailInfoRow(label: 'Category', value: report.category ?? 'Unknown'),
        _DetailInfoRow(label: 'Priority', value: report.priority ?? 'Unknown'),
        _DetailInfoRow(label: 'Submitted', value: report.submittedDate),
        _DetailInfoRow(label: 'Assigned technician', value: report.technician),
        if (report.resolvedAt != null)
          _DetailInfoRow(label: 'Resolved', value: report.completedDate),
      ],
    ),
  );
}

class _DetailStatusBadge extends StatelessWidget {
  const _DetailStatusBadge({required this.report});

  final StudentReport report;

  @override
  Widget build(BuildContext context) {
    final color = switch (report.status) {
      'pending' => const Color(0xff967100),
      'assigned' => const Color(0xff2878a8),
      'in_progress' => const Color(0xff1b9bc2),
      'completed' => const Color(0xff248a49),
      'cancelled' => const Color(0xffb42318),
      _ => const Color(0xff66758a),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        report.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 42),
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: Color(0xffedf0f4))),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 132,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff66758a),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff344054),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReportStatusTimeline extends StatelessWidget {
  const _ReportStatusTimeline({required this.report});

  final StudentReport report;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (title: 'Submitted', active: true, subtitle: report.submittedDate),
      (
        title: 'Assigned',
        active: report.assignmentComplete,
        subtitle: report.assignmentComplete
            ? report.technician
            : 'Waiting for assignment',
      ),
      (
        title: 'In Progress',
        active: report.inProgressComplete,
        subtitle: report.inProgressComplete
            ? 'Repair in progress or finished'
            : 'Waiting for update',
      ),
      (
        title: 'Completed',
        active: report.completionComplete,
        subtitle: report.completionComplete
            ? report.completedDate
            : 'Waiting for completion',
      ),
    ];

    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _TimelineStep(
            title: steps[index].title,
            subtitle: steps[index].subtitle,
            active: steps[index].active,
            drawLine: index != steps.length - 1,
          ),
        if (report.isCancelled)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'This report was cancelled.',
              style: TextStyle(
                color: Color(0xffb42318),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.drawLine,
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
          width: 38,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              if (drawLine)
                Positioned(
                  top: 32,
                  bottom: 0,
                  child: Container(width: 2, color: const Color(0xffcad3df)),
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: active ? const Color(0xff248a49) : Colors.white,
                  shape: BoxShape.circle,
                  border: active
                      ? null
                      : Border.all(color: const Color(0xffaab5c3), width: 2),
                ),
                child: active
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
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
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff66758a),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DetailLoading extends StatelessWidget {
  const _DetailLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 56),
    child: Center(
      child: Column(
        children: [
          CircularProgressIndicator(key: Key('report-detail-loading')),
          SizedBox(height: 12),
          Text('Loading report details…'),
        ],
      ),
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xffb42318), size: 32),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
