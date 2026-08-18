import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/barcode_master_lookup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/camera_barcode_scanner.dart';

class RestockScreen extends StatefulWidget {
  final List<Product> products;
  final String cashierName;
  final String? branchId;
  final String? branchName;
  final Function(Product updatedProduct, StockMutation mutation) onRestockCompleted;

  const RestockScreen({
    super.key,
    required this.products,
    this.cashierName = 'Kasir',
    this.branchId,
    this.branchName,
    required this.onRestockCompleted,
  });

  @override
  State<RestockScreen> createState() => _RestockScreenState();
}

class _RestockScreenState extends State<RestockScreen> {
  Product? _selectedProduct;
  final TextEditingController _qtyController = TextEditingController(text: '12');
  final TextEditingController _packMultiplierController = TextEditingController(text: '1');
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController(text: 'Kulakan Agen / Pasar');
  DateTime? _selectedExpiryDate;

  String _packType = 'satuan'; // 'satuan', 'dus', 'lusin', 'renceng', 'bal'

  @override
  void initState() {
    super.initState();
    if (widget.products.isNotEmpty) {
      _selectProduct(widget.products.first, showToast: false);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _packMultiplierController.dispose();
    _costPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _selectProduct(Product product, {bool showToast = true}) {
    setState(() {
      _selectedProduct = product;
      if (product.costPrice != null) {
        _costPriceController.text = product.costPrice!.toInt().toString();
      }
    });

    if (showToast && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk "${product.name}" dipilih.'),
          backgroundColor: AppTheme.successGreen,
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  void _handleBarcodeOrSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;

    // 1. Coba cari exact match barcode produk toko
    Product? found = widget.products
        .where((p) => p.code.isNotEmpty && p.code.trim().toLowerCase() == clean.toLowerCase())
        .firstOrNull;

    // 2. Jika tidak ada exact barcode, coba cari berdasarkan ID produk
    found ??= widget.products.where((p) => p.id.toLowerCase() == clean.toLowerCase()).firstOrNull;

    // 3. Jika tidak ada, coba cari substring nama produk
    found ??= widget.products.where((p) => p.name.toLowerCase().contains(clean.toLowerCase())).firstOrNull;

    if (found != null) {
      _selectProduct(found);
    } else {
      final master = BarcodeMasterLookupService().lookup(clean);
      final hintName = master != null ? ' (${master.name})' : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode "$clean"$hintName belum terdaftar di daftar produk toko.'),
          backgroundColor: AppTheme.warningOrange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openCameraScanner() {
    showDialog(
      context: context,
      builder: (ctx) => CameraBarcodeScannerDialog(
        onBarcodeDetected: (scannedBarcode) {
          Navigator.pop(ctx);
          _handleBarcodeOrSearch(scannedBarcode);
        },
      ),
    );
  }

  // Buka Dialog Pencarian Cepat Produk (Cari Real-Time / Barcode / Kategori)
  Future<void> _openProductSearchPicker() async {
    final Product? picked = await showDialog<Product>(
      context: context,
      builder: (ctx) => _ProductSearchPickerDialog(
        products: widget.products,
        currentlySelectedId: _selectedProduct?.id,
        onOpenScanner: () {
          Navigator.pop(ctx);
          _openCameraScanner();
        },
      ),
    );

    if (picked != null) {
      _selectProduct(picked);
    }
  }

  int get _calculatedAddedUnits {
    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;
    final multiplier = int.tryParse(_packMultiplierController.text.trim()) ?? 1;
    return qty * multiplier;
  }

  void _onPackTypeChanged(String val) {
    setState(() {
      _packType = val;
      if (val == 'satuan') {
        _packMultiplierController.text = '1';
      } else if (val == 'lusin') {
        _packMultiplierController.text = '12';
      } else if (val == 'renceng') {
        _packMultiplierController.text = '10';
      } else if (val == 'dus') {
        _packMultiplierController.text = '24';
      } else if (val == 'bal') {
        _packMultiplierController.text = '20';
      }
    });
  }

  void _submitRestock() {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih produk yang ingin di-restok')),
      );
      return;
    }

    final addedUnits = _calculatedAddedUnits;
    if (addedUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah stok yang ditambahkan harus lebih dari 0')),
      );
      return;
    }

    final double? parsedCost = double.tryParse(_costPriceController.text.trim());

    // Update Product Stock
    final updatedProduct = _selectedProduct!.copyWith(
      stock: _selectedProduct!.stock + addedUnits,
      costPrice: parsedCost ?? _selectedProduct!.costPrice,
    );

    // Create Stock Mutation
    final mutation = StockMutation(
      id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      type: StockMutationType.restock,
      qtyChange: addedUnits,
      previousStock: _selectedProduct!.stock,
      newStock: updatedProduct.stock,
      timestamp: DateTime.now(),
      note: '${_noteController.text.trim()} (+$addedUnits ${_selectedProduct!.unit})',
      cashierName: widget.cashierName,
      costPrice: parsedCost,
      branchId: widget.branchId,
      branchName: widget.branchName,
    );

    widget.onRestockCompleted(updatedProduct, mutation);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stok ${_selectedProduct!.name} bertambah +$addedUnits ${_selectedProduct!.unit} (Total: ${updatedProduct.stock})'),
        backgroundColor: AppTheme.successGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedProduct = _selectedProduct;
    final totalTambahan = _calculatedAddedUnits;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kulakan & Restock Barang Masuk',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Tambah stok barang belanjaan dari agen / distributor / pasar',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Scan Barcode Kamera',
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.goldAccent),
            onPressed: _openCameraScanner,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Bar Pilihan Produk & Tombol Scan Barcode
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Pilih Produk yang Masuk *',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                            ),
                            ElevatedButton.icon(
                              onPressed: _openCameraScanner,
                              icon: const Icon(Icons.camera_alt_rounded, size: 14),
                              label: const Text('Scan Barcode HP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.2),
                                foregroundColor: AppTheme.goldMuted,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(color: AppTheme.primaryGold),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Card Pemilihan Produk Aktif (Interaktif)
                        InkWell(
                          onTap: _openProductSearchPicker,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedProduct != null ? AppTheme.primaryGold : AppTheme.borderColor,
                                width: selectedProduct != null ? 1.5 : 1,
                              ),
                              boxShadow: selectedProduct != null
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryGold.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : AppTheme.softShadow,
                            ),
                            child: selectedProduct != null
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                          color: selectedProduct.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(selectedProduct.icon, color: selectedProduct.color, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              selectedProduct.name,
                                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDark),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                if (selectedProduct.code.isNotEmpty)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                    margin: const EdgeInsets.only(right: 6),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      selectedProduct.code,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w800,
                                                        color: AppTheme.goldMuted,
                                                      ),
                                                    ),
                                                  ),
                                                Flexible(
                                                  child: Text(
                                                    'Stok: ${selectedProduct.stock} ${selectedProduct.unit}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.goldGradient,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.sync_alt_rounded, size: 13, color: AppTheme.primaryDark),
                                            SizedBox(width: 4),
                                            Text(
                                              'Ganti',
                                              style: TextStyle(fontSize: 11, color: AppTheme.primaryDark, fontWeight: FontWeight.w800),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const Row(
                                    children: [
                                      Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Klik untuk cari produk (Ketik nama / Barcode / Kategori)...',
                                          style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted),
                                        ),
                                      ),
                                      Text(
                                        'Pilih Produk',
                                        style: TextStyle(fontSize: 11, color: AppTheme.goldAccent, fontWeight: FontWeight.w800),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Kemasan Masuk
                        const Text('Satuan Kemasan Kulakan *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _packType,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            prefixIcon: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryGold, size: 18),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'satuan', child: Text('Satuan Eceran (Pcs / Bks / Kg)', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'dus', child: Text('Kardus / Dus / Karton', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'renceng', child: Text('Renceng (Gantungan)', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'lusin', child: Text('Lusin (12 Pcs)', style: TextStyle(fontSize: 12.5))),
                            DropdownMenuItem(value: 'bal', child: Text('Bal / Karung Sak', style: TextStyle(fontSize: 12.5))),
                          ],
                          onChanged: (val) => _onPackTypeChanged(val!),
                        ),
                        const SizedBox(height: 14),

                        // Input Jumlah Beli & Isi Per Kemasan
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Jumlah Beli Masuk *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _qtyController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => setState(() {}),
                                    decoration: const InputDecoration(
                                      hintText: 'cth: 2',
                                      prefixIcon: Icon(Icons.numbers_rounded, color: AppTheme.primaryGold, size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Isi per Kemasan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _packMultiplierController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) => setState(() {}),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.grid_view_rounded, color: AppTheme.primaryGold, size: 18),
                                      suffixText: selectedProduct?.unit ?? 'pcs',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Banner Hasil Hitung Total Tambahan Stok
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryDark, AppTheme.surfaceDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.bolt_rounded, color: AppTheme.goldAccent, size: 18),
                                  SizedBox(width: 6),
                                  Text('Total Tambahan Stok:', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.6)),
                                ),
                                child: Text(
                                  '+$totalTambahan ${selectedProduct?.unit ?? "unit"}',
                                  style: const TextStyle(
                                    color: AppTheme.goldAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Form Harga Beli Modal & Tanggal Expired
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Harga Modal Per Unit', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _costPriceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixText: 'Rp ',
                                      hintText: 'cth: 12000',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Kedaluwarsa (Expired)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now().add(const Duration(days: 90)),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                                      );
                                      if (picked != null) {
                                        setState(() => _selectedExpiryDate = picked);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppTheme.borderColor),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryGold),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _selectedExpiryDate != null
                                                  ? '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}'
                                                  : 'Pilih Tanggal',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                color: _selectedExpiryDate != null ? AppTheme.textDark : AppTheme.textMuted,
                                                fontWeight: FontWeight.w600,
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
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Catatan / Supplier
                        const Text('Catatan / Supplier', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            hintText: 'cth: Agen Toko Jaya / Pasar Induk',
                            prefixIcon: Icon(Icons.edit_note_rounded, color: AppTheme.primaryGold, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky Bottom Bar Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: const Border(top: BorderSide(color: AppTheme.borderColor)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: AppTheme.borderColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Batal', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: ElevatedButton.icon(
                          onPressed: _submitRestock,
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: const Text('Simpan & Tambah Stok', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Modal dialog untuk picker pencarian produk
class _ProductSearchPickerDialog extends StatefulWidget {
  final List<Product> products;
  final String? currentlySelectedId;
  final VoidCallback onOpenScanner;

  const _ProductSearchPickerDialog({
    required this.products,
    this.currentlySelectedId,
    required this.onOpenScanner,
  });

  @override
  State<_ProductSearchPickerDialog> createState() => _ProductSearchPickerDialogState();
}

class _ProductSearchPickerDialogState extends State<_ProductSearchPickerDialog> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.code.isNotEmpty && p.code.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCat = _selectedCategory == null || p.categoryId == _selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        height: 560,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryGold, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Cari & Pilih Produk Toko', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ketik nama sembako / barcode...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 18),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryGold, size: 18),
                  onPressed: widget.onOpenScanner,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('Tidak ada produk yang cocok', style: TextStyle(color: AppTheme.textMuted)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (c, i) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final p = filtered[i];
                        final isSel = p.id == widget.currentlySelectedId;

                        return ListTile(
                          selected: isSel,
                          selectedTileColor: AppTheme.primaryGold.withValues(alpha: 0.1),
                          leading: CircleAvatar(
                            backgroundColor: p.color.withValues(alpha: 0.15),
                            child: Icon(p.icon, color: p.color, size: 18),
                          ),
                          title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text('Stok: ${p.stock} ${p.unit} • ${AppTheme.formatRupiah(p.price)}', style: const TextStyle(fontSize: 11)),
                          trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold, size: 18) : null,
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
