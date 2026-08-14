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

  final List<Map<String, String>> _sampleBarcodes = [
    {'name': 'Beras Ramos 5kg', 'code': '8991001'},
    {'name': 'Minyak Bimoli 2L', 'code': '8991003'},
    {'name': 'Telur Fresh 1kg', 'code': '8991005'},
    {'name': 'Indomie Goreng', 'code': '8991008'},
    {'name': 'Gudang Garam Surya', 'code': '8991012'},
    {'name': 'Le Minerale Dingin', 'code': '8991015'},
    {'name': 'Baru (Belum Ada)', 'code': '89998881234'},
  ];

  @override
  void initState() {
    super.initState();
    _laserAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Hanya gunakan native camera controller jika bukan Web atau jika platform channel tersedia
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
        const SnackBar(
          content: Text('Senter kamera hanya aktif saat menggunakan kamera HP fisik.'),
          duration: Duration(milliseconds: 1200),
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

    // Debounce to allow continuous smooth scan
    Future.delayed(const Duration(milliseconds: 1400), () {
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
        height: 620,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
          border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.5), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Scanner Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1E293B),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.secondaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kamera Scanner Barcode HP',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Scan cepat: Arahkan kamera ke barcode bawaan produk',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
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
                      top: 14,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.secondaryTeal),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Barcode Masuk: $_lastScannedCode',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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

            // Quick Test Barcode Pills (For ultra-fast cashier testing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFF0F172A),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Simulasi Scan Barcode (Klik Cepat):',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Scan ➔ Scan ➔ Bayar',
                        style: TextStyle(color: AppTheme.secondaryTeal, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _sampleBarcodes.map((item) {
                        final isNew = item['code'] == '89998881234';
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _handleBarcode(item['code']!),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: isNew ? const Color(0xFF0D9488).withValues(alpha: 0.3) : const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isNew ? AppTheme.secondaryTeal : AppTheme.borderColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isNew ? Icons.add_circle_outline_rounded : Icons.barcode_reader,
                                    size: 12,
                                    color: isNew ? AppTheme.secondaryTeal : Colors.amberAccent,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    item['name']!,
                                    style: TextStyle(
                                      color: isNew ? const Color(0xFF5EEAD4) : Colors.white,
                                      fontSize: 11,
                                      fontWeight: isNew ? FontWeight.bold : FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Scanner Control Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Senter / Flash Torch Toggle
                  IconButton(
                    onPressed: _safeToggleTorch,
                    icon: Icon(
                      _torchEnabled ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _torchEnabled ? Colors.amber : Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Senter Kamera',
                  ),

                  // Switch Camera (Depan / Belakang)
                  IconButton(
                    onPressed: _safeSwitchCamera,
                    icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white70, size: 20),
                    tooltip: 'Ganti Kamera',
                  ),

                  // Mode Toggle Manual
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showManualInput = !_showManualInput;
                      });
                    },
                    icon: Icon(
                      _showManualInput ? Icons.camera_alt_rounded : Icons.keyboard_rounded,
                      color: AppTheme.secondaryTeal,
                      size: 20,
                    ),
                    tooltip: 'Ketik Barcode Manual / USB Gun Scanner',
                  ),

                  const Spacer(),

                  // Tombol Selesai
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveScannerView() {
    return Container(
      color: const Color(0xFF0B1120),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Scanner Target Frame with animated red laser line
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Frame
                  Container(
                    width: 270,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isProcessing ? AppTheme.successGreen : AppTheme.secondaryTeal,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isProcessing ? AppTheme.successGreen : AppTheme.primaryTeal).withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Animated Scanning Laser Bar
                        if (!_isProcessing)
                          AnimatedBuilder(
                            animation: _laserAnimController,
                            builder: (context, child) {
                              return Positioned(
                                top: _laserAnimController.value * 140 + 10,
                                left: 10,
                                right: 10,
                                child: Container(
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                                        blurRadius: 8,
                                        spreadRadius: 1,
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
                                Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  '✓ Scan Berhasil!',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        else
                          const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.qr_code_scanner_rounded, color: Colors.white30, size: 48),
                                SizedBox(height: 8),
                                Text(
                                  'Bidik Barcode Produk',
                                  style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Direct text / USB reader input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _manualInputController,
              style: const TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 0.5),
              decoration: InputDecoration(
                hintText: 'Ketik nomor barcode atau tembak pakai scanner USB...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 11.5),
                fillColor: const Color(0xFF1E293B),
                filled: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                prefixIcon: const Icon(Icons.barcode_reader, color: AppTheme.primaryTeal, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward_rounded, color: AppTheme.secondaryTeal, size: 18),
                  onPressed: () {
                    _handleBarcode(_manualInputController.text);
                    _manualInputController.clear();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primaryTeal),
                ),
              ),
              onSubmitted: (val) {
                _handleBarcode(val);
                _manualInputController.clear();
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
