import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/sound_service.dart';
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
  final SoundService _soundService = SoundService();
  late AnimationController _laserAnimController;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _useNativeScanner = false;
  bool _hasCameraError = false;
  String? _lastScannedCode;
  DateTime? _lastScannedTimestamp;
  int _scannedCount = 0;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _initScanner();
  }

  void _initScanner() {
    try {
      _controller?.dispose();
      _controller = MobileScannerController(
        formats: const [
          BarcodeFormat.all,
        ],
        detectionSpeed: DetectionSpeed.noDuplicates,
        detectionTimeoutMs: 1200,
      );
      setState(() {
        _useNativeScanner = true;
        _hasCameraError = false;
      });
    } catch (_) {
      setState(() {
        _useNativeScanner = false;
        _hasCameraError = true;
      });
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
    if (_controller == null || _hasCameraError) return;
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
    if (_controller == null || _hasCameraError) return;
    try {
      await _controller?.switchCamera();
      if (mounted) setState(() {});
    } catch (_) {}
  }

  void _handleBarcode(String code) {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    final now = DateTime.now();

    // Cegah multi-scan instan / saat transisi processing
    if (_isProcessing) return;

    // Cegah scan ganda secara tidak sengaja pada barcode yang sama dalam kurun 2 detik
    if (_lastScannedCode == cleanCode && _lastScannedTimestamp != null) {
      final diff = now.difference(_lastScannedTimestamp!).inMilliseconds;
      if (diff < 2000) {
        return;
      }
    }

    _lastScannedTimestamp = now;
    _lastScannedCode = cleanCode;

    setState(() {
      _isProcessing = true;
      _scannedCount++;
    });

    // 1. Putar bunyi BEEP POS Scanner dan getaran Haptic
    _soundService.playScanBeep();

    // 2. Kirim callback ke keranjang/POS
    widget.onBarcodeDetected(cleanCode);

    // 3. Debounce jeda cooldown agar kasir tidak sengaja scan berulang
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
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 19),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kasir',
        ),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.goldAccent, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scanner Barcode',
                    style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Kamera HP / USB Scanner Gun',
                    style: TextStyle(color: AppTheme.goldAccent, fontSize: 10.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_scannedCount > 0)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_scannedCount Scan',
                  style: const TextStyle(color: AppTheme.primaryDark, fontSize: 10.5, fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _soundService.isSoundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: _soundService.isSoundEnabled ? AppTheme.goldAccent : Colors.white60,
              size: 19,
            ),
            onPressed: () {
              setState(() {
                _soundService.setSoundEnabled(!_soundService.isSoundEnabled);
              });
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_soundService.isSoundEnabled ? 'Bunyi scanner aktif (BEEP)' : 'Bunyi scanner dinonaktifkan (Mute)'),
                  duration: const Duration(milliseconds: 900),
                  backgroundColor: AppTheme.surfaceDark,
                ),
              );
            },
            tooltip: _soundService.isSoundEnabled ? 'Matikan Suara Beep' : 'Nyalakan Suara Beep',
          ),
          if (!_hasCameraError) ...[
            IconButton(
              icon: Icon(_torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded, color: Colors.white, size: 19),
              onPressed: _safeToggleTorch,
              tooltip: 'Senter',
            ),
            IconButton(
              icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 19),
              onPressed: _safeSwitchCamera,
              tooltip: 'Ganti Kamera',
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Viewfinder Camera Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final targetWidth = min(constraints.maxWidth * 0.86, 340.0);
                  const targetHeight = 190.0;

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Camera Stream / Error Placeholder
                      Positioned.fill(
                        child: _useNativeScanner && _controller != null && !_hasCameraError
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
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!_hasCameraError && mounted) {
                                      setState(() => _hasCameraError = true);
                                    }
                                  });
                                  return _buildCameraErrorState();
                                },
                              )
                            : _buildCameraErrorState(),
                      ),

                      // Professional Target Viewfinder & Laser (Only shown when camera is active)
                      if (!_hasCameraError) ...[
                        // Dark overlay around viewfinder
                        Center(
                          child: Container(
                            width: targetWidth,
                            height: targetHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 200,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Corner Reticle Brackets (Professional POS styling)
                        Center(
                          child: SizedBox(
                            width: targetWidth,
                            height: targetHeight,
                            child: Stack(
                              children: [
                                // Top-Left Corner
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: _buildCornerBracket(isTop: true, isLeft: true),
                                ),
                                // Top-Right Corner
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: _buildCornerBracket(isTop: true, isLeft: false),
                                ),
                                // Bottom-Left Corner
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  child: _buildCornerBracket(isTop: false, isLeft: true),
                                ),
                                // Bottom-Right Corner
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: _buildCornerBracket(isTop: false, isLeft: false),
                                ),

                                // Laser Scanner Line clipped strictly inside the viewfinder
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: AnimatedBuilder(
                                    animation: _laserAnimController,
                                    builder: (context, child) {
                                      return Align(
                                        alignment: Alignment(0, (_laserAnimController.value * 2) - 1),
                                        child: Container(
                                          height: 3,
                                          margin: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: _isProcessing
                                                  ? [Colors.transparent, AppTheme.successGreen, Colors.transparent]
                                                  : [Colors.transparent, const Color(0xFFEF4444), Colors.transparent],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: (_isProcessing ? AppTheme.successGreen : const Color(0xFFEF4444)).withValues(alpha: 0.8),
                                                blurRadius: 8,
                                                spreadRadius: 1.5,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top Helper Tip Banner
                        Positioned(
                          top: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 8),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.center_focus_strong_rounded, color: AppTheme.goldAccent, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Posisikan barcode di tengah laser merah (~10-15 cm)',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Floating Last Scanned Code Notification
                      if (_lastScannedCode != null)
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 3)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Terdeteksi: $_lastScannedCode',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Controls & Manual Input Bottom Panel (Obsidian & Gold Theme)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  top: BorderSide(color: AppTheme.surfaceDark, width: 1.5),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Manual Barcode / Scanner Gun USB input field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _manualInputController,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'Ketik barcode / tembak scanner gun USB...',
                            hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined, color: AppTheme.goldAccent, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.surfaceDark),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: AppTheme.primaryGold),
                            ),
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
                          backgroundColor: AppTheme.primaryGold,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Input', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Selesai & Kembali Button (Gold Gradient)
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_circle_rounded, size: 17),
                      label: const Text('Selesai / Kembali ke Kasir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: AppTheme.primaryDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
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

  // Clean Camera Permission / Offline Card (No awkward overlaps)
  Widget _buildCameraErrorState() {
    return Container(
      color: const Color(0xFF0B1120),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.primaryDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.videocam_off_rounded, size: 38, color: AppTheme.goldAccent),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Akses Kamera Belum Diizinkan',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w900),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Klik ikon gembok pada address bar browser / pengaturan izin HP dan aktifkan "Camera: Allow" agar dapat scan otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _initScanner,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Coba Hubungkan Kamera Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.goldAccent,
                    side: const BorderSide(color: AppTheme.primaryGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper Corner Reticle Bracket Builder
  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    const double bracketSize = 22.0;
    const double thickness = 3.5;
    final color = _isProcessing ? AppTheme.successGreen : AppTheme.primaryGold;

    return Container(
      width: bracketSize,
      height: bracketSize,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? BorderSide(color: color, width: thickness) : BorderSide.none,
          bottom: !isTop ? BorderSide(color: color, width: thickness) : BorderSide.none,
          left: isLeft ? BorderSide(color: color, width: thickness) : BorderSide.none,
          right: !isLeft ? BorderSide(color: color, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
        ),
      ),
    );
  }
}
