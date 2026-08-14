import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  final ValueChanged<String> onBarcodeDetected;
  final VoidCallback? onOpenQuickAdd;

  const ScannerScreen({
    super.key,
    required this.onBarcodeDetected,
    this.onOpenQuickAdd,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  final TextEditingController _manualInputController = TextEditingController();
  late AnimationController _laserAnimController;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _useNativeScanner = false;
  String? _lastScannedCode;
  int _scannedCount = 0;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    try {
      _controller = MobileScannerController(
        formats: const [
          BarcodeFormat.all,
        ],
        detectionSpeed: DetectionSpeed.unrestricted,
        detectionTimeoutMs: 250,
      );
      _useNativeScanner = true;
    } catch (_) {
      _useNativeScanner = false;
    }
  }

  @override
  void dispose() {
    _laserAnimController.stop();
    _laserAnimController.dispose();
    try {
      _controller?.dispose();
    } catch (_) {}
    _manualInputController.dispose();
    super.dispose();
  }

  void _safeToggleTorch() async {
    if (_controller == null) return;
    try {
      await _controller?.toggleTorch();
      if (mounted) {
        setState(() {
          _torchEnabled = !_torchEnabled;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senter hanya didukung pada kamera HP fisik.'),
            duration: Duration(milliseconds: 1200),
          ),
        );
      }
    }
  }

  void _safeSwitchCamera() async {
    if (_controller == null) return;
    try {
      await _controller?.switchCamera();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _handleBarcode(String code) {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = cleanCode;
      _scannedCount++;
    });

    widget.onBarcodeDetected(cleanCode);

    // Toast notifikasi scan berhasil
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Barcode "$cleanCode" terdeteksi!'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(milliseconds: 1000),
      ),
    );

    // Debounce agar kasir bisa scan barang berikutnya dengan lancar
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1120),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 1,
        toolbarHeight: 46,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kasir',
          visualDensity: VisualDensity.compact,
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.secondaryTeal, size: 18),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Scanner Barcode',
                style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_scannedCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_scannedCount Scan',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white, size: 18),
            onPressed: _safeToggleTorch,
            tooltip: 'Senter',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 18),
            onPressed: _safeSwitchCamera,
            tooltip: 'Ganti Kamera',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Viewfinder Area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera Stream or Animated Target
                  Positioned.fill(
                    child: _useNativeScanner && _controller != null
                        ? MobileScanner(
                            controller: _controller!,
                            fit: BoxFit.cover,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final val = barcode.rawValue ?? barcode.displayValue;
                                if (val != null && val.trim().isNotEmpty) {
                                  _handleBarcode(val.trim());
                                  break;
                                }
                              }
                            },
                            errorBuilder: (context, error) {
                              return Container(
                                color: const Color(0xFF0F172A),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.videocam_off_rounded, size: 52, color: Colors.white38),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Akses Kamera / Webcam Belum Diizinkan',
                                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Klik ikon gembok di address bar browser dan izinkan "Camera: Allow"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Color(0xFF5EEAD4), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: const Color(0xFF0F172A),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 72,
                                    color: AppTheme.secondaryTeal.withValues(alpha: 0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Arahkan Barcode ke Dalam Kotak',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Mendukung Barcode Produk, Webcam & Scanner Gun',
                                    style: TextStyle(color: Colors.white38, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),

                  // Framing Box & Laser Animation
                  Center(
                    child: Container(
                      width: 320,
                      height: 190,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isProcessing ? AppTheme.successGreen : AppTheme.secondaryTeal,
                          width: 2.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Laser Scanner Animation
                          AnimatedBuilder(
                            animation: _laserAnimController,
                            builder: (context, child) {
                              return Align(
                                alignment: Alignment(0, (_laserAnimController.value * 2) - 1),
                                child: Container(
                                  height: 2.5,
                                  width: 300,
                                  decoration: BoxDecoration(
                                    color: _isProcessing ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isProcessing ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Top Helper Tip Banner
                  Positioned(
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_rounded, color: Color(0xFFFDE047), size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Posisikan barcode mendatar di tengah laser merah (~10-15 cm)',
                            style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Floating Last Scanned Code Indicator
                  if (_lastScannedCode != null)
                    Positioned(
                      top: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 6),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Terdeteksi: $_lastScannedCode',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Controls & Test Simulation Bottom Panel
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual Gun / Keyboard Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Ketik barcode / tembak barcode scanner USB...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined, color: Colors.white54, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _handleBarcode(val.trim());
                              _manualInputController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_manualInputController.text.trim().isNotEmpty) {
                            _handleBarcode(_manualInputController.text.trim());
                            _manualInputController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Input', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Selesai & Kembali Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text('Selesai / Kembali ke Kasir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
