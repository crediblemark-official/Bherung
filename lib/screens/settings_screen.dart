import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final List<Product> products;
  final String storeName;
  final StoreProfile storeProfile;
  final ValueChanged<String>? onStoreNameChanged;
  final ValueChanged<StoreProfile>? onStoreProfileChanged;
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.products,
    this.storeName = 'Bherung',
    this.storeProfile = const StoreProfile(),
    this.onStoreNameChanged,
    this.onStoreProfileChanged,
    required this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  final AppsScriptService _appsScriptService = AppsScriptService();

  // Link Template Master "Make a Copy" untuk Pembeli Toko
  static const String templateCopyUrl =
      'https://docs.google.com/spreadsheets/d/1k6MIzg_1atT9sp_zPG4LzQOPVe4GC3ctb8GOV95Wyvc/copy';

  late TabController _tabController;

  late final TextEditingController _inputController;
  late final TextEditingController _storeNameController;
  late final TextEditingController _storeTaglineController;
  late final TextEditingController _startingCashController;
  late final TextEditingController _qrisNameController;
  late final TextEditingController _qrisNmidController;

  late List<BankAccount> _bankAccounts;

  bool _isTesting = false;
  bool _isFullSyncing = false;
  String? _statusMessage;
  bool _isStatusSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _storeNameController = TextEditingController(text: widget.storeProfile.name.isNotEmpty ? widget.storeProfile.name : widget.storeName);
    _storeTaglineController = TextEditingController(text: widget.storeProfile.tagline);
    _startingCashController = TextEditingController(text: widget.storeProfile.defaultStartingCash.toInt().toString());
    _qrisNameController = TextEditingController(text: widget.storeProfile.qrisName);
    _qrisNmidController = TextEditingController(text: widget.storeProfile.qrisNmid);
    _bankAccounts = List.from(widget.storeProfile.bankAccounts);

    _inputController = TextEditingController(
      text: _appsScriptService.rawInput.isNotEmpty
          ? _appsScriptService.rawInput
          : _appsScriptService.spreadsheetId,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _storeNameController.dispose();
    _storeTaglineController.dispose();
    _startingCashController.dispose();
    _qrisNameController.dispose();
    _qrisNmidController.dispose();
    super.dispose();
  }

  void _saveProfileChanges() {
    final updatedProfile = StoreProfile(
      name: _storeNameController.text.trim().isEmpty ? 'Bherung' : _storeNameController.text.trim(),
      tagline: _storeTaglineController.text.trim().isEmpty ? '24 JAM' : _storeTaglineController.text.trim(),
      qrisName: _qrisNameController.text.trim(),
      qrisNmid: _qrisNmidController.text.trim(),
      defaultStartingCash: double.tryParse(_startingCashController.text.replaceAll('.', '').replaceAll(',', '')) ?? 200000,
      bankAccounts: _bankAccounts,
    );

    InventoryStorageService().saveStoreProfile(updatedProfile);

    if (widget.onStoreNameChanged != null) {
      widget.onStoreNameChanged!(updatedProfile.name);
    }
    if (widget.onStoreProfileChanged != null) {
      widget.onStoreProfileChanged!(updatedProfile);
    }
    widget.onDataChanged();
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

  // 1 Tombol Pintar Sinkronisasi Penuh Toko (Kirim Offline + Tarik Katalog Resmi)
  Future<void> _handleFullSync() async {
    setState(() {
      _isFullSyncing = true;
      _statusMessage = null;
    });

    // 1. Kirim antrean transaksi offline jika ada
    int flushedCount = 0;
    if (_appsScriptService.offlineQueueCount > 0) {
      flushedCount = await _appsScriptService.flushOfflineQueue();
    }

    // 2. Tarik katalog produk resmi & data toko dari Spreadsheet
    final syncResult = await _appsScriptService.syncAllDataFromSpreadsheet();

    if (!mounted) return;
    setState(() {
      _isFullSyncing = false;
    });

    if (syncResult.success) {
      if (syncResult.products != null) {
        widget.products.clear();
        widget.products.addAll(syncResult.products!);
        await InventoryStorageService().saveProducts(widget.products);
      }
      widget.onDataChanged();

      setState(() {
        _isStatusSuccess = true;
        final productCount = syncResult.products?.length ?? widget.products.length;
        _statusMessage = 'Sinkronisasi berhasil! $productCount produk resmi toko terhubung'
            '${flushedCount > 0 ? " & $flushedCount antrean offline terkirim." : "."}';
      });
    } else {
      setState(() {
        _isStatusSuccess = false;
        _statusMessage = syncResult.message;
      });
    }
  }

  // Muat Data Demo Produk untuk Simulator / Uji Coba
  Future<void> _handleLoadDemoProducts() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.science_rounded, color: AppTheme.primaryTeal, size: 22),
            SizedBox(width: 8),
            Text('Muat Data Demo Toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Aplikasi akan memuat 17 produk sembako & rokok contoh untuk mode uji coba transaksi. Lanjutkan?',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
            child: const Text('Ya, Muat Data Demo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final demoList = await InventoryStorageService().loadDemoProducts();
      widget.products.clear();
      widget.products.addAll(demoList);
      widget.onDataChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil memuat ${demoList.length} produk demo ke etalase toko!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
      setState(() {});
    }
  }

  // Reset & Kosongkan Data Lokal Toko
  Future<void> _handleResetLocalStore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 22),
            SizedBox(width: 8),
            Text('Kosongkan Data Lokal Toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
          ],
        ),
        content: const Text(
          'Seluruh produk lokal, histori mutasi, dan catatan shift yang tersimpan di HP ini akan dikosongkan kembali ke kondisi awal bersih. Data di Google Spreadsheet Anda tetap aman.\n\nLanjutkan reset?',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: const Text('Ya, Kosongkan Data'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await InventoryStorageService().clearAllProducts();
      widget.products.clear();
      widget.onDataChanged();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Katalog lokal telah dikosongkan. Siap untuk sinkronisasi resmi Spreadsheet.'),
          backgroundColor: AppTheme.primaryDark,
        ),
      );
      setState(() {});
    }
  }

  void _openAddOrEditBankDialog([BankAccount? existing, int? index]) {
    final nameCtrl = TextEditingController(text: existing?.bankName ?? 'BCA');
    final numCtrl = TextEditingController(text: existing?.accountNumber ?? '');
    final holderCtrl = TextEditingController(text: existing?.accountHolder ?? _storeNameController.text);

    final List<String> popularBanks = ['BCA', 'BRI', 'Mandiri', 'BNI', 'BSI', 'CIMB', 'Permata', 'DANA', 'GoPay', 'OVO'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: AppTheme.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                existing == null ? 'Tambah Rekening Bank' : 'Edit Rekening Bank',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Nama Bank / E-Wallet:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: popularBanks.map((b) {
                    final isSel = nameCtrl.text.toUpperCase() == b.toUpperCase();
                    return ChoiceChip(
                      label: Text(b, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? Colors.white : AppTheme.textDark)),
                      selected: isSel,
                      selectedColor: AppTheme.primaryTeal,
                      onSelected: (val) {
                        setDialogState(() => nameCtrl.text = b);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Bank / E-Wallet Lainnya',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: numCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Rekening / No. HP E-Wallet',
                    hintText: 'cth: 88301928301',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: holderCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Atas Nama (Pemilik Rekening)',
                    hintText: 'cth: Bherung / Toko Sembako',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () {
                if (numCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor rekening tidak boleh kosong!')),
                  );
                  return;
                }
                final newAccount = BankAccount(
                  bankName: nameCtrl.text.trim().isEmpty ? 'BCA' : nameCtrl.text.trim(),
                  accountNumber: numCtrl.text.trim(),
                  accountHolder: holderCtrl.text.trim().isEmpty ? _storeNameController.text : holderCtrl.text.trim(),
                );

                setState(() {
                  if (index != null && index >= 0 && index < _bankAccounts.length) {
                    _bankAccounts[index] = newAccount;
                  } else {
                    _bankAccounts.add(newAccount);
                  }
                });
                _saveProfileChanges();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan Rekening'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Pengaturan Sistem & Toko',
          style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGold,
          indicatorWeight: 3,
          labelColor: AppTheme.goldAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
          tabs: const [
            Tab(icon: Icon(Icons.table_chart_rounded, size: 16), text: 'Google Sheets'),
            Tab(icon: Icon(Icons.storefront_rounded, size: 16), text: 'Profil Toko & Shift'),
            Tab(icon: Icon(Icons.payment_rounded, size: 16), text: 'QRIS & Rekening'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildCloudSyncTab(),
            _buildStoreProfileTab(),
            _buildPaymentMethodsTab(),
          ],
        ),
      ),
    );
  }

  // TAB 1: Google Sheets & Sync
  Widget _buildCloudSyncTab() {
    final isConnected = _appsScriptService.isConnected;

    return ListView(
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
                                content: Text('Link Template disalin ke Clipboard!'),
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

        // 4. Sinkronisasi Penuh Database Toko (1 Tombol Otomatis)
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
              const Row(
                children: [
                  Icon(Icons.sync_alt_rounded, color: AppTheme.primaryTeal, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Sinkronisasi Database Toko:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Menarik seluruh katalog produk resmi dari Spreadsheet dan otomatis mengirimkan antrean nota transaksi offline.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (!isConnected || _isFullSyncing) ? null : _handleFullSync,
                  icon: _isFullSyncing
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.sync_rounded, size: 16),
                  label: Text(
                    _isFullSyncing ? 'Sedang Menyinkronkan Database...' : 'Sinkronisasi Penuh Database Toko',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Mode Uji Coba & Demo (Khusus di HP / Tanpa Cloud)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.science_outlined, color: AppTheme.textDark, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Mode Uji Coba & Demo (Lokal HP Saja)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Data demo hanya disimpan di memori HP untuk latihan kasir, dan TIDAK AKAN dikirim ke Google Spreadsheet toko.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleLoadDemoProducts,
                      icon: const Icon(Icons.play_arrow_outlined, size: 14, color: AppTheme.primaryTeal),
                      label: const Text('Muat Demo di HP', style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleResetLocalStore,
                      icon: const Icon(Icons.delete_sweep_outlined, size: 14, color: AppTheme.dangerRed),
                      label: const Text('Reset Data Demo', style: TextStyle(fontSize: 11, color: AppTheme.dangerRed, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.dangerRed),
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
      ],
    );
  }

  // TAB 2: Profil Toko & Shift
  Widget _buildStoreProfileTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Identitas Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _storeNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Toko Kelontong / POS',
                  hintText: 'cth: Bherung / Toko Sumber Rejeki',
                  prefixIcon: Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryTeal),
                  isDense: true,
                ),
                onChanged: (_) => _saveProfileChanges(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _storeTaglineController,
                decoration: const InputDecoration(
                  labelText: 'Tagline Toko',
                  hintText: 'cth: 24 JAM / Sembako Lengkap & Murah',
                  prefixIcon: Icon(Icons.label_important_outline_rounded, size: 18, color: AppTheme.primaryTeal),
                  isDense: true,
                ),
                onChanged: (_) => _saveProfileChanges(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Operasional Shift & Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
              const SizedBox(height: 10),
              TextField(
                controller: _startingCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Modal Kas Awal Laci Kasir Default (Rp)',
                  hintText: '200000',
                  prefixIcon: Icon(Icons.payments_rounded, size: 18, color: AppTheme.primaryTeal),
                  isDense: true,
                ),
                onChanged: (_) => _saveProfileChanges(),
              ),
              const SizedBox(height: 6),
              const Text(
                'Nilai ini akan otomatis menjadi saldo awal saat kasir membuka serah terima shift baru.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 3: QRIS & Rekening Bank Toko
  Widget _buildPaymentMethodsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // QRIS Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryTeal, size: 20),
                  SizedBox(width: 8),
                  Text('Konfigurasi QRIS Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qrisNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Merchant QRIS',
                  hintText: 'cth: QRIS Toko Madura Bherung',
                  isDense: true,
                ),
                onChanged: (_) => _saveProfileChanges(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qrisNmidController,
                decoration: const InputDecoration(
                  labelText: 'Nomor NMID QRIS',
                  hintText: 'cth: ID1020304050607',
                  isDense: true,
                ),
                onChanged: (_) => _saveProfileChanges(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Rekening Bank Section
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_rounded, color: AppTheme.primaryTeal, size: 20),
                      SizedBox(width: 8),
                      Text('Rekening Bank / E-Wallet Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openAddOrEditBankDialog(),
                    icon: const Icon(Icons.add_rounded, size: 14),
                    label: const Text('Tambah', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_bankAccounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text('Belum ada rekening bank. Klik "Tambah" untuk menambahkan rekening toko.', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _bankAccounts.length,
                  separatorBuilder: (c, i) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final acc = _bankAccounts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryDark,
                        child: Text(
                          acc.bankName.isNotEmpty ? acc.bankName.substring(0, acc.bankName.length > 3 ? 3 : acc.bankName.length).toUpperCase() : 'BANK',
                          style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                      title: Text('${acc.accountNumber} (${acc.bankName})', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      subtitle: Text('a/n ${acc.accountHolder}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryTeal),
                            onPressed: () => _openAddOrEditBankDialog(acc, index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                            onPressed: () {
                              setState(() {
                                _bankAccounts.removeAt(index);
                              });
                              _saveProfileChanges();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }
}
