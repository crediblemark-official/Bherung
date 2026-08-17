import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

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
  final Function(ShiftRecord shiftRecord, AppUser? nextUser) onShiftHandoverCompleted;

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
    required this.onShiftHandoverCompleted,
  });

  @override
  State<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends State<ShiftHandoverScreen> {
  final TextEditingController _nextCashierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final Map<String, TextEditingController> _auditControllers = {};
  late List<Product> _sensitiveProducts;
  AppUser? _selectedNextUser;
  bool _isChangingGuard = false;

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
    _selectedNextUser = null;
    _nextCashierController.text = widget.currentCashier;
  }

  @override
  void dispose() {
    _nextCashierController.dispose();
    _notesController.dispose();
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

  void _submit() {
    _finalizeSubmit();
  }

  Future<void> _finalizeSubmit() async {
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

    final AppUser? nextUser = _isChangingGuard ? _selectedNextUser : null;
    final String recipientName = nextUser?.name ?? widget.currentCashier;

    final shiftRecord = ShiftRecord(
      id: 'LAPORAN-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: widget.currentCashier,
      shiftName: 'Laporan ${widget.storeName}',
      startTime: DateTime.now().subtract(const Duration(hours: 24)),
      endTime: DateTime.now(),
      startingCashDrawer: 0,
      systemCashSales: widget.currentShiftSales,
      systemQrisSales: 0,
      systemKasbonSales: 0,
      totalSystemSales: widget.currentShiftSales,
      physicalCashCounted: 0,
      cashDifference: 0,
      stockAudits: audits,
      handoverNotes: _notesController.text.trim(),
      nextCashierName: recipientName,
      transactionCount: widget.currentShiftTransactions,
    );

    if (nextUser != null) {
      await InventoryStorageService().saveScheduledNextUser(nextUser);
    }

    widget.onShiftHandoverCompleted(shiftRecord, nextUser);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 0,
        toolbarHeight: 50,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kasir',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.assessment_rounded, color: AppTheme.primaryDark, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Laporan & Tutup Kas',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
              ),
              child: Text(
                widget.currentCashier,
                style: const TextStyle(color: AppTheme.goldAccent, fontSize: 10.5, fontWeight: FontWeight.bold),
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
                  // 1. Ringkasan Omzet
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
                            Text('Ringkasan Omzet', style: TextStyle(color: AppTheme.goldAccent, fontSize: 12, fontWeight: FontWeight.w800)),
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
                                    widget.previousShiftSales > 0
                                        ? AppTheme.formatRupiah(widget.previousShiftSales)
                                        : '—',
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
                                  const Text('Omzet Saat Ini:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
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
                              const Text('Total Transaksi:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                              Text(
                                '${widget.currentShiftTransactions} Transaksi',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 2. Cek Stok Rokok & Barang Penting
                  if (_sensitiveProducts.isNotEmpty) ...[
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
                            children: [
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.inventory_2_rounded, color: AppTheme.warningOrange, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Cek Stok Rokok & Barang Penting',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Cocokkan jumlah fisik barang dengan stok di sistem:',
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
                                    width: 74,
                                    height: 34,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
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
                                      diff == 0 ? 'Pas' : '${diff > 0 ? "+" : ""}$diff',
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
                  ],

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
                            Text('Catatan ke Pemilik Toko (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'cth: Ada langganan titip gas 3kg, kulkas bocor tadi malam, rokok A kosong...',
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
                                  const Text('Ganti Orang Jaga?', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                                  Text(
                                    _isChangingGuard
                                        ? 'Pilih penjaga pengganti di bawah ini'
                                        : 'Tidak — penjaga tetap sama seperti biasa',
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
                          const Text('Pilih penjaga pengganti:', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: widget.users.map((user) {
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
                                          fontSize: 11.5,
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                          color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                                        ),
                                      ),
                                      if (isCurrent) ...[
                                        const SizedBox(width: 4),
                                        const Text('(Jaga Sekarang)', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sticky Bottom Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: const Border(top: BorderSide(color: AppTheme.borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isChangingGuard && _selectedNextUser != null
                        ? 'KIRIM LAPORAN & GANTI KE ${_selectedNextUser!.name.toUpperCase()}'
                        : 'KIRIM LAPORAN KE PEMILIK TOKO',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
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
