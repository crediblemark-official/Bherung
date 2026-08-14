import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ShiftHandoverDialog extends StatefulWidget {
  final String currentCashier;
  final double currentShiftSales;
  final int currentShiftTransactions;
  final List<Product> products;
  final Function(ShiftRecord) onShiftHandoverCompleted;

  const ShiftHandoverDialog({
    super.key,
    required this.currentCashier,
    required this.currentShiftSales,
    required this.currentShiftTransactions,
    required this.products,
    required this.onShiftHandoverCompleted,
  });

  @override
  State<ShiftHandoverDialog> createState() => _ShiftHandoverDialogState();
}

class _ShiftHandoverDialogState extends State<ShiftHandoverDialog> {
  final TextEditingController _startingCashController = TextEditingController(text: '200000');
  final TextEditingController _physicalCashController = TextEditingController();
  final TextEditingController _nextCashierController = TextEditingController(text: 'Madura Shift Malam (Hasan)');
  final TextEditingController _notesController = TextEditingController();

  final Map<String, TextEditingController> _auditControllers = {};
  late List<Product> _sensitiveProducts;

  @override
  void initState() {
    super.initState();
    _sensitiveProducts = widget.products.where((p) => p.isSensitiveItem || p.categoryId == 'rokok').toList();
    if (_sensitiveProducts.isEmpty) {
      _sensitiveProducts = widget.products.take(4).toList();
    }
    for (final p in _sensitiveProducts) {
      _auditControllers[p.id] = TextEditingController(text: p.stock.toString());
    }
    // Default perkiraan uang fisik = kas awal + penjualan tunai
    _physicalCashController.text = (200000 + widget.currentShiftSales).toInt().toString();
  }

  @override
  void dispose() {
    _startingCashController.dispose();
    _physicalCashController.dispose();
    _nextCashierController.dispose();
    _notesController.dispose();
    for (final c in _auditControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _startingCash => double.tryParse(_startingCashController.text.replaceAll('.', '')) ?? 0;
  double get _physicalCash => double.tryParse(_physicalCashController.text.replaceAll('.', '')) ?? 0;
  double get _expectedCash => _startingCash + widget.currentShiftSales;
  double get _cashDiff => _physicalCash - _expectedCash;

  void _submit() {
    final List<SensitiveProductAudit> audits = [];
    for (final p in _sensitiveProducts) {
      final physical = int.tryParse(_auditControllers[p.id]?.text.trim() ?? '') ?? p.stock;
      audits.add(SensitiveProductAudit(
        productId: p.id,
        productName: p.name,
        systemStock: p.stock,
        physicalStock: physical,
        difference: physical - p.stock,
      ));
    }

    final shiftRecord = ShiftRecord(
      id: 'SHIFT-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: widget.currentCashier,
      shiftName: 'Shift Siang-Sore (24 Jam)',
      startTime: DateTime.now().subtract(const Duration(hours: 8)),
      endTime: DateTime.now(),
      startingCashDrawer: _startingCash,
      systemCashSales: widget.currentShiftSales,
      systemQrisSales: 0,
      systemKasbonSales: 0,
      totalSystemSales: widget.currentShiftSales,
      physicalCashCounted: _physicalCash,
      cashDifference: _cashDiff,
      stockAudits: audits,
      handoverNotes: _notesController.text.trim(),
      nextCashierName: _nextCashierController.text.trim(),
    );

    widget.onShiftHandoverCompleted(shiftRecord);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
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
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.sync_alt_rounded, color: Colors.amber, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Serah Terima Shift & Audit Kas/Stok',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Tutup shift kasir: ${widget.currentCashier} • Rekonsiliasi uang & rokok/sembako',
                          style: const TextStyle(color: Colors.white70, fontSize: 10.5),
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

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Ringkasan Penjualan Sistem
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Transaksi Shift Ini:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text('${widget.currentShiftTransactions} Transaksi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Penjualan Sistem:', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                              Text(
                                AppTheme.formatRupiah(widget.currentShiftSales),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Rekonsiliasi Uang Fisik Laci
                    const Row(
                      children: [
                        Icon(Icons.point_of_sale_rounded, size: 16, color: AppTheme.primaryTeal),
                        SizedBox(width: 6),
                        Text('1. Rekonsiliasi Uang Fisik Laci Kasir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Modal Kas Awal (Rp)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _startingCashController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
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
                              const Text('Uang Fisik Dihitung (Rp) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              TextFormField(
                                controller: _physicalCashController,
                                keyboardType: TextInputType.number,
                                onChanged: (val) => setState(() {}),
                                decoration: const InputDecoration(prefixText: 'Rp '),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Difference Calculation Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _cashDiff == 0
                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                            : (_cashDiff > 0
                                ? Colors.blue.withValues(alpha: 0.1)
                                : AppTheme.dangerRed.withValues(alpha: 0.1)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _cashDiff == 0
                              ? AppTheme.successGreen
                              : (_cashDiff > 0 ? Colors.blue : AppTheme.dangerRed),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _cashDiff == 0
                                ? '✓ Kas Sesuai / Pas (Target: ${AppTheme.formatRupiah(_expectedCash)})'
                                : (_cashDiff > 0 ? 'Kas Lebih (+)' : 'Kas Kurang / Selisih (-)'),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _cashDiff == 0
                                  ? AppTheme.successGreen
                                  : (_cashDiff > 0 ? Colors.blue : AppTheme.dangerRed),
                            ),
                          ),
                          Text(
                            AppTheme.formatRupiah(_cashDiff.abs()),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: _cashDiff == 0
                                  ? AppTheme.successGreen
                                  : (_cashDiff > 0 ? Colors.blue : AppTheme.dangerRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 3: Audit Barang Sensitif (Rokok/Sembako)
                    const Row(
                      children: [
                        Icon(Icons.inventory_rounded, size: 16, color: AppTheme.warningOrange),
                        SizedBox(width: 6),
                        Text('2. Hitung Fisik Barang Sensitif (Rokok & Sembako)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pastikan jumlah fisik di etalase cocok dengan stok sistem:',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sensitiveProducts.length,
                        separatorBuilder: (c, i) => const Divider(height: 1),
                        itemBuilder: (c, i) {
                          final p = _sensitiveProducts[i];
                          final ctrl = _auditControllers[p.id]!;
                          final physical = int.tryParse(ctrl.text.trim()) ?? p.stock;
                          final diff = physical - p.stock;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                      Text('Sistem: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: 80,
                                  height: 32,
                                  child: TextField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    onChanged: (val) => setState(() {}),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.zero,
                                      suffixText: p.unit,
                                      suffixStyle: const TextStyle(fontSize: 9),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    diff == 0 ? '✓ Pas' : '${diff > 0 ? "+" : ""}$diff',
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: diff == 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Section 4: Penjaga Selanjutnya & Catatan
                    const Text('Penjaga Shift Selanjutnya *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _nextCashierController,
                      decoration: const InputDecoration(
                        hintText: 'Nama penjaga shift pengganti...',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Catatan Serah Terima (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'cth: Gas LPG kosong, uang koin Rp 500 habis...',
                      ),
                    ),
                  ],
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
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Selesaikan Serah Terima Shift'),
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
