import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/qr_computer_service.dart';
import '../widgets/app_nav_bar.dart';
import '../widgets/navigation.dart';
import 'report_workflow_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Scan QR Code'),
            Expanded(
              child: Container(
                color: const Color(0xff1d2a3a),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final frameSize = constraints.maxWidth < 260
                                  ? constraints.maxWidth
                                  : 260.0;
                              return SizedBox(
                                width: frameSize,
                                height: frameSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    DecoratedBox(
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      child: InkWell(
                                        onTap: () => openDissolve(
                                          context,
                                          const QrScannerScreen(),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(24),
                                          child: Icon(
                                            Icons.qr_code_2,
                                            size: 150,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            top: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            top: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            bottom: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            bottom: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Position the QR code inside\nthe frame to scan',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppNavBar(
              selected: 2,
              onSelected: (index) => navigateFrom(context, index, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _computerService = QrComputerService();
  bool _resolving = false;

  Future<void> _handleCode(BarcodeCapture capture) async {
    if (_resolving) return;
    final token = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .map((value) => value.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (token.isEmpty) return;

    setState(() => _resolving = true);
    await _controller.stop();
    try {
      final computer = await _computerService.resolve(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        noAnimationRoute((_) => ComputerDetailsScreen(computerId: computer.id)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _resolving = false);
      await _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _computerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xff1d2a3a),
    appBar: AppBar(
      title: const Text('Scan QR Code'),
      backgroundColor: const Color(0xff155bb2),
      foregroundColor: Colors.white,
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(controller: _controller, onDetect: _handleCode),
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff1d6ef2), width: 4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        if (_resolving)
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        const Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Text(
            'Place the computer QR code inside the frame',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        noAnimationRoute((_) => const ComputerDetailsScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const ScreenHeader(title: 'Scan result'),
            Expanded(
              child: Container(
                color: const Color(0xff1d2a3a),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final frameSize = constraints.maxWidth < 260
                                  ? constraints.maxWidth
                                  : 260.0;
                              return SizedBox(
                                width: frameSize,
                                height: frameSize,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 198,
                                      height: 198,
                                      child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(24),
                                            child: Icon(
                                              Icons.qr_code_2,
                                              size: 150,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            top: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            top: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            left: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            bottom: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            right: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                            bottom: BorderSide(
                                              color: Color(0xff1d6ef2),
                                              width: 5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            bottomRight: Radius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'SCAN COMPLETE',
                            style: TextStyle(
                              color: Color(0xff4fcf68),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AppNavBar(
              selected: 2,
              onSelected: (index) => navigateFrom(context, index, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class ComputerListScreen extends StatelessWidget {
  const ComputerListScreen({super.key});

  static const computers = [
    _ComputerEntry(
      id: 'PC - 001',
      room: 'RW 306',
      status: 'Working',
      color: Color(0xff3dc870),
    ),
    _ComputerEntry(
      id: 'PC - 002',
      room: 'RW 306',
      status: 'Under Maintenance',
      color: Color(0xffd1494d),
    ),
    _ComputerEntry(
      id: 'PC - 003',
      room: 'RW 306',
      status: 'Under Maintenance',
      color: Color(0xffd1494d),
    ),
    _ComputerEntry(
      id: 'PC - 004',
      room: 'RW 306',
      status: 'Working',
      color: Color(0xff3dc870),
    ),
    _ComputerEntry(
      id: 'PC - 005',
      room: 'RW 306',
      status: 'In Progress',
      color: Color(0xff2d8ae6),
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xff0d0b8e),
            padding: const EdgeInsets.fromLTRB(12, 20, 12, 22),
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
                const Expanded(
                  child: Text(
                    'Computer List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xfff5f5f5),
              padding: const EdgeInsets.all(18),
              child: ListView.separated(
                itemCount: computers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final computer = computers[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).push(
                      noAnimationRoute((_) => const ComputerDetailsScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
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
                          const Icon(
                            Icons.desktop_windows,
                            size: 28,
                            color: Colors.black87,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  computer.id,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  computer.room,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xff666666),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: computer.color.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              computer.status,
                              style: TextStyle(
                                color: computer.color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          AppNavBar(
            selected: 2,
            onSelected: (index) => navigateFrom(context, index, 2),
          ),
        ],
      ),
    ),
  );
}

class _ComputerEntry {
  const _ComputerEntry({
    required this.id,
    required this.room,
    required this.status,
    required this.color,
  });

  final String id;
  final String room;
  final String status;
  final Color color;
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
    decoration: const BoxDecoration(
      color: Color(0xff155bb2),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
    ),
    child: Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              height: 1.15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}
