import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';
import 'scanner_screen.dart';

class ShiftHandoverScreen extends StatefulWidget {
  final String currentCashier;
  final double currentShiftSales;
  final int currentShiftTransactions;
  final List<Product> products;
  final List<AppUser> users;
  final AppUser? initialIncomingUser;
  final double defaultStartingCash;
  final String storeName;
  final double previousShiftSales;
  final String? branchId;
  final String? branchName;
  final Function(ShiftRecord shiftRecord, AppUser? nextUser, List<Product> updatedProducts) onShiftHandoverCompleted;

  const ShiftHandoverScreen({
    super.key,
    required this.currentCashier,
    required this.currentShiftSales,
    required this.currentShiftTransactions,
    required this.products,
    this.users = const [],
    this.initialIncomingUser,
    this.defaultStartingCash = 200000,
    this.storeName = 'Bherung',
    this.previousShiftSales = 0,
    this.branchId,
    this.branchName,
    required this.onShiftHandoverCompleted,
  });

  @override
  State<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends State<ShiftHandoverScreen> {
  final TextEditingController _nextCashierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _auditControllers = {};
  final Map<String, int> _initialStocksMap = {}; // Stok Lama Baseline Terkunci
  
  late List<Product> _allProducts;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  AppUser? _selectedNextUser;
  bool _isChangingGuard = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _allProducts = List.from(widget.products);
    for (final p in _allProducts) {
      _auditControllers[p.id] = TextEditingController(text: p.stock.toString());
    }

    _selectedNextUser = widget.initialIncomingUser;
    if (_selectedNextUser != null) {
      _isChangingGuard = true;
      _nextCashierController.text = _selectedNextUser!.name;
    } else {
      _nextCashierController.text = widget.currentCashier;
    }

    _loadLockedBaselineStocks();
  }

  Future<void> _loadLockedBaselineStocks() async {
    final storage = InventoryStorageService();
    final savedBaseline = await storage.loadBaselineStocks();
    
    if (savedBaseline.isNotEmpty) {
      _initialStocksMap.addAll(savedBaseline);
    } else {
      // Inisialisasi awal jika belum ada baseline tersimpan
      for (final p in _allProducts) {
        _initialStocksMap[p.id] = p.stock;
      }
      await storage.saveBaselineStocks(_initialStocksMap);
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nextCashierController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    for (final c in _auditControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _selectNextUser(AppUser user) {
    setState(() {
      _selectedNextUser = user;
      _nextCashierController.text = user.name;
    });
  }

  int _getPhysicalStock(Product p) {
    final text = _auditControllers[p.id]?.text.trim() ?? '';
    return int.tryParse(text) ?? p.stock;
  }

  int _getInitialStock(Product p) {
    return _initialStocksMap[p.id] ?? p.stock;
  }

  void _setPhysicalStock(Product p, int newQty) {
    if (newQty < 0) newQty = 0;
    _auditControllers[p.id]?.text = newQty.toString();
    setState(() {});
  }

  void _openBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ScannerScreen(
          onBarcodeDetected: (scannedCode) {
            final codeClean = scannedCode.trim().toLowerCase();
            final matchIndex = _allProducts.indexWhere((p) => p.code.toLowerCase() == codeClean);
            if (matchIndex != -1) {
              final matchedProduct = _allProducts[matchIndex];
              setState(() {
                _searchController.text = matchedProduct.name;
                _searchQuery = matchedProduct.name;
                _selectedCategory = 'all';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Produk ditemukan: ${matchedProduct.name}'),
                  backgroundColor: AppTheme.primaryTeal,
                  duration: const Duration(seconds: 2),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Barcode "$scannedCode" tidak ditemukan.'),
                  backgroundColor: Colors.orange[800],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _finalizeSubmit() async {
    setState(() => _isSaving = true);
    final storage = InventoryStorageService();

    final List<SensitiveProductAudit> audits = [];
    final List<Product> updatedProducts = [];
    final List<StockMutation> mutations = [];
    final Map<String, int> nextContractBaselineStocks = {};

    for (final p in _allProducts) {
      final physical = _getPhysicalStock(p);
      final initial = _getInitialStock(p);
      final diff = physical - p.stock;

      audits.add(SensitiveProductAudit(
        productId: p.id,
        productName: p.name,
        initialStock: initial,
        systemStock: p.stock,
        physicalStock: physical,
        difference: diff,
        unit: p.unit,
        costPrice: p.costPrice,
        retailPrice: p.price,
      ));

      if (diff != 0) {
        mutations.add(StockMutation(
          id: 'MUT-SHIFT-${DateTime.now().millisecondsSinceEpoch}-${p.id}',
          productId: p.id,
          productName: p.name,
          type: StockMutationType.auditCorrection,
          qtyChange: diff,
          previousStock: p.stock,
          newStock: physical,
          timestamp: DateTime.now(),
          cashierName: widget.currentCashier,
          note: 'Koreksi Serah Terima Jaga (${diff > 0 ? "Surplus +$diff" : "Minus $diff"})',
          costPrice: p.costPrice,
          branchId: widget.branchId,
          branchName: widget.branchName,
        ));
      }

      // Stok fisik riil hari ini di-lock menjadi baseline "Stok Lama" bagi penjaga baru
      nextContractBaselineStocks[p.id] = physical;
      updatedProducts.add(p.copyWith(stock: physical));
    }

    final AppUser? nextUser = _isChangingGuard ? _selectedNextUser : null;
    final String recipientName = nextUser?.name ?? widget.currentCashier;

    final shiftRecord = ShiftRecord(
      id: 'LAPORAN-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: widget.currentCashier,
      shiftName: 'Laporan ${widget.storeName}',
      startTime: DateTime.now().subtract(const Duration(hours: 24)),
      endTime: DateTime.now(),
      startingCashDrawer: widget.defaultStartingCash,
      systemCashSales: widget.currentShiftSales,
      systemQrisSales: 0,
      systemKasbonSales: 0,
      totalSystemSales: widget.currentShiftSales,
      physicalCashCounted: widget.defaultStartingCash + widget.currentShiftSales,
      cashDifference: 0,
      stockAudits: audits,
      handoverNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      nextCashierName: recipientName,
      transactionCount: widget.currentShiftTransactions,
      branchId: widget.branchId,
      branchName: widget.branchName,
    );

    // 1. Simpan Baseline Stok Lama Terkunci Baru HANYA jika serah terima pergantian penjaga resmi
    if (_isChangingGuard && nextUser != null) {
      await storage.saveBaselineStocks(nextContractBaselineStocks);
    }

    // 2. Simpan master produk & mutasi stok
    await storage.saveProducts(updatedProducts);
    if (mutations.isNotEmpty) {
      final existingMutations = await storage.loadMutations();
      existingMutations.insertAll(0, mutations);
      await storage.saveMutations(existingMutations);
    }

    // 3. Simpan riwayat serah terima
    final existingShifts = await storage.loadShifts();
    existingShifts.insert(0, shiftRecord);
    await storage.saveShifts(existingShifts);

    if (nextUser != null) {
      await storage.saveScheduledNextUser(nextUser);
    }

    // 4. Sinkronisasi ke Google Spreadsheet
    AppsScriptService().syncAllProducts(updatedProducts);
    AppsScriptService().sendShiftRecord(shiftRecord);

    widget.onShiftHandoverCompleted(shiftRecord, nextUser, updatedProducts);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextUser != null
                ? 'Serah terima disahkan! Stok fisik riil terkunci menjadi Stok Lama bagi ${nextUser.name}.'
                : 'Laporan serah terima berhasil disimpan dan stok sistem diperbarui.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(seconds: 4),
        ),
      );
      Navigator.pop(context);
    }
  }

  List<Product> get _filteredProducts {
    return _allProducts.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchCode = p.code.toLowerCase().contains(q);
        if (!matchName && !matchCode) return false;
      }

      if (_selectedCategory == 'all') return true;
      if (_selectedCategory == 'sensitive') {
        return p.isSensitiveItem ||
            p.categoryId == 'rokok' ||
            p.categoryId == 'gas_galon' ||
            p.categoryId == 'bensin' ||
            p.categoryId == 'sembako';
      }
      return p.categoryId.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    final int matchedCount = _allProducts.where((p) => _getPhysicalStock(p) == p.stock).length;
    final int diffCount = _allProducts.where((p) => _getPhysicalStock(p) != p.stock).length;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        toolbarHeight: 52,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kasir',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Icon(Icons.fact_check_rounded, color: AppTheme.primaryDark, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Serah Terima Jaga & Cekan Toko',
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Penjaga: ${widget.currentCashier} • $matchedCount Cocok / $diffCount Selisih',
                    style: const TextStyle(color: AppTheme.textSubtle, fontSize: 10.5, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryGold, size: 22),
            tooltip: 'Scan Barcode',
            onPressed: _openBarcodeScanner,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  // Banner Edukasi Alur Stok Lama Terkunci
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_clock_rounded, color: AppTheme.primaryGold, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '🔒 STOK LAMA adalah angka modal awal yang terkunci mati selama masa tugas ${widget.currentCashier}. '
                            'Saat serah terima disahkan, hasil hitung Fisik Riil hari ini otomatis di-lock menjadi Stok Lama bagi penjaga berikutnya.',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 1. Ringkasan Omzet Jaga
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.surfaceDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDark),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bar_chart_rounded, color: AppTheme.goldAccent, size: 16),
                            SizedBox(width: 6),
                            Text('Ringkasan Omzet Jaga', style: TextStyle(color: AppTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.w800)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Periode Lalu:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                                  const SizedBox(height: 3),
                                  Text(
                                    widget.previousShiftSales > 0 ? AppTheme.formatRupiah(widget.previousShiftSales) : '—',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            Container(height: 32, width: 1, color: AppTheme.borderDark),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Omzet Jaga Ini:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                                  const SizedBox(height: 3),
                                  Text(
                                    AppTheme.formatRupiah(widget.currentShiftSales),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.goldAccent),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Transaksi:', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text(
                                '${widget.currentShiftTransactions} Transaksi',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Cekan & Pencocokan Fisik Barang
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2_rounded, color: AppTheme.primaryTeal, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Pencocokan Stok Fisik Toko',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: diffCount > 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                diffCount > 0 ? '$diffCount Selisih' : 'Semua Cocok',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: diffCount > 0 ? AppTheme.dangerRed : AppTheme.successGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Cocokkan jumlah fisik riil di etalase dengan stok sistem:',
                          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),

                        // Search Bar
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 36,
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(fontSize: 12.5),
                                  decoration: InputDecoration(
                                    hintText: 'Cari produk / barcode...',
                                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                                    prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppTheme.textMuted),
                                    suffixIcon: _searchQuery.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 14),
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(() => _searchQuery = '');
                                            },
                                          )
                                        : null,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                    filled: true,
                                    fillColor: AppTheme.bgSubtle,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppTheme.borderColor)),
                                  ),
                                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: _openBarcodeScanner,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 36,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryDark,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.barcode_reader, color: AppTheme.primaryGold, size: 16),
                                    SizedBox(width: 4),
                                    Text('Scan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildCategoryChip('all', 'Semua (${_allProducts.length})'),
                              const SizedBox(width: 6),
                              _buildCategoryChip('sensitive', '⭐ Barang Rawan'),
                              const SizedBox(width: 6),
                              _buildCategoryChip('rokok', 'Rokok'),
                              const SizedBox(width: 6),
                              _buildCategoryChip('gas_galon', 'Gas & Galon'),
                              const SizedBox(width: 6),
                              _buildCategoryChip('sembako', 'Sembako'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Product List
                        if (filtered.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: const Text('Tidak ada produk yang cocok.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                          )
                        else
                          ...filtered.map((prod) {
                            final controller = _auditControllers[prod.id];
                            final physical = _getPhysicalStock(prod);
                            final initial = _getInitialStock(prod);
                            final diff = physical - prod.stock;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSubtle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: diff != 0 ? (diff < 0 ? const Color(0xFFFCA5A5) : const Color(0xFF93C5FD)) : AppTheme.borderColor,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 3,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE2E8F0),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Stok Lama: $initial ${prod.unit}',
                                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                                              ),
                                            ),
                                            Text(
                                              'Sistem: ${prod.stock} ${prod.unit}',
                                              style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                        if (diff != 0 && prod.costPrice != null && prod.costPrice! > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              'Selisih Modal: ${AppTheme.formatRupiah(diff * prod.costPrice!)}',
                                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: diff < 0 ? AppTheme.dangerRed : AppTheme.successGreen),
                                            ),
                                          )
                                        else if (diff != 0 && (prod.costPrice == null || prod.costPrice == 0))
                                          const Padding(
                                            padding: EdgeInsets.only(top: 2),
                                            child: Text(
                                              '⚠️ HPP Belum Diset',
                                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Stepper - & +
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: AppTheme.textDark),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _setPhysicalStock(prod, physical - 1),
                                  ),
                                  const SizedBox(width: 4),

                                  SizedBox(
                                    width: 58,
                                    height: 34,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppTheme.primaryDark),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _setPhysicalStock(prod, physical + 1),
                                  ),
                                  const SizedBox(width: 6),

                                  // Badge Status
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: diff == 0 ? const Color(0xFFECFDF5) : (diff < 0 ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      diff == 0 ? 'Pas' : '${diff > 0 ? "+" : ""}$diff',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: diff == 0 ? AppTheme.successGreen : (diff < 0 ? AppTheme.dangerRed : const Color(0xFF2563EB)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Catatan & Ganti Penjaga
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
                            Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 18),
                            SizedBox(width: 6),
                            Text('Catatan / Kesepakatan Serah Terima', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'cth: Titipan gas 3kg, kesepakatan potongan selisih barang, uang laci...',
                            hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Divider(),
                        const SizedBox(height: 10),

                        // Toggle Ganti Penjaga
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Serahkan ke Penjaga Baru?', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                                  Text(
                                    _isChangingGuard
                                        ? 'Pilih penjaga penerima toko di bawah ini'
                                        : 'Tidak — penjaga tetap bertugas seperti biasa',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isChangingGuard,
                              onChanged: (val) => setState(() {
                                _isChangingGuard = val;
                                if (!val) {
                                  _selectedNextUser = null;
                                  _nextCashierController.text = widget.currentCashier;
                                }
                              }),
                              activeTrackColor: AppTheme.primaryTeal,
                            ),
                          ],
                        ),

                        if (_isChangingGuard && widget.users.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          const Text('Pilih penjaga penerima toko:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Builder(
                            builder: (context) {
                              final eligibleUsers = widget.users.where((u) {
                                if (u.isOwner) return true;
                                if (widget.branchId != null && u.branchId != null) {
                                  return u.branchId == widget.branchId;
                                }
                                return true;
                              }).toList();

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: eligibleUsers.map((user) {
                                  final isSelected = _selectedNextUser?.id == user.id;
                                  final isCurrent = user.name == widget.currentCashier;

                                  return InkWell(
                                    onTap: () => _selectNextUser(user),
                                    borderRadius: BorderRadius.circular(8),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        gradient: isSelected ? AppTheme.goldGradient : null,
                                        color: isSelected ? null : (isCurrent ? AppTheme.bgSubtle : Colors.white),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryGold : AppTheme.borderColor,
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                        boxShadow: isSelected ? AppTheme.softShadow : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            user.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                            size: 15,
                                            color: isSelected ? AppTheme.primaryDark : (user.isOwner ? const Color(0xFFD97706) : AppTheme.primaryTeal),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                              color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                                            ),
                                          ),
                                          if (isCurrent) ...[
                                            const SizedBox(width: 4),
                                            const Text('(Saat ini)', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom Submit Button
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold, size: 20),
                  label: Text(
                    _isChangingGuard && _selectedNextUser != null
                        ? 'Sahkan & Serahkan Toko ke ${_selectedNextUser!.name}'
                        : 'Simpan Laporan & Selesaikan Cekan',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900),
                  ),
                  onPressed: _isSaving ? null : _finalizeSubmit,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String catKey, String label) {
    final isSelected = _selectedCategory == catKey;
    return ChoiceChip(
      selected: isSelected,
      showCheckmark: false,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textDark,
        ),
      ),
      selectedColor: AppTheme.primaryDark,
      backgroundColor: AppTheme.bgSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.borderColor),
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = catKey);
      },
    );
  }
}
