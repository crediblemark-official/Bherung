import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/branch.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';
import 'user_guide_screen.dart';

class SettingsScreen extends StatefulWidget {
  final List<Product> products;
  final String storeName;
  final StoreProfile storeProfile;
  final AppUser? currentUser;
  final ValueChanged<String>? onStoreNameChanged;
  final ValueChanged<StoreProfile>? onStoreProfileChanged;
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.products,
    this.storeName = 'Bherung',
    this.storeProfile = const StoreProfile(),
    this.currentUser,
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
  late final TextEditingController _appsScriptUrlController;
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

  bool get _isOwner => widget.currentUser?.isOwner ?? false;
  bool _isMultiBranchEnabled = false;
  List<Branch> _branches = [];
  String _activeBranchId = 'br-main';
  bool _isLoadingBranches = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: (widget.currentUser?.isOwner ?? false) ? 4 : 3, vsync: this);
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

    _appsScriptUrlController = TextEditingController(
      text: _appsScriptService.webAppUrl,
    );

    _loadBranchSettings();
  }

  List<AppUser> _users = [];

  Future<void> _loadBranchSettings() async {
    final storage = InventoryStorageService();
    final enabled = await storage.loadMultiBranchEnabled();
    final branches = await storage.loadBranches(storeName: widget.storeName);
    final activeId = await storage.loadActiveBranchId();
    final users = await storage.loadUsers();

    if (mounted) {
      setState(() {
        _isMultiBranchEnabled = enabled;
        _branches = branches;
        _activeBranchId = activeId;
        _users = users;
        _isLoadingBranches = false;
      });
    }
  }

  Future<void> _toggleMultiBranch(bool value) async {
    final storage = InventoryStorageService();
    await storage.saveMultiBranchEnabled(value);
    setState(() {
      _isMultiBranchEnabled = value;
    });
    widget.onDataChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Fitur Multi Cabang AKTIF. Anda dapat mengelola cabang toko di bawah ini.'
                : 'Fitur Multi Cabang DINONAKTIFKAN. Mode toko tunggal aktif.',
          ),
          backgroundColor: value ? AppTheme.successGreen : AppTheme.primaryDark,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setActiveBranch(String branchId) async {
    final storage = InventoryStorageService();
    await storage.saveActiveBranchId(branchId);
    setState(() {
      _activeBranchId = branchId;
    });
    widget.onDataChanged();
    if (mounted) {
      final active = _branches.firstWhere((b) => b.id == branchId, orElse: () => _branches.first);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cabang aktif perangkat disetel ke: ${active.name}'),
          backgroundColor: AppTheme.primaryTeal,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _appsScriptUrlController.dispose();
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
    final customUrl = _appsScriptUrlController.text.trim();

    if (input.isEmpty && customUrl.isEmpty) {
      setState(() {
        _statusMessage = 'Harap masukkan ID/Link Spreadsheet atau URL Web App Apps Script toko Anda.';
        _isStatusSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    await _appsScriptService.setSpreadsheetAndWebApp(
      spreadsheetInput: input,
      webAppUrlInput: customUrl,
    );

    final res = await _appsScriptService.testConnection(input.isNotEmpty ? input : customUrl);

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
    _appsScriptUrlController.clear();
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
          tabs: [
            const Tab(icon: Icon(Icons.table_chart_rounded, size: 16), text: 'Google Sheets'),
            const Tab(icon: Icon(Icons.storefront_rounded, size: 16), text: 'Profil Toko & Jaga'),
            const Tab(icon: Icon(Icons.payment_rounded, size: 16), text: 'QRIS & Rekening'),
            if (_isOwner)
              const Tab(icon: Icon(Icons.store_mall_directory_rounded, size: 16), text: 'Multi Cabang'),
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
            if (_isOwner)
              _buildMultiBranchTab(),
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'ID: ${_appsScriptService.spreadsheetId.isNotEmpty ? _appsScriptService.spreadsheetId : "Custom Apps Script URL"}'
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
                      'Pastikan akses berbagi spreadsheet diatur "Editor", lalu salin link/ID spreadsheet Anda ke bawah:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 3. Form Input Link/ID Spreadsheet & URL Web App Apps Script
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.table_chart_rounded, color: AppTheme.primaryTeal, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Link atau ID Google Spreadsheet Toko:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _inputController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Tempel link spreadsheet (https://docs.google.com/...)',
                  hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primaryTeal, size: 18),
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
              const SizedBox(height: 12),

              // Input 2: URL Web App Google Apps Script (Custom Deployment)
              const Row(
                children: [
                  Icon(Icons.code_rounded, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'URL Web App Google Apps Script (Custom Deployment):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Opsional. Jika Anda mendeploy script sendiri dari Google Spreadsheet akun pribadi Anda.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _appsScriptUrlController,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'https://script.google.com/macros/s/.../exec',
                  hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  prefixIcon: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 18),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded, size: 16),
                    tooltip: 'Tempel dari Clipboard',
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _appsScriptUrlController.text = data!.text!;
                      }
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),

              // Action Buttons: Stacked Full-Width (Rapi & Tidak Terpotong)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _handleTestConnection,
                  icon: _isTesting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark))
                      : const Icon(Icons.cable_rounded, size: 18),
                  label: Text(
                    _isTesting ? 'Memeriksa Koneksi Database...' : 'Hubungkan & Simpan Database',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.primaryDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    elevation: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserGuideScreen()),
                    );
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Buka Buku Panduan Setup & Deploy Database',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    backgroundColor: const Color(0xFFEFF6FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
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
        const SizedBox(height: 14),

        // Daftar Kasir & Penugasan Cabang
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penugasan Kasir & Cabang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                      Text('Atur cabang tugas masing-masing penjaga toko', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    ],
                  ),
                  if (_branches.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 22),
                      tooltip: 'Tambah Kasir Baru',
                      onPressed: () => _showQuickCreateStaffDialog(context, _branches.first),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (_users.where((u) => !u.isOwner).isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.badge_outlined, size: 28, color: AppTheme.textSubtle),
                      SizedBox(height: 6),
                      Text('Belum ada akun penjaga toko / kasir.', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      Text('Tambahkan kasir untuk mengatur penugasan cabang.', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                    ],
                  ),
                )
              else
                ..._users.where((u) => !u.isOwner).map((staff) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.12),
                          child: const Icon(Icons.person_rounded, color: AppTheme.primaryTeal, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staff.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              const SizedBox(height: 2),
                              Text(
                                (staff.branchName != null && staff.branchName!.isNotEmpty)
                                    ? '📍 Cabang: ${staff.branchName}'
                                    : '⚪ Belum Ditugaskan ke Cabang Mana Pun',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: (staff.branchName != null && staff.branchName!.isNotEmpty)
                                      ? const Color(0xFF0F766E)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_branches.isNotEmpty)
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _branches.any((b) => b.id == staff.branchId) ? staff.branchId : null,
                              hint: const Text('Pilih Cabang', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('❌ Lepas Tugas Cabang', style: TextStyle(fontSize: 11, color: AppTheme.dangerRed)),
                                ),
                                ..._branches.map((b) => DropdownMenuItem<String>(
                                      value: b.id,
                                      child: Text(b.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    )),
                              ],
                              onChanged: (newBranchId) async {
                                final userIndex = _users.indexWhere((u) => u.id == staff.id);
                                if (userIndex != -1) {
                                  if (newBranchId == null || newBranchId.isEmpty) {
                                    _users[userIndex] = staff.copyWith(branchId: '', branchName: '');
                                  } else {
                                    final branch = _branches.firstWhere((b) => b.id == newBranchId);
                                    _users[userIndex] = staff.copyWith(branchId: branch.id, branchName: branch.name);
                                  }
                                  await InventoryStorageService().saveUsers(_users);
                                  setState(() {});
                                  widget.onDataChanged();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Penugasan kasir "${staff.name}" berhasil diperbarui.'),
                                        backgroundColor: AppTheme.successGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                }),
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

  // TAB 4: Multi Cabang (Khusus Pemilik Toko / Owner)
  Widget _buildMultiBranchTab() {
    if (_isLoadingBranches) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryGold),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      children: [
        // 1. Toggle Switch Card Utama
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isMultiBranchEnabled ? AppTheme.primaryGold.withValues(alpha: 0.6) : AppTheme.borderColor,
              width: _isMultiBranchEnabled ? 1.5 : 1.0,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      gradient: _isMultiBranchEnabled ? AppTheme.goldGradient : null,
                      color: _isMultiBranchEnabled ? null : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.store_mall_directory_rounded,
                      color: _isMultiBranchEnabled ? AppTheme.primaryDark : AppTheme.textMuted,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Apakah Toko Memiliki Banyak Cabang?',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMultiBranchEnabled
                              ? 'Fitur Aktif • Siap mencatat penjualan per cabang'
                              : 'Fitur Mati • Beroperasi mode 1 toko biasa',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isMultiBranchEnabled ? const Color(0xFF047857) : AppTheme.textMuted,
                            fontWeight: _isMultiBranchEnabled ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isMultiBranchEnabled,
                    activeTrackColor: AppTheme.primaryGold.withValues(alpha: 0.5),
                    onChanged: (val) => _toggleMultiBranch(val),
                  ),
                ],
              ),
              const Divider(height: 20),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isMultiBranchEnabled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isMultiBranchEnabled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isMultiBranchEnabled ? Icons.check_circle_rounded : Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: _isMultiBranchEnabled ? const Color(0xFF16A34A) : AppTheme.primaryGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isMultiBranchEnabled
                          ? '💡 Setiap HP kasir dapat disetel bertugas di cabang masing-masing. Transaksi nota, uang kas, dan laporan shift otomatis tersimpan rapi sesuai cabang.'
                          : '💡 Jika Anda hanya punya 1 warung/toko, biarkan opsi ini mati agar tampilan kasir tetap simpel & cepat.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _isMultiBranchEnabled ? const Color(0xFF166534) : AppTheme.textDark,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (_isMultiBranchEnabled) ...[
          // 2. Card Cabang yang Sedang Dipakai di HP Ini
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.4)),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.phone_android_rounded, color: AppTheme.primaryTeal, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'HP / Tablet Ini Dipakai di Cabang Mana?',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih cabang tempat perangkat kasir ini sedang beroperasi:',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryTeal),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _branches.any((b) => b.id == _activeBranchId) ? _activeBranchId : _branches.first.id,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryTeal),
                      items: _branches.map((b) {
                        return DropdownMenuItem<String>(
                          value: b.id,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: b.isMain ? AppTheme.primaryGold.withValues(alpha: 0.2) : const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  b.code.isNotEmpty ? b.code : 'CB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: b.isMain ? const Color(0xFFB45309) : AppTheme.textDark,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b.name,
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (b.isMain)
                                const Text(' (Pusat)', style: TextStyle(fontSize: 11, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newId) {
                        if (newId != null) {
                          _setActiveBranch(newId);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Header & Tombol Tambah Cabang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daftar Cabang Toko (${_branches.length})',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                  ),
                  const Text('Kelola seluruh cabang gerai toko Anda', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditBranchDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tambah Cabang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 4. List Cabang
          ..._branches.map((b) {
            final isCurrentActive = b.id == _activeBranchId;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCurrentActive ? AppTheme.primaryTeal : AppTheme.borderColor,
                  width: isCurrentActive ? 1.5 : 1.0,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: b.isMain
                            ? AppTheme.primaryGold.withValues(alpha: 0.15)
                            : AppTheme.primaryTeal.withValues(alpha: 0.12),
                        child: Icon(
                          b.isMain ? Icons.store_rounded : Icons.storefront_rounded,
                          color: b.isMain ? const Color(0xFFB45309) : AppTheme.primaryTeal,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    b.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (b.code.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: Text(
                                      b.code,
                                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (b.isMain)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFFDE68A)),
                                    ),
                                    child: const Text(
                                      '⭐ CABANG UTAMA (PUSAT)',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                                    ),
                                  ),
                                if (isCurrentActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCCFBF1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF99F6E4)),
                                    ),
                                    child: const Text(
                                      '📱 AKTIF DI HP INI',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                                    ),
                                  ),
                                Builder(
                                  builder: (context) {
                                    final assignedStaff = _users.where((u) => !u.isOwner && u.branchId == b.id).toList();
                                    return InkWell(
                                      onTap: () => _showAssignStaffToBranchDialog(b),
                                      borderRadius: BorderRadius.circular(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: assignedStaff.isNotEmpty ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: assignedStaff.isNotEmpty ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                assignedStaff.isNotEmpty
                                                    ? '👤 Penjaga: ${assignedStaff.map((u) => u.name).join(", ")}'
                                                    : '👤 Belum ada penjaga',
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                  color: assignedStaff.isNotEmpty ? const Color(0xFF166534) : const Color(0xFF92400E),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 3),
                                            Icon(
                                              Icons.edit_rounded,
                                              size: 10,
                                              color: assignedStaff.isNotEmpty ? const Color(0xFF166534) : const Color(0xFF92400E),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Color(0xFFD97706)),
                            tooltip: 'Tugaskan Penjaga di Cabang Ini',
                            onPressed: () => _showAssignStaffToBranchDialog(b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryTeal),
                            tooltip: 'Ubah Data Cabang',
                            onPressed: () => _showAddOrEditBranchDialog(b),
                          ),
                          if (!b.isMain && _branches.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                              tooltip: 'Hapus Cabang',
                              onPressed: () => _deleteBranch(b),
                            ),
                        ],
                      ),
                    ],
                  ),
                  if (b.address.isNotEmpty || b.phone.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    if (b.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                b.address,
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (b.phone.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            b.phone,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                  ],
                  if (!isCurrentActive) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _setActiveBranch(b.id),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                        label: const Text('Gunakan Cabang Ini di HP Kasir Ini', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryTeal,
                          side: const BorderSide(color: AppTheme.primaryTeal),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  void _showAddOrEditBranchDialog([Branch? existing]) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? (isEdit ? '' : 'CB0${_branches.length + 1}'));
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    bool isMainVal = existing?.isMain ?? (_branches.isEmpty);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_note_rounded : Icons.add_business_rounded,
                color: AppTheme.primaryGold,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isEdit ? 'Ubah Data Cabang' : 'Tambah Cabang Baru',
                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Cabang
                const Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 14, color: AppTheme.primaryTeal),
                    SizedBox(width: 4),
                    Text('Nama Cabang Toko *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Cabang 2 - Kalimalang',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // Kode Cabang
                const Row(
                  children: [
                    Icon(Icons.tag_rounded, size: 14, color: AppTheme.primaryTeal),
                    SizedBox(width: 4),
                    Text('Kode Singkat Cabang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: codeCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: CB02, KLM, PUSAT',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // Alamat
                const Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryTeal),
                    SizedBox(width: 4),
                    Text('Alamat Cabang (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                    hintText: 'Contoh: Jl. Raya Kalimalang No. 12',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 10),

                // No HP
                const Row(
                  children: [
                    Icon(Icons.phone_outlined, size: 14, color: AppTheme.primaryTeal),
                    SizedBox(width: 4),
                    Text('No. HP / WA Cabang (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Contoh: 0812-3456-7890',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 12),

                // Checkbox Is Main
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: isMainVal,
                      activeColor: AppTheme.primaryGold,
                      title: const Text(
                        'Jadikan Cabang Utama (Pusat)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      subtitle: const Text(
                        'Toko rujukan utama untuk profil kasir',
                        style: TextStyle(fontSize: 10.5, color: Color(0xFFB45309)),
                      ),
                      onChanged: (val) {
                        setDlgState(() {
                          isMainVal = val ?? false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cleanName = nameCtrl.text.trim();
                if (cleanName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama cabang wajib diisi!'), backgroundColor: AppTheme.dangerRed),
                  );
                  return;
                }

                final cleanCode = codeCtrl.text.trim().toUpperCase();
                final cleanAddress = addressCtrl.text.trim();
                final cleanPhone = phoneCtrl.text.trim();

                List<Branch> updatedList = List.from(_branches);

                if (isMainVal) {
                  // Hapus flag isMain dari cabang lain
                  updatedList = updatedList.map((b) => b.copyWith(isMain: false)).toList();
                }

                if (isEdit) {
                  final idx = updatedList.indexWhere((b) => b.id == existing.id);
                  if (idx != -1) {
                    updatedList[idx] = existing.copyWith(
                      name: cleanName,
                      code: cleanCode,
                      address: cleanAddress,
                      phone: cleanPhone,
                      isMain: isMainVal,
                    );
                  }
                } else {
                  final newBranch = Branch(
                    id: 'br-${DateTime.now().millisecondsSinceEpoch}',
                    name: cleanName,
                    code: cleanCode.isNotEmpty ? cleanCode : 'CB0${updatedList.length + 1}',
                    address: cleanAddress,
                    phone: cleanPhone,
                    isMain: isMainVal || updatedList.isEmpty,
                    isActive: true,
                  );
                  updatedList.add(newBranch);
                }

                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(ctx);

                await InventoryStorageService().saveBranches(updatedList);
                setState(() {
                  _branches = updatedList;
                });
                widget.onDataChanged();

                nav.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'Data cabang berhasil diperbarui.' : 'Cabang baru "$cleanName" berhasil ditambahkan!'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
              child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Cabang'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteBranch(Branch branch) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 22),
            SizedBox(width: 8),
            Text('Hapus Cabang Toko', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.dangerRed)),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus cabang "${branch.name}"?\n\nData produk dan catatan riwayat lama tidak akan terhapus.',
          style: const TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: const Text('Ya, Hapus Cabang'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final updatedList = _branches.where((b) => b.id != branch.id).toList();
      if (_activeBranchId == branch.id) {
        _activeBranchId = updatedList.first.id;
        await InventoryStorageService().saveActiveBranchId(_activeBranchId);
      }
      await InventoryStorageService().saveBranches(updatedList);
      setState(() {
        _branches = updatedList;
      });
      widget.onDataChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cabang "${branch.name}" telah dihapus.'),
            backgroundColor: AppTheme.primaryDark,
          ),
        );
      }
    }
  }

  // Dialog Khusus: Tugaskan Penjaga Toko / Kasir ke Cabang Ini
  void _showAssignStaffToBranchDialog(Branch branch) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final nonOwnerUsers = _users.where((u) => !u.isOwner).toList();
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_rounded, color: AppTheme.primaryTeal, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Atur Penjaga Cabang',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                      Text(
                        branch.name,
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF166534)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Pilih kasir yang ditugaskan di cabang ini. Penjaga hanya bisa login di cabang yang telah ditentukan (1 cabang 1 penjaga).',
                              style: TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (nonOwnerUsers.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const Column(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 36, color: AppTheme.textSubtle),
                            SizedBox(height: 8),
                            Text(
                              'Belum ada akun penjaga toko / kasir.',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tambahkan kasir baru di bawah untuk ditugaskan di cabang ini.',
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...nonOwnerUsers.map((user) {
                        final isAssignedToThis = user.branchId == branch.id;
                        final isAssignedToOther = user.branchId != null && user.branchId!.isNotEmpty && user.branchId != branch.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isAssignedToThis ? const Color(0xFFF0FDF4) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isAssignedToThis ? const Color(0xFF86EFAC) : AppTheme.borderColor,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              dense: true,
                              value: isAssignedToThis,
                              activeColor: AppTheme.primaryTeal,
                              title: Text(
                                user.name,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              subtitle: Text(
                                isAssignedToThis
                                    ? '✅ Bertugas di cabang ini'
                                    : (isAssignedToOther
                                        ? '⚠️ Saat ini di ${user.branchName ?? "cabang lain"}'
                                        : '⚪ Belum ada penugasan cabang'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isAssignedToThis
                                      ? const Color(0xFF15803D)
                                      : (isAssignedToOther ? const Color(0xFFD97706) : AppTheme.textMuted),
                                ),
                              ),
                              onChanged: (checked) {
                                setDlgState(() {
                                  final userIndex = _users.indexWhere((u) => u.id == user.id);
                                  if (userIndex != -1) {
                                    if (checked == true) {
                                      _users[userIndex] = user.copyWith(
                                        branchId: branch.id,
                                        branchName: branch.name,
                                      );
                                    } else {
                                      _users[userIndex] = user.copyWith(
                                        branchId: '',
                                        branchName: '',
                                      );
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await _showQuickCreateStaffDialog(ctx, branch);
                        setDlgState(() {});
                      },
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('+ Tambah Akun Kasir Baru', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: const BorderSide(color: AppTheme.primaryTeal),
                        minimumSize: const Size(double.infinity, 38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await InventoryStorageService().saveUsers(_users);
                  setState(() {});
                  widget.onDataChanged();
                  if (ctx.mounted) Navigator.pop(ctx);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Penugasan penjaga untuk ${branch.name} berhasil disimpan!'),
                      backgroundColor: AppTheme.successGreen,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Penugasan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Tambah Cepat Akun Kasir Langsung Ditugaskan ke Cabang
  Future<void> _showQuickCreateStaffDialog(BuildContext parentCtx, Branch branch) async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryTeal, size: 20),
            SizedBox(width: 8),
            Text('Tambah Kasir Baru', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Akan langsung ditugaskan di ${branch.name}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryTeal, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Kasir / Penjaga',
                hintText: 'Contoh: Ahmad, Siti',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'No. HP (Opsional)',
                hintText: 'Contoh: 0812-3456-7890',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'PIN 4-Digit Kasir',
                counterText: '',
                hintText: '5678',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final pin = pinCtrl.text.trim().isEmpty ? '5678' : pinCtrl.text.trim();
              final newUser = AppUser(
                id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                phone: phoneCtrl.text.trim(),
                role: UserRoleType.staff,
                pin: pin,
                branchId: branch.id,
                branchName: branch.name,
              );
              setState(() {
                _users.add(newUser);
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
