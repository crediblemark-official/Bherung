import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'dynamic_category_picker.dart';

class QuickAddProductDialog extends StatefulWidget {
  final String barcode;
  final List<Category> categories;
  final Function(Product) onProductCreated;

  const QuickAddProductDialog({
    super.key,
    required this.barcode,
    required this.categories,
    required this.onProductCreated,
  });

  @override
  State<QuickAddProductDialog> createState() => _QuickAddProductDialogState();
}

class _QuickAddProductDialogState extends State<QuickAddProductDialog> {
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_shopping_cart_rounded, color: AppTheme.secondaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Cepat Produk Baru',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Barcode baru terdeteksi. Isi data kilat untuk langsung dijual.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5),
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

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barcode Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, size: 18, color: AppTheme.primaryTeal),
                            const SizedBox(width: 8),
                            const Text('Barcode: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                _codeController.text,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryDark,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nama Produk
                      const Text('Nama Barang / Sembako *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'cth: Kopi Kapal Api Spesial Mix 1 Renceng, Surya 16...',
                          prefixIcon: Icon(Icons.inventory_rounded, size: 18),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Nama barang tidak boleh kosong';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Row: Kategori & Satuan Unit
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Kategori *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
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
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Satuan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedUnit,
                                  decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                  items: _units
                                      .map((u) => DropdownMenuItem(
                                            value: u,
                                            child: Text(u, style: const TextStyle(fontSize: 12)),
                                          ))
                                      .toList(),
                                  onChanged: (val) => setState(() => _selectedUnit = val!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Row: Harga Jual Eceran & Stok Awal
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Harga Jual Eceran (Rp) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    prefixText: 'Rp ',
                                    hintText: 'cth: 15.000',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Harga jual wajib diisi';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Stok Awal *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '24',
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Stok wajib';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Harga Modal / Kulakan (Opsional)
                      const Text('Harga Beli / Modal (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
                      const SizedBox(height: 5),
                      TextFormField(
                        controller: _costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          prefixText: 'Rp ',
                          hintText: 'cth: 13.500 (untuk kalkulasi laba bersih)',
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Switch Harga Grosir & Barang Sensitif (Rokok/Sembako)
                      InkWell(
                        onTap: () => setState(() => _isSensitiveItem = !_isSensitiveItem),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _isSensitiveItem,
                              onChanged: (val) => setState(() => _isSensitiveItem = val ?? false),
                              activeColor: AppTheme.primaryTeal,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Barang Sensitif Shift (Rokok/Sembako)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Text('Wajib dihitung saat serah terima shift kasir', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
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
            ),

            // Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.bgSubtle,
                border: Border(top: BorderSide(color: AppTheme.borderColor)),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                    label: const Text('Simpan & Masukkan Keranjang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
}
