import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mq_journey/features/scan/data/adapters/settings_progress_api_adapter.dart';
import 'package:mq_journey/features/scan/domain/contracts/visit_event.dart';
import 'package:mq_journey/features/scan/presentation/widgets/scanner_view.dart';
import 'package:mq_journey/features/scan/providers/scan_providers.dart';
import 'package:permission_handler/permission_handler.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  late final MobileScannerController _scannerController;
  bool _torchOn = false;
  int _lastProcessed = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() => _torchOn = !_torchOn);
    _scannerController.toggleTorch();
  }

  String? _parseLocationId(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null) return null;
    if (uri.host == 'mq.edu.au' || uri.scheme == 'io.mqjourney') {
      return uri.queryParameters['locationId'];
    }
    return null;
  }

  Future<void> _onDetectBarcode(String raw) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastProcessed < 1500) return;
    _lastProcessed = now;

    final locationId = _parseLocationId(raw);
    if (locationId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read QR code')),
      );
      return;
    }

    final manifest = await ref.read(trailManifestProvider.future);
    if (!manifest.contains(locationId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not part of the trail')),
      );
      return;
    }

    final visit = VisitEvent(
      locationId: locationId,
      scannedAt: DateTime.now(),
    );
    await ref.read(progressApiProvider).recordVisit(visit);

    if (!mounted) return;
    context.go('/location/$locationId');
  }

  Future<void> _openAppSettings() async {
    await openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          ScannerView(
            controller: _scannerController,
            onDetect: _onDetectBarcode,
            onPermissionDenied: _openAppSettings,
          ),
          const _DimSurround(reticleColor: Colors.white),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimSurround extends StatelessWidget {
  const _DimSurround({required this.reticleColor});
  final Color reticleColor;

  @override
  Widget build(BuildContext context) {
    const r = 240.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = (w - r) / 2;
        final cy = (h - r) / 2;
        const dim = Colors.black54;
        return Stack(
          children: [
            Positioned(left: 0, top: 0, width: w, height: cy, child: Container(color: dim)),
            Positioned(left: 0, bottom: 0, width: w, height: cy, child: Container(color: dim)),
            Positioned(left: 0, top: cy, width: cx, height: r, child: Container(color: dim)),
            Positioned(right: 0, top: cy, width: cx, height: r, child: Container(color: dim)),
          ],
        );
      },
    );
  }
}
