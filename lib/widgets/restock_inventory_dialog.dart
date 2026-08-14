import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class RestockInventoryDialog extends StatefulWidget {
  final List<Product> products;
  final Function(Product updatedProduct, StockMutation mutation) onRestockCompleted;

  const RestockInventoryDialog({
    super.key,
    required this.products,
    required this.onRestockCompleted,
  });

  @override
  State<RestockInventoryDialog> createState() => _RestockInventoryDialogState();
}

class _RestockInventoryDialogState extends State<RestockInventoryDialog> {
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
      _selectedProduct = widget.products.first;
      if (_selectedProduct!.costPrice != null) {
        _costPriceController.text = _selectedProduct!.costPrice!.toInt().toString();
      }
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
        _packMultiplierController.text = '40'; // Default isi dus misal indomie
      } else if (val == 'bal') {
        _packMultiplierController.text = '20';
      }
    });
  }

  void _submit() {
    if (_selectedProduct == null) return;
    final addedUnits = _calculatedAddedUnits;
    if (addedUnits <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah stok masuk harus lebih dari 0')),
      );
      return;
    }

    final double? cost = double.tryParse(_costPriceController.text.replaceAll('.', '').replaceAll(',', ''));
    final prevStock = _selectedProduct!.stock;
    final newStock = prevStock + addedUnits;

    final updatedProduct = _selectedProduct!.copyWith(
      stock: newStock,
      costPrice: cost ?? _selectedProduct!.costPrice,
      expiryDate: _selectedExpiryDate ?? _selectedProduct!.expiryDate,
    );

    final mutation = StockMutation(
      id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
      productId: updatedProduct.id,
      productName: updatedProduct.name,
      type: StockMutationType.restock,
      qtyChange: addedUnits,
      previousStock: prevStock,
      newStock: newStock,
      timestamp: DateTime.now(),
      note: '${_noteController.text.trim()} (${_qtyController.text} $_packType)',
      cashierName: 'Ahmad',
      costPrice: cost,
    );

    widget.onRestockCompleted(updatedProduct, mutation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 650),
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
                      color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_business_rounded, color: AppTheme.secondaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kulakan & Restock Barang Masuk',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tambah stok barang belanjaan dari agen/pasar',
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

            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilih Produk
                    const Text('Pilih Produk yang Masuk *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProduct?.id,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.inventory_2_rounded, size: 18),
                      ),
                      isExpanded: true,
                      items: widget.products.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(
                            '${p.name} (Stok saat ini: ${p.stock} ${p.unit})',
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        final found = widget.products.firstWhere((p) => p.id == val);
                        setState(() {
                          _selectedProduct = found;
                          if (found.costPrice != null) {
                            _costPriceController.text = found.costPrice!.toInt().toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kemasan Masuk
                    const Text('Satuan Kemasan Kulakan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _packType,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            items: const [
                              DropdownMenuItem(value: 'satuan', child: Text('Satuan Eceran (Pcs/Bks/Kg)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'dus', child: Text('Kardus / Dus / Karton', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'renceng', child: Text('Renceng (Gantungan)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'lusin', child: Text('Lusin (12 Pcs)', style: TextStyle(fontSize: 12))),
                              DropdownMenuItem(value: 'bal', child: Text('Bal / Karung Sak', style: TextStyle(fontSize: 12))),
                            ],
                            onChanged: (val) => _onPackTypeChanged(val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Input Jumlah Beli & Isi Per Kemasan
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Jumlah Masuk *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _qtyController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
                                decoration: const InputDecoration(hintText: 'cth: 2'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Isi per Kemasan *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _packMultiplierController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
                                decoration: InputDecoration(
                                  suffixText: _selectedProduct?.unit ?? 'pcs',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Live Total Calculation Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Tambahan Stok:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            '+$_calculatedAddedUnits ${_selectedProduct?.unit ?? "pcs"}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryTeal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Harga Beli Modal & Tanggal Kedaluwarsa
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Harga Modal Per Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              TextFormField(
                                controller: _costPriceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(prefixText: 'Rp '),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Kedaluwarsa (Expired)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 180)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                  );
                                  if (picked != null) {
                                    setState(() => _selectedExpiryDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 16, color: AppTheme.primaryTeal),
                                      const SizedBox(width: 6),
                                      Text(
                                        _selectedExpiryDate != null
                                            ? '${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}'
                                            : 'Pilih Tanggal',
                                        style: const TextStyle(fontSize: 11.5),
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
                    const SizedBox(height: 12),

                    // Catatan Kulakan
                    const Text('Catatan / Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        hintText: 'cth: Agen Sembako Barokah, Pasar Induk...',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
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
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Simpan & Tambah Stok'),
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
