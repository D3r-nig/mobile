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
                padding: const EdgeInsets.all(12),
                children: [
                  ReportTabs(
                    selected: selectedTab,
                    onSelected: (tab) => setState(() => selectedTab = tab),
                  ),
                  if (visibleReports.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No reports in this category',
                          style: TextStyle(
                            color: Color(0xff777777),
                            fontSize: 11,
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
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: ['All', 'Pending', 'In Progress', 'Completed']
        .map(
          (tab) => InkWell(
            key: ValueKey('report-tab-$tab'),
            onTap: () => onSelected(tab),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                tab,
                style: TextStyle(
                  color: tab == selected
                      ? const Color(0xff3937e8)
                      : Colors.black,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        )
        .toList(),
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
        borderRadius: BorderRadius.circular(7),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                data.id,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                color: data.color.withAlpha(45),
                child: Text(
                  data.status,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            data.lab,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(data.detail, style: const TextStyle(fontSize: 9)),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              data.date,
              style: const TextStyle(fontSize: 8, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    ),
  );
}
