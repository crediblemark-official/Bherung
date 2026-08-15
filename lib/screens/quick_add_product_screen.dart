import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/barcode_master_lookup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dynamic_category_picker.dart';
import 'scanner_screen.dart';

class QuickAddProductScreen extends StatefulWidget {
  final String barcode;
  final List<Category> categories;
  final Function(Product) onProductCreated;

  const QuickAddProductScreen({
    super.key,
    required this.barcode,
    required this.categories,
    required this.onProductCreated,
  });

  @override
  State<QuickAddProductScreen> createState() => _QuickAddProductScreenState();
}

class _QuickAddProductScreenState extends State<QuickAddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _codeController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController(text: '24');
  final TextEditingController _wholesalePriceController = TextEditingController();
  final TextEditingController _wholesaleMinQtyController = TextEditingController();

  late List<Category> _availableCategories;
  String _selectedCategoryId = 'sembako';
  String _selectedUnit = 'pcs';
  bool _isSensitiveItem = false;
  final bool _showWholesale = false;

  final List<String> _units = ['pcs', 'bks', 'botol', 'renceng', 'kg', 'sak', 'dus', 'tabung', 'galon'];

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.barcode);
    _availableCategories = List.from(widget.categories);
    if (_availableCategories.isNotEmpty && _availableCategories.any((c) => c.id != 'all')) {
      _selectedCategoryId = _availableCategories.firstWhere((c) => c.id != 'all').id;
    }
    if (widget.barcode.isNotEmpty) {
      _lookupMasterBarcode(widget.barcode);
    }
  }

  void _lookupMasterBarcode(String barcode) {
    final item = BarcodeMasterLookupService().lookup(barcode);
    if (item != null) {
      setState(() {
        if (_nameController.text.isEmpty || _nameController.text.startsWith('Produk')) {
          _nameController.text = item.name;
        }
        if (_priceController.text.isEmpty) {
          _priceController.text = item.price.toInt().toString();
        }
        if (_costPriceController.text.isEmpty && item.costPrice != null) {
          _costPriceController.text = item.costPrice!.toInt().toString();
        }
        _selectedCategoryId = item.categoryId;
        _selectedUnit = item.unit;
        _isSensitiveItem = item.isSensitiveItem;
      });
    }
  }

  void _scanBarcodeWithCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ScannerScreen(
          onBarcodeDetected: (scannedBarcode) {
            setState(() {
              _codeController.text = scannedBarcode;
            });
            _lookupMasterBarcode(scannedBarcode);
            Navigator.pop(ctx); // Kembali ke form Tambah Produk dengan barcode terisi
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _costPriceController.dispose();
    _stockController.dispose();
    _wholesalePriceController.dispose();
    _wholesaleMinQtyController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    final price = double.tryParse(_priceController.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
    final costPrice = double.tryParse(_costPriceController.text.replaceAll('.', '').replaceAll(',', ''));
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;
    final wholesalePrice = double.tryParse(_wholesalePriceController.text.replaceAll('.', '').replaceAll(',', ''));
    final wholesaleMinQty = int.tryParse(_wholesaleMinQtyController.text.trim());

    // Pilih icon berdasarkan kategori
    IconData icon = Icons.inventory_2_rounded;
    Color color = AppTheme.primaryTeal;
    final foundCat = _availableCategories.where((c) => c.id == _selectedCategoryId).firstOrNull;
    if (foundCat != null) {
      icon = foundCat.icon;
      color = foundCat.color;
    }

    final newProduct = Product(
      id: 'prd-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      price: price,
      costPrice: costPrice,
      wholesalePrice: _showWholesale ? wholesalePrice : null,
      wholesaleMinQty: _showWholesale ? wholesaleMinQty : null,
      unit: _selectedUnit,
      categoryId: _selectedCategoryId,
      icon: icon,
      color: color,
      code: code,
      stock: stock,
      minStockAlert: 5,
      isSensitiveItem: _isSensitiveItem,
    );

    widget.onProductCreated(newProduct);
    Navigator.pop(context);
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
        title: const Row(
          children: [
            Text(
              'Tambah Produk Baru',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
            SizedBox(width: 8),
            Text(
              '• Toko Kelontong',
              style: TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  children: [
                    // Barcode & Scanner Card (Sleek Obsidian & Gold Theme)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _codeController.text.isNotEmpty ? AppTheme.primaryGold : AppTheme.borderColor,
                          width: _codeController.text.isNotEmpty ? 1.4 : 1,
                        ),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.qr_code_2_rounded, color: AppTheme.primaryGold, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Barcode / Kode Barang SKU',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _codeController,
                                  keyboardType: TextInputType.text,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: 'Ketik angka barcode / scan...',
                                    hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
                                    prefixIcon: const Icon(Icons.numbers_rounded, color: AppTheme.goldMuted, size: 18),
                                    suffixIcon: _codeController.text.isNotEmpty
                                        ? IconButton(
                                            icon: const Icon(Icons.clear_rounded, size: 16),
                                            onPressed: () {
                                              _codeController.clear();
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onChanged: (val) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _scanBarcodeWithCamera,
                                icon: const Icon(Icons.camera_alt_rounded, size: 15),
                                label: const Text('Scan HP', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryGold,
                                  foregroundColor: AppTheme.primaryDark,
                                  elevation: 1,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Nama Barang
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
                          const Text('Nama Barang / Sembako *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              hintText: 'cth: Kopi Kapal Api Spesial Mix 1 Renceng',
                              hintStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18, color: AppTheme.textMuted),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Nama produk wajib diisi';
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Kategori & Satuan
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          // Kategori Dinamis
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kategori *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                DynamicCategoryPicker(
                                  categories: _availableCategories,
                                  selectedCategoryId: _selectedCategoryId,
                                  onCategorySelected: (catId) {
                                    setState(() => _selectedCategoryId = catId);
                                  },
                                  onCategoryCreated: (newCat) {
                                    setState(() {
                                      _availableCategories.add(newCat);
                                      _selectedCategoryId = newCat.id;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Satuan
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Satuan *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.borderColor),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedUnit,
                                      isExpanded: true,
                                      items: _units.map((u) {
                                        return DropdownMenuItem<String>(
                                          value: u,
                                          child: Text(u, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) setState(() => _selectedUnit = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Harga Jual Eceran & Stok Awal
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Harga Jual Eceran (Rp) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: 'Rp ',
                                    prefixStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                    hintText: '15.000',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Harga wajib diisi';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stok Awal di Toko *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    suffixText: _selectedUnit,
                                    suffixStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Harga Beli / Modal (Opsional)
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
                          const Text('Harga Beli / Modal (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _costPriceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              isDense: true,
                              prefixText: 'Rp ',
                              prefixStyle: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
                              hintText: 'cth: 13.500 (untuk kalkulasi laba bersih)',
                              hintStyle: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Checkbox Barang Sensitif (Clean Material InkWell)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () => setState(() => _isSensitiveItem = !_isSensitiveItem),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isSensitiveItem,
                                onChanged: (val) => setState(() => _isSensitiveItem = val ?? false),
                                activeColor: AppTheme.primaryTeal,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Barang Sensitif Shift (Rokok / Sembako)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 2),
                                    Text('Wajib dihitung fisik saat serah terima pergantian kasir', style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Submit Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
                  label: const Text('Simpan & Masukkan Keranjang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
