import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ShiftHandoverScreen extends StatefulWidget {
  final String currentCashier;
  final double currentShiftSales;
  final int currentShiftTransactions;
  final List<Product> products;
  final Function(ShiftRecord) onShiftHandoverCompleted;

  const ShiftHandoverScreen({
    super.key,
    required this.currentCashier,
    required this.currentShiftSales,
    required this.currentShiftTransactions,
    required this.products,
    required this.onShiftHandoverCompleted,
  });

  @override
  State<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends State<ShiftHandoverScreen> {
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
        title: Row(
          children: [
            const Text(
              'Serah Terima Shift',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppTheme.secondaryTeal.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Kasir: ${widget.currentCashier}',
                style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                children: [
                  // 1. Ringkasan Shift Aktif
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
                              const Text('Total Transaksi Shift:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.currentShiftTransactions} Transaksi',
                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 30, width: 1, color: AppTheme.borderColor),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Penjualan Sistem:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                              const SizedBox(height: 2),
                              Text(
                                AppTheme.formatRupiah(widget.currentShiftSales),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Rekonsiliasi Uang Fisik Laci
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
                            Icon(Icons.point_of_sale_rounded, color: AppTheme.primaryTeal, size: 18),
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
                                  const Text('Modal Kas Awal (Rp)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _startingCashController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Uang Fisik di Laci (Rp) *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _physicalCashController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Indikator Status Selisih Kas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _cashDiff == 0
                                ? const Color(0xFFECFDF5)
                                : (_cashDiff > 0 ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2)),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _cashDiff == 0
                                  ? AppTheme.successGreen
                                  : (_cashDiff > 0 ? const Color(0xFF3B82F6) : AppTheme.dangerRed),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _cashDiff == 0
                                    ? '✓ Kas Sesuai / Pas (Target: ${AppTheme.formatRupiah(_expectedCash)})'
                                    : (_cashDiff > 0 ? '✓ Kas Lebih (+)' : '⚠ Kas Selisih / Kurang (-)'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: _cashDiff == 0
                                      ? const Color(0xFF047857)
                                      : (_cashDiff > 0 ? const Color(0xFF1D4ED8) : const Color(0xFFB91C1C)),
                                ),
                              ),
                              Text(
                                AppTheme.formatRupiah(_cashDiff.abs()),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _cashDiff == 0
                                      ? const Color(0xFF047857)
                                      : (_cashDiff > 0 ? const Color(0xFF1D4ED8) : const Color(0xFFB91C1C)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Audit Fisik Barang Sensitif (Rokok & Sembako)
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
                            Icon(Icons.inventory_2_rounded, color: AppTheme.warningOrange, size: 18),
                            SizedBox(width: 6),
                            Text('2. Hitung Fisik Barang Sensitif (Rokok & Sembako)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pastikan jumlah fisik di etalase cocok dengan stok sistem:',
                          style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),

                        ..._sensitiveProducts.map((prod) {
                          final controller = _auditControllers[prod.id];
                          final physical = int.tryParse(controller?.text ?? '') ?? prod.stock;
                          final diff = physical - prod.stock;

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
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(prod.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                      Text('Sistem: ${prod.stock} ${prod.unit}', style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 70,
                                  height: 32,
                                  child: TextField(
                                    controller: controller,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      suffixText: prod.unit,
                                      suffixStyle: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: diff == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    diff == 0 ? '✓ Pas' : '${diff > 0 ? "+" : ""}$diff',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: diff == 0 ? AppTheme.successGreen : AppTheme.dangerRed,
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

                  // 4. Informasi Serah Terima & Catatan
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
                        const Text('3. Penerima Shift & Catatan Handover', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nextCashierController,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Diserahkan Kepada (Penjaga Berikutnya)',
                            labelStyle: const TextStyle(fontSize: 11),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Catatan Khusus (cth: uang rokok kurang 5rb, gas 3kg titipan ibu RT)',
                            labelStyle: const TextStyle(fontSize: 11),
                            isDense: true,
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

            // Sticky Bottom Completion Bar
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
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Selesaikan Serah Terima Shift', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
