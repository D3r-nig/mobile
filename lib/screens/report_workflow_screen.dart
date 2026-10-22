import 'package:flutter/material.dart';

import '../widgets/auth_widgets.dart';
import '../widgets/navigation.dart';
import '../services/maintenance_history_service.dart';
import '../services/report_submission_service.dart';
import 'reports_screen.dart';

class ComputerDetailsScreen extends StatelessWidget {
  const ComputerDetailsScreen({
    super.key,
    this.computerId = 1,
    this.assetTag = 'PC-001',
    this.lab = 'RW 306',
    this.status = 'Working',
    this.brand = 'Dell OptiPlex',
    this.processor = 'Intel Core i5',
    this.ram = '50GB',
    this.storage = '256 GB SSD',
    this.operatingSystem = 'Windows 11',
  });

  final int computerId;
  final String assetTag, lab, status, brand, processor, ram, storage, operatingSystem;
  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Computer Details',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComputerCard(assetTag: assetTag, lab: lab),
        const SizedBox(height: 8),
        InfoRow(
          label: 'Status',
          value: status,
          valueColor: Color(0xff39a34a),
        ),
        InfoRow(label: 'Brand', value: brand),
        InfoRow(label: 'Processor', value: processor),
        InfoRow(label: 'RAM', value: ram),
        InfoRow(label: 'Storage', value: storage),
        InfoRow(label: 'OS', value: operatingSystem),
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
              openDissolve(context, ReportProblemScreen(
                computerId: computerId,
                assetTag: assetTag,
                lab: lab,
              )),
        ),
        const SizedBox(height: 8),
        WorkflowButton(
          label: 'View Maintenance History',
          color: const Color(0xffe4eaff),
          textColor: const Color(0xff6685e9),
          icon: Icons.history,
          onTap: (context) =>
              openDissolve(context, MaintenanceHistoryScreen(
                computerId: computerId,
                assetTag: assetTag,
                lab: lab,
              )),
        ),
      ],
    ),
  );
}

class MaintenanceHistoryScreen extends StatefulWidget {
  const MaintenanceHistoryScreen({
    super.key,
    this.computerId = 1,
    this.assetTag = 'PC-001',
    this.lab = 'RW 306',
  });

  final int computerId;
  final String assetTag, lab;

  @override
  State<MaintenanceHistoryScreen> createState() => _MaintenanceHistoryScreenState();
}

class _MaintenanceHistoryScreenState extends State<MaintenanceHistoryScreen> {
  late final MaintenanceHistoryService _service = MaintenanceHistoryService();
  late Future<List<MaintenanceRecordEntry>> _records;

  @override
  void initState() {
    super.initState();
    _records = _service.load(widget.computerId);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Maintenance History',
    bottom: ActionButton(
      label: 'Report a Problem',
      onPressed: () => openDissolve(
        context,
        ReportProblemScreen(
          computerId: widget.computerId,
          assetTag: widget.assetTag,
          lab: widget.lab,
        ),
      ),
    ),
    child: Column(
      children: [
        ComputerCard(assetTag: widget.assetTag, lab: widget.lab),
        FutureBuilder<List<MaintenanceRecordEntry>>(
          future: _records,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unable to load maintenance history. Pull back and try again.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            final records = snapshot.data ?? const [];
            if (records.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No maintenance history for this computer.'),
              );
            }
            return Column(
              children: records
                  .map((record) => MaintenanceItem(
                        date: record.scheduledDate,
                        title: record.title,
                        technician: 'Technician: ${record.technician ?? 'Unassigned'}',
                        status: record.status,
                      ))
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({
    super.key,
    this.computerId = 1,
    this.assetTag = 'PC-001',
    this.lab = 'RW 306',
    this.dataSource,
  });

  final int computerId;
  final String assetTag, lab;
  final StudentReportSubmissionDataSource? dataSource;

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  late final StudentReportSubmissionDataSource _dataSource =
      widget.dataSource ?? FirebaseStudentReportSubmissionDataSource();
  final _descriptionController = TextEditingController();
  String _category = 'hardware';
  String _priority = 'medium';
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _descriptionController.dispose();
    if (widget.dataSource == null && _dataSource is FirebaseStudentReportSubmissionDataSource) {
      (_dataSource as FirebaseStudentReportSubmissionDataSource).dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      setState(() => _error = 'Please describe the problem.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await _dataSource.submitReport(
        computerId: widget.computerId,
        category: _category,
        description: description,
        priority: _priority,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(noAnimationRoute((_) => const ReportSubmittedScreen()));
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => WorkflowScaffold(
    title: 'Report a Problem',
    bottom: ActionButton(
      label: 'Report a Problem',
      onPressed: _submitting ? null : () { _submit(); },
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ComputerCard(assetTag: widget.assetTag, lab: widget.lab),
        const SizedBox(height: 10),
        const Text(
          'Problem Category',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        ReportOptionField(
          initialValue: _category,
          options: ['Hardware', 'Software', 'Network', 'Peripheral', 'Other'],
          icon: Icons.category_outlined,
          onChanged: (value) => setState(() => _category = value.toLowerCase()),
        ),
        const SizedBox(height: 10),
        const Text(
          'Describe the Problem',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: _descriptionController,
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
        ReportOptionField(
          initialValue: _priority,
          options: ['Low', 'Medium', 'High'],
          icon: Icons.flag_outlined,
          onChanged: (value) => setState(() => _priority = value.toLowerCase()),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
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
    required this.onChanged,
  });

  final String initialValue;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: initialValue.toLowerCase(),
    items: [
      for (final option in options)
        DropdownMenuItem(
          value: option.toLowerCase(),
          child: Text(option, style: const TextStyle(fontSize: 14)),
        ),
    ],
    onChanged: (value) { if (value != null) onChanged(value); },
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
                'Report Sent for Review',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              const Text(
                'Your report was sent to your teacher\nfor validation before processing.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
              const SizedBox(height: 14),
              ActionButton(
                label: 'View My Reports',
                onPressed: () =>
                    Navigator.of(context)
                        .push(noAnimationRoute((_) => const ReportsScreen())),
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
  const ComputerCard({
    super.key,
    this.assetTag = 'PC-001',
    this.lab = 'RW 306',
  });

  final String assetTag, lab;
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
    child: Row(
      children: [
        Icon(Icons.desktop_windows, size: 35),
        SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assetTag,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            Text(lab, style: TextStyle(fontSize: 9)),
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
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? const Color(0xff344054),
            fontWeight: FontWeight.w600,
          ),
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
