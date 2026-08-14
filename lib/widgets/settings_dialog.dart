import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../theme/app_theme.dart';
import 'user_guide_dialog.dart';

class SettingsDialog extends StatefulWidget {
  final List<Product> products;
  final String storeName;
  final ValueChanged<String>? onStoreNameChanged;
  final VoidCallback onDataChanged;

  const SettingsDialog({
    super.key,
    required this.products,
    this.storeName = 'TOKO MADURA BHERUNG',
    this.onStoreNameChanged,
    required this.onDataChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final AppsScriptService _appsScriptService = AppsScriptService();

  // Link Template Master "Make a Copy" untuk Pembeli Toko
  static const String templateCopyUrl =
      'https://docs.google.com/spreadsheets/d/1k6MIzg_1atT9sp_zPG4LzQOPVe4GC3ctb8GOV95Wyvc/copy';

  late final TextEditingController _inputController;
  late final TextEditingController _storeNameController;
  bool _isTesting = false;
  bool _isSyncingProducts = false;
  String? _statusMessage;
  bool _isStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.storeName);
    // Inisialisasi dari input simpanan user (atau KOSONG jika belum pernah diset)
    _inputController = TextEditingController(
      text: _appsScriptService.rawInput.isNotEmpty
          ? _appsScriptService.rawInput
          : _appsScriptService.spreadsheetId,
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _handleTestConnection() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _statusMessage = 'Harap masukkan Link atau ID Google Spreadsheet toko Anda.';
        _isStatusSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    final res = await _appsScriptService.testConnection(input);

    if (!mounted) return;
    setState(() {
      _isTesting = false;
      _isStatusSuccess = res['success'] == true;
      _statusMessage = res['message'];
    });

    if (_isStatusSuccess) {
      widget.onDataChanged();
    }
  }

  Future<void> _handleDisconnect() async {
    await _appsScriptService.clearSettings();
    _inputController.clear();
    setState(() {
      _statusMessage = 'Koneksi database telah diputuskan & direset.';
      _isStatusSuccess = true;
    });
    widget.onDataChanged();
  }

  Future<void> _handleSyncProducts() async {
    setState(() {
      _isSyncingProducts = true;
      _statusMessage = null;
    });

    final res = await _appsScriptService.syncAllProducts(widget.products);

    if (!mounted) return;
    setState(() {
      _isSyncingProducts = false;
      _isStatusSuccess = res['success'] == true;
      _statusMessage = res['message'];
    });
  }

  Future<void> _handleFlushQueue() async {
    final count = await _appsScriptService.flushOfflineQueue();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Berhasil menyinkronkan $count transaksi offline ke Spreadsheet!'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
    setState(() {});
  }

  void _copyTemplateLink() {
    Clipboard.setData(const ClipboardData(text: templateCopyUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Link Template Google Sheets disalin ke clipboard! Buka di browser.'),
        backgroundColor: AppTheme.primaryTeal,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openUserGuide() {
    showDialog(
      context: context,
      builder: (context) => const UserGuideDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _appsScriptService.isConnected;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: 540,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Tombol Panduan
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.cloud_sync_rounded, color: AppTheme.primaryTeal, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Database Google Spreadsheet Toko',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      Text(
                        'Cukup Masukkan Link / ID Spreadsheet (Tanpa Deploy)',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(height: 16, color: AppTheme.borderColor),

              // 2. Status Koneksi Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFF0FDF4) : AppTheme.bgSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isConnected ? AppTheme.successGreen.withValues(alpha: 0.6) : AppTheme.borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isConnected ? AppTheme.successGreen : AppTheme.textSubtle,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected
                                ? 'Status: Terhubung ke Spreadsheet Toko'
                                : 'Status: Mode Offline (Belum Terhubung)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isConnected ? const Color(0xFF065F46) : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            isConnected
                                ? _appsScriptService.spreadsheetName
                                : 'Transaksi kasir disimpan lokal & siap disinkronkan',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isConnected ? const Color(0xFF047857) : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected) ...[
                      TextButton.icon(
                        onPressed: _handleDisconnect,
                        icon: const Icon(Icons.link_off_rounded, size: 13, color: AppTheme.dangerRed),
                        label: const Text('Putuskan', style: TextStyle(fontSize: 10.5, color: AppTheme.dangerRed)),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. PANDUAN 2 LANGKAH & TOMBOL BUKU PANDUAN
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, size: 16, color: AppTheme.warningOrange),
                        const SizedBox(width: 5),
                        const Text(
                          'Cara Hubungkan Spreadsheet (Hanya 10 Detik):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: _openUserGuide,
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_rounded, size: 12, color: AppTheme.primaryTeal),
                                SizedBox(width: 3),
                                Text(
                                  'Buku Panduan',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Langkah 1: Tombol Salin Template
                    _buildStepRow(
                      step: '1',
                      title: 'Buka Link Template & Buat Salinan di Google Drive Anda:',
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 4),
                        child: OutlinedButton.icon(
                          onPressed: _copyTemplateLink,
                          icon: const Icon(Icons.copy_rounded, size: 14, color: AppTheme.primaryTeal),
                          label: const Text(
                            'Salin Link Template Google Sheets (Buka di Browser)',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Langkah 2: Tempel Link / ID
                    _buildStepRow(
                      step: '2',
                      title: 'Pastikan akses berbagi "Editor", lalu salin link/ID spreadsheet Anda ke bawah:',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. Input Link / ID Spreadsheet (Tanpa Hardcoded Default)
              const Text(
                'Link atau ID Google Spreadsheet Toko:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 5),

              TextField(
                controller: _inputController,
                style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: 'Tempel link spreadsheet (contoh: https://docs.google.com/spreadsheets/d/...)',
                  isDense: true,
                  prefixIcon: const Icon(Icons.table_chart_rounded, size: 18, color: AppTheme.primaryTeal),
                  suffixIcon: _inputController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _inputController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),

              // Tombol Simpan & Test Koneksi
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _handleTestConnection,
                      icon: _isTesting
                          ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cable_rounded, size: 15),
                      label: Text(_isTesting ? 'Menghubungkan...' : 'Hubungkan & Simpan Database', style: const TextStyle(fontSize: 11.5)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),

              // Status Feedback Message
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _isStatusSuccess ? AppTheme.successGreenLight : AppTheme.dangerRedLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isStatusSuccess ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isStatusSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                        size: 14,
                        color: _isStatusSuccess ? AppTheme.successGreen : AppTheme.dangerRed,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _isStatusSuccess ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Divider(height: 18, color: AppTheme.borderColor),

              // 5. Sinkronisasi Data & Antrean Offline
              const Text(
                'Alat Sinkronisasi Sembako & Transaksi:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              ),
              const SizedBox(height: 6),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (!isConnected || _isSyncingProducts) ? null : _handleSyncProducts,
                      icon: _isSyncingProducts
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.cloud_upload_outlined, size: 14),
                      label: const Text('Sync 17 Katalog Sembako', style: TextStyle(fontSize: 10.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: (_appsScriptService.offlineQueueCount == 0 || !isConnected) ? null : _handleFlushQueue,
                      icon: const Icon(Icons.sync_rounded, size: 14),
                      label: Text('Kirim Offline (${_appsScriptService.offlineQueueCount})', style: const TextStyle(fontSize: 10.5)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({required String step, required String title, Widget? child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.primaryTeal,
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppTheme.textDark, height: 1.3),
              ),
              ?child,
            ],
          ),
        ),
      ],
    );
  }
}
