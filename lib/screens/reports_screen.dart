import 'package:flutter/material.dart';

import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'scan_screen.dart';
import 'report_workflow_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String selectedTab = 'All';

  static const reports = [
    ReportData(
      id: '#1021',
      lab: 'PC - 001',
      detail: 'No display on monitor',
      status: 'Pending',
      color: Color(0xffd0a700),
      date: 'Aug 7, 2028',
    ),
    ReportData(
      id: '#1067',
      lab: 'PC - 006',
      detail: 'No Internet Connection',
      status: 'In Progress',
      color: Color(0xff1b9bc2),
      date: 'Aug 13, 2028',
    ),
    ReportData(
      id: '#1251',
      lab: 'PC - 007',
      detail: 'No label, touch',
      status: 'Completed',
      color: Color(0xff46b82b),
      date: 'Aug 07, 2028',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleReports = selectedTab == 'All'
        ? reports
        : reports.where((report) => report.status == selectedTab).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'My Reports'),
            Expanded(
              child: ListView(
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
                  const SizedBox(height: 22),
                  ReportTabs(
                    selected: selectedTab,
                    onSelected: (tab) => setState(() => selectedTab = tab),
                  ),
                  if (visibleReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No reports here yet',
                          style: TextStyle(
                            color: Color(0xff52657f),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                  else
                    ...visibleReports.map((report) => ReportCard(data: report)),
                ],
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
      children: ['All', 'Pending', 'In Progress', 'Completed']
          .map(
            (tab) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
            key: ValueKey('report-tab-$tab'),
            onTap: () => onSelected(tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: tab == selected ? const Color(0xffe8f1fb) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tab == selected
                      ? const Color(0xffb9d4f0)
                      : const Color(0xffe0e7ef),
                ),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: tab == selected
                      ? const Color(0xff155bb2)
                      : const Color(0xff66758a),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
              ),
            ),
          )
          .toList(),
    ),
  );
}

class ReportOverview extends StatelessWidget {
  const ReportOverview({super.key, required this.reports});

  final List<ReportData> reports;

  @override
  Widget build(BuildContext context) {
    final pending = reports.where((report) => report.status == 'Pending').length;
    final active = reports.where((report) => report.status == 'In Progress').length;
    final completed = reports.where((report) => report.status == 'Completed').length;

    return Row(
      children: [
        _OverviewItem(label: '${reports.length} total', value: '${reports.length}', color: const Color(0xff155bb2)),
        _OverviewItem(label: 'Pending', value: '$pending', color: const Color(0xffb7791f)),
        _OverviewItem(label: 'Active', value: '$active', color: const Color(0xff1b9bc2)),
        _OverviewItem(label: 'Done', value: '$completed', color: const Color(0xff248a49)),
      ],
    );
  }
}

class _OverviewItem extends StatelessWidget {
  const _OverviewItem({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(45)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff66758a), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}

class ReportData {
  const ReportData({
    required this.id,
    required this.lab,
    required this.detail,
    required this.status,
    required this.color,
    required this.date,
  });
  final String id, lab, detail, status, date;
  final Color color;
}

class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.data});
  final ReportData data;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => openDissolve(context, const ReportTrackingScreen()),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe0e7ef)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Color(0xff155bb2), size: 22),
              const SizedBox(width: 8),
              Text(data.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(data.detail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xff17243a))),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.desktop_windows_outlined, size: 16, color: Color(0xff66758a)),
              const SizedBox(width: 5),
              Text(data.lab, style: const TextStyle(fontSize: 13, color: Color(0xff52657f))),
              const Spacer(),
              Text(data.date, style: const TextStyle(fontSize: 12, color: Color(0xff7b8796))),
            ],
          ),
        ],
      ),
    ),
  );
}
