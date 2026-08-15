import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/app_theme.dart';

class CameraBarcodeScannerDialog extends StatefulWidget {
  final ValueChanged<String> onBarcodeDetected;
  final VoidCallback? onOpenQuickAdd;

  const CameraBarcodeScannerDialog({
    super.key,
    required this.onBarcodeDetected,
    this.onOpenQuickAdd,
  });

  @override
  State<CameraBarcodeScannerDialog> createState() => _CameraBarcodeScannerDialogState();
}

class _CameraBarcodeScannerDialogState extends State<CameraBarcodeScannerDialog> with SingleTickerProviderStateMixin {
  MobileScannerController? _controller;
  final TextEditingController _manualInputController = TextEditingController();
  late AnimationController _laserAnimController;
  bool _isProcessing = false;
  bool _torchEnabled = false;
  bool _showManualInput = false;
  bool _cameraInitialized = false;
  bool _useNativeScanner = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Gunakan native camera controller jika didukung
    if (!kIsWeb) {
      try {
        _controller = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
        _useNativeScanner = true;
      } catch (_) {
        _useNativeScanner = false;
      }
    }
  }

  @override
  void dispose() {
    _laserAnimController.dispose();
    try {
      _controller?.dispose();
    } catch (_) {}
    _manualInputController.dispose();
    super.dispose();
  }

  void _safeToggleTorch() async {
    if (_controller == null || !_cameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Senter kamera hanya aktif saat menggunakan kamera HP fisik.'),
          backgroundColor: AppTheme.surfaceDark,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1400),
        ),
      );
      return;
    }
    try {
      await _controller?.toggleTorch();
      if (mounted) {
        setState(() {
          _torchEnabled = !_torchEnabled;
        });
      }
    } catch (_) {}
  }

  void _safeSwitchCamera() async {
    if (_controller == null || !_cameraInitialized) return;
    try {
      await _controller?.switchCamera();
    } catch (_) {}
  }

  void _handleBarcode(String code) {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = cleanCode;
    });

    widget.onBarcodeDetected(cleanCode);

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        height: 600,
        decoration: BoxDecoration(
          color: AppTheme.primaryDark,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.15),
              blurRadius: 20,
              spreadRadius: -2,
            ),
          ],
          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Scanner Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDark, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: AppTheme.goldGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryDark, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Barcode Kamera',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Arahkan kamera tepat ke barcode kemasan produk',
                          style: TextStyle(
                            color: AppTheme.textSubtle,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // Camera Viewfinder / Interactive Laser Scan View
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_useNativeScanner && _controller != null && !_showManualInput)
                    MobileScanner(
                      controller: _controller!,
                      onDetect: (capture) {
                        if (!_cameraInitialized && mounted) {
                          setState(() => _cameraInitialized = true);
                        }
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                            _handleBarcode(barcode.rawValue!);
                            break;
                          }
                        }
                      },
                      errorBuilder: (context, error) {
                        return _buildInteractiveScannerView();
                      },
                    )
                  else
                    _buildInteractiveScannerView(),

                  // Last Scanned Notification Pill
                  if (_lastScannedCode != null)
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.primaryGold, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Terdeteksi: $_lastScannedCode',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scanner Control Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  top: BorderSide(color: AppTheme.borderDark, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Senter / Flash Torch Toggle
                  _buildFooterIconButton(
                    icon: _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _torchEnabled ? AppTheme.goldAccent : Colors.white70,
                    tooltip: 'Senter Kamera',
                    onTap: _safeToggleTorch,
                  ),
                  const SizedBox(width: 8),

                  // Switch Camera (Depan / Belakang)
                  _buildFooterIconButton(
                    icon: Icons.cameraswitch_rounded,
                    color: Colors.white70,
                    tooltip: 'Ganti Kamera',
                    onTap: _safeSwitchCamera,
                  ),
                  const SizedBox(width: 8),

                  // Mode Toggle Manual
                  _buildFooterIconButton(
                    icon: _showManualInput ? Icons.camera_alt_rounded : Icons.keyboard_alt_rounded,
                    color: _showManualInput ? AppTheme.primaryGold : Colors.white70,
                    tooltip: 'Mode Keyboard / Scanner USB',
                    onTap: () {
                      setState(() {
                        _showManualInput = !_showManualInput;
                      });
                    },
                  ),

                  const Spacer(),

                  // Tombol Selesai
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Selesai'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.primaryDark,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
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

  Widget _buildFooterIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildInteractiveScannerView() {
    return Container(
      color: AppTheme.surfaceDarker,
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Scanner Target Frame with Modern Gold HUD Brackets & Laser
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Frame with Gold Glow & Custom Corners
                  CustomPaint(
                    painter: _ScannerHudCornerPainter(
                      color: _isProcessing ? AppTheme.successGreen : AppTheme.primaryGold,
                    ),
                    child: Container(
                      width: 280,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Stack(
                        children: [
                          // Animated Gold Laser Sweep
                          if (!_isProcessing)
                            AnimatedBuilder(
                              animation: _laserAnimController,
                              builder: (context, child) {
                                return Positioned(
                                  top: _laserAnimController.value * 150 + 12,
                                  left: 12,
                                  right: 12,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppTheme.goldAccent,
                                          AppTheme.primaryGold,
                                          AppTheme.goldAccent,
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryGold.withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          if (_isProcessing)
                            const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Scan Berhasil',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.qr_code_scanner_rounded, color: Colors.white24, size: 44),
                                  SizedBox(height: 8),
                                  Text(
                                    'Posisikan Barcode di Kotak Ini',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Direct text / USB reader input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: TextField(
              controller: _manualInputController,
              style: const TextStyle(color: Colors.white, fontSize: 13.5, letterSpacing: 0.4),
              decoration: InputDecoration(
                hintText: 'Ketik barcode manual / tembak scanner USB...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                fillColor: AppTheme.surfaceDark,
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                prefixIcon: const Icon(Icons.barcode_reader, color: AppTheme.primaryGold, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGold, size: 18),
                  onPressed: () {
                    _handleBarcode(_manualInputController.text);
                    _manualInputController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                ),
              ),
              onSubmitted: (val) {
                _handleBarcode(val);
                _manualInputController.clear();
              },
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// Custom Painter for HUD Corner Brackets
class _ScannerHudCornerPainter extends CustomPainter {
  final Color color;

  _ScannerHudCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const radius = 12.0;

    // Top-Left Corner
    final tlPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(const Offset(radius, 0), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top-Right Corner
    final trPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, paint);

    // Bottom-Left Corner
    final blPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..arcToPoint(Offset(radius, size.height), radius: const Radius.circular(radius))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(blPath, paint);

    // Bottom-Right Corner
    final brPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..arcToPoint(Offset(size.width, size.height - radius), radius: const Radius.circular(radius))
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerHudCornerPainter oldDelegate) => oldDelegate.color != color;
}
