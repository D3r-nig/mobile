import 'dart:async';

import 'package:flutter/material.dart';

import '../services/reports_service.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'report_tracking_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, this.dataSource});

  final StudentReportsDataSource? dataSource;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late final StudentReportsDataSource _dataSource =
      widget.dataSource ?? FirebaseStudentReportsDataSource();
  List<StudentReport>? _reports;
  Object? _loadError;
  bool _isLoading = true;
  String _selectedFilter = 'All';
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    if (_dataSource is FirebaseStudentReportsDataSource) {
      _reports = FirebaseStudentReportsDataSource.cachedReports;
      _isLoading = _reports == null;
    }
    _loadReports();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadReports(silent: true);
    });
  }

  @override
  void dispose() {
    if (widget.dataSource == null &&
        _dataSource is FirebaseStudentReportsDataSource) {
      _dataSource.dispose();
    }
    _syncTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadReports({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loadError = null;
        _isLoading = _reports == null;
      });
    }
    try {
      final reports = await _dataSource.loadReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _isLoading = _reports == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reports = _reports ?? const <StudentReport>[];
    final filtered = reports.where(_matchesSelectedFilter).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _ReportsHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadReports,
                child: ListView(
                  key: const Key('reports-list'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    const Text(
                      'Reports overview',
                      style: TextStyle(
                        color: Color(0xff17243a),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ReportOverview(reports: reports),
                    const SizedBox(height: 18),
                    ReportTabs(
                      selected: _selectedFilter,
                      onSelected: (filter) =>
                          setState(() => _selectedFilter = filter),
                    ),
                    const SizedBox(height: 14),
                    if (_loadError != null)
                      _ReportsError(
                        message: reportsErrorMessage(_loadError!),
                        onRetry: _loadReports,
                      )
                    else if (_isLoading)
                      const _ReportsLoading()
                    else if (reports.isEmpty)
                      const _ReportsEmptyState()
                    else if (filtered.isEmpty)
                      const _ReportsEmptyFilterState()
                    else
                      ...filtered.map(
                        (report) => ReportCard(
                          key: ValueKey('report-card-${report.id}'),
                          report: report,
                          dataSource: _dataSource,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            AppNavBar(
              selected: 1,
              onSelected: (index) => navigateFrom(context, index, 1),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesSelectedFilter(StudentReport report) =>
      switch (_selectedFilter) {
        'Pending' => report.status == 'pending' || report.status == 'pending_teacher_review',
        'In Progress' =>
          report.status == 'assigned' || report.status == 'in_progress',
        'Completed' => report.status == 'completed',
        'Cancelled' => report.status == 'cancelled',
        _ => true,
      };
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: const Color(0xff155bb2),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
    child: const Text(
      'My Reports',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class ReportTabs extends StatelessWidget {
  const ReportTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final filter in const [
          'All',
          'Pending',
          'In Progress',
          'Completed',
          'Cancelled',
        ])
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: ValueKey('report-tab-$filter'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => onSelected(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: filter == selected
                      ? const Color(0xffe8f1fb)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: filter == selected
                        ? const Color(0xffb9d4f0)
                        : const Color(0xffe0e7ef),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: filter == selected
                        ? const Color(0xff155bb2)
                        : const Color(0xff66758a),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class ReportOverview extends StatelessWidget {
  const ReportOverview({super.key, required this.reports});

  final List<StudentReport> reports;

  @override
  Widget build(BuildContext context) {
    final pending = reports
        .where((report) => report.status == 'pending' || report.status == 'pending_teacher_review')
        .length;
    final active = reports
        .where(
          (report) =>
              report.status == 'assigned' || report.status == 'in_progress',
        )
        .length;
    final completed = reports
        .where((report) => report.status == 'completed')
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 8.0;
        final itemWidth = (constraints.maxWidth - spacing * 3) / 4;
        return Row(
          children: [
            _OverviewItem(
              label: 'Total',
              value: reports.length,
              color: const Color(0xff155bb2),
              width: itemWidth,
            ),
            SizedBox(width: spacing),
            _OverviewItem(
              label: 'Pending',
              value: pending,
              color: const Color(0xffb7791f),
              width: itemWidth,
            ),
            SizedBox(width: spacing),
            _OverviewItem(
              label: 'Active',
              value: active,
              color: const Color(0xff1b9bc2),
              width: itemWidth,
            ),
            SizedBox(width: spacing),
            _OverviewItem(
              label: 'Completed',
              value: completed,
              color: const Color(0xff248a49),
              width: itemWidth,
            ),
          ],
        );
      },
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({
    required this.label,
    required this.value,
    required this.color,
    required this.width,
  });

  final String label;
  final int value;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            key: ValueKey('report-summary-${label.toLowerCase()}'),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xff66758a),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, required this.dataSource});

  final StudentReport report;
  final StudentReportsDataSource dataSource;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(report.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffe0e7ef)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: report.id == null
            ? null
            : () => openDissolve(
                context,
                ReportTrackingScreen(report: report, dataSource: dataSource),
              ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xff155bb2),
                    size: 21,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.displayReportNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(label: report.statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xff17243a),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 5,
                children: [
                  _CardMetadata(
                    icon: Icons.desktop_windows_outlined,
                    value: report.computer,
                  ),
                  if (report.lab != null)
                    _CardMetadata(
                      icon: Icons.location_on_outlined,
                      value: report.lab!,
                    ),
                  if (report.priority != null)
                    _CardMetadata(
                      icon: Icons.flag_outlined,
                      value: report.priority!,
                    ),
                  _CardMetadata(
                    icon: Icons.calendar_today_outlined,
                    value: report.submittedDate,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMetadata extends StatelessWidget {
  const _CardMetadata({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width - 64,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xff66758a)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xff52657f)),
          ),
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withAlpha(28),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
    ),
  );
}

Color _statusColor(String status) => switch (status) {
  'pending' || 'pending_teacher_review' => const Color(0xff967100),
  'assigned' => const Color(0xff2878a8),
  'in_progress' => const Color(0xff1b9bc2),
  'completed' => const Color(0xff248a49),
  'cancelled' => const Color(0xffb42318),
  _ => const Color(0xff66758a),
};

class _ReportsLoading extends StatelessWidget {
  const _ReportsLoading();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 54),
    child: Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            key: Key('reports-loading'),
            strokeWidth: 3,
          ),
          SizedBox(height: 12),
          Text(
            'Loading your reports…',
            style: TextStyle(color: Color(0xff66758a), fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('reports-error'),
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xfffff5f5),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xfff1caca)),
    ),
    child: Column(
      children: [
        const Icon(Icons.error_outline, color: Color(0xffb42318), size: 28),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xff8f1d16),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}

class _ReportsEmptyState extends StatelessWidget {
  const _ReportsEmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Column(
      children: [
        const Icon(
          Icons.assignment_outlined,
          color: Color(0xff7b8796),
          size: 42,
        ),
        const SizedBox(height: 10),
        const Text(
          'No reports yet.',
          key: Key('reports-empty'),
          style: TextStyle(
            color: Color(0xff52657f),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Your submitted computer reports will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xff66758a), fontSize: 12),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => navigateFrom(context, 0, 1),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Return to Home'),
        ),
      ],
    ),
  );
}

class _ReportsEmptyFilterState extends StatelessWidget {
  const _ReportsEmptyFilterState();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 38),
    child: Center(
      child: Text(
        'No reports in this category.',
        style: TextStyle(
          color: Color(0xff52657f),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
