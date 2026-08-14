import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final List<Product> products;
  final String storeName;
  final ValueChanged<String>? onStoreNameChanged;
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.products,
    this.storeName = 'TOKO MADURA BHERUNG',
    this.onStoreNameChanged,
    required this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppsScriptService _appsScriptService = AppsScriptService();

  // Link Template Master "Make a Copy" untuk Pembeli Toko
  static const String templateCopyUrl =
      'https://docs.google.com/spreadsheets/d/1k6MIzg_1atT9sp_zPG4LzQOPVe4GC3ctb8GOV95Wyvc/copy';

  late final TextEditingController _inputController;
  late final TextEditingController _storeNameController;
  bool _isTesting = false;
  bool _isSyncingProducts = false;
  bool _isPullingProducts = false;
  String? _statusMessage;
  bool _isStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    _storeNameController = TextEditingController(text: widget.storeName);
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

  Future<void> _handlePullProductsFromSpreadsheet() async {
    setState(() {
      _isPullingProducts = true;
      _statusMessage = null;
    });

    final fetched = await _appsScriptService.fetchProductsFromSpreadsheet();

    if (!mounted) return;
    setState(() {
      _isPullingProducts = false;
    });

    if (fetched != null && fetched.isNotEmpty) {
      widget.products.clear();
      widget.products.addAll(fetched);
      InventoryStorageService().saveProducts(widget.products);
      widget.onDataChanged();

      setState(() {
        _isStatusSuccess = true;
        _statusMessage = 'Berhasil mengimpor ${fetched.length} produk katalog master dari Google Spreadsheet!';
      });
    } else {
      setState(() {
        _isStatusSuccess = false;
        _statusMessage = 'Gagal memuat katalog atau data produk di Spreadsheet kosong.';
      });
    }
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

  @override
  Widget build(BuildContext context) {
    final isConnected = _appsScriptService.isConnected;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
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
        title: const Row(
          children: [
            Text(
              'Pengaturan & Cloud Sync',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
            SizedBox(width: 8),
            Text(
              '• Google Spreadsheet',
              style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Status Koneksi Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isConnected ? const Color(0xFF86EFAC) : AppTheme.borderColor,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected ? AppTheme.successGreen : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected
                              ? 'Status: Terhubung ke Google Spreadsheet'
                              : 'Status: Mode Offline (Belum Terhubung)',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? const Color(0xFF166534) : AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? 'ID: ${_appsScriptService.spreadsheetId}'
                              : 'Transaksi kasir disimpan lokal & siap disinkronkan',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isConnected)
                    IconButton(
                      icon: const Icon(Icons.link_off_rounded, color: AppTheme.dangerRed, size: 20),
                      tooltip: 'Putuskan Koneksi',
                      onPressed: _handleDisconnect,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Panduan 10 Detik
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bolt_rounded, color: Color(0xFF2563EB), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Cara Hubungkan Spreadsheet (10 Detik)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Step 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 8.5,
                        backgroundColor: Color(0xFF0D9488),
                        child: Text('1', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Buka Link Template & Buat Salinan di Google Drive Anda:',
                              style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: templateCopyUrl));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Link Template disalin ke Clipboard!'),
                                    backgroundColor: AppTheme.successGreen,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0D9488)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.copy_rounded, size: 14, color: Color(0xFF0D9488)),
                                    SizedBox(width: 6),
                                    Text(
                                      'Salin Link Template Google Sheets',
                                      style: TextStyle(color: Color(0xFF0D9488), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Step 2
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 8.5,
                        backgroundColor: Color(0xFF0D9488),
                        child: Text('2', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pastikan akses berbagi "Editor", lalu salin link/ID spreadsheet Anda ke bawah:',
                          style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Form Input Link/ID Spreadsheet
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Link atau ID Google Spreadsheet Toko:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _inputController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Tempel link spreadsheet (https://docs.google.com/...)',
                      hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      prefixIcon: const Icon(Icons.table_chart_rounded, color: AppTheme.primaryTeal, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.paste_rounded, size: 16),
                        tooltip: 'Tempel dari Clipboard',
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data?.text != null) {
                            _inputController.text = data!.text!;
                          }
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tombol Hubungkan
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _handleTestConnection,
                      icon: _isTesting
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cable_rounded, size: 16),
                      label: Text(_isTesting ? 'Memeriksa Spreadsheet...' : 'Hubungkan & Simpan Database', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 12),

            // Status Message Box
            if (_statusMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isStatusSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isStatusSuccess ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isStatusSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: _isStatusSuccess ? AppTheme.successGreen : AppTheme.dangerRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isStatusSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 4. Alat Sinkronisasi Sembako & Transaksi Offline
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alat Sinkronisasi Sembako & Transaksi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  // Tarik Produk dari Spreadsheet Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (!isConnected || _isPullingProducts) ? null : _handlePullProductsFromSpreadsheet,
                      icon: _isPullingProducts
                          ? const SizedBox(width: 13, height: 13, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.download_rounded, size: 16),
                      label: Text(
                        _isPullingProducts ? 'Mengambil Data dari Spreadsheet...' : 'Tarik & Perbarui Katalog dari Spreadsheet',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: (!isConnected || _isSyncingProducts) ? null : _handleSyncProducts,
                          icon: _isSyncingProducts
                              ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.cloud_upload_outlined, size: 14),
                          label: Text(
                            _isSyncingProducts ? 'Mengunggah...' : 'Upload ${widget.products.length} Sembako',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: !isConnected ? null : _handleFlushQueue,
                          icon: const Icon(Icons.sync_rounded, size: 14),
                          label: Text(
                            'Kirim Offline (${_appsScriptService.offlineQueueCount})',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Profil Toko (Nama Toko)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nama Toko Kelontong:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _storeNameController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'cth: TOKO MADURA BHERUNG',
                      prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onChanged: (val) {
                      if (widget.onStoreNameChanged != null) {
                        widget.onStoreNameChanged!(val);
                      }
                    },
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
