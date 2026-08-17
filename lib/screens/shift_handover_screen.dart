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
    required this.onShiftHandoverCompleted,
  });

  @override
  State<ShiftHandoverScreen> createState() => _ShiftHandoverScreenState();
}

class _ShiftHandoverScreenState extends State<ShiftHandoverScreen> {
  late final TextEditingController _startingCashController;
  final TextEditingController _physicalCashController = TextEditingController();
  final TextEditingController _nextCashierController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Map<String, TextEditingController> _auditControllers = {};
  late List<Product> _sensitiveProducts;
  AppUser? _selectedNextUser;

  @override
  void initState() {
    super.initState();
    _startingCashController = TextEditingController(
      text: widget.defaultStartingCash.toInt().toString(),
    );
    _sensitiveProducts = widget.products.where((p) => p.isSensitiveItem || p.categoryId == 'rokok').toList();
    if (_sensitiveProducts.isEmpty) {
      _sensitiveProducts = widget.products.take(4).toList();
    }
    for (final p in _sensitiveProducts) {
      _auditControllers[p.id] = TextEditingController(text: p.stock.toString());
    }
    // Default perkiraan uang fisik = kas awal + penjualan tunai
    _physicalCashController.text = (widget.defaultStartingCash + widget.currentShiftSales).toInt().toString();

    // Inisialisasi kasir penerima
    if (widget.initialIncomingUser != null) {
      _selectedNextUser = widget.initialIncomingUser;
      _nextCashierController.text = widget.initialIncomingUser!.name;
    } else if (widget.users.isNotEmpty) {
      _selectedNextUser = widget.users.firstWhere(
        (u) => u.name != widget.currentCashier,
        orElse: () => widget.users.first,
      );
      _nextCashierController.text = _selectedNextUser?.name ?? 'Penjaga Shift Selanjutnya';
    } else {
      _nextCashierController.text = 'Penjaga Shift Selanjutnya';
    }
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

  void _selectNextUser(AppUser user) {
    setState(() {
      _selectedNextUser = user;
      _nextCashierController.text = user.name;
    });
  }

  void _submit() {
    // Cari akun Pemilik Toko (Owner)
    final ownerUser = widget.users.where((u) => u.isOwner).firstOrNull;
    final ownerPin = ownerUser?.pin.trim().isNotEmpty == true ? ownerUser!.pin.trim() : '1234';

    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: AppTheme.primaryGold, size: 22),
            SizedBox(width: 8),
            Text(
              'Otorisasi Pemilik Toko',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Serah terima shift hanya boleh disetujui & disahkan oleh Pemilik Toko (Owner).',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Penjaga Shift Selanjutnya: ${_selectedNextUser?.name ?? _nextCashierController.text}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'PIN Owner',
                counterText: '',
                prefixIcon: const Icon(Icons.password_rounded, color: AppTheme.primaryGold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim() == ownerPin) {
                Navigator.pop(ctx);
                _finalizeSubmit();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN Pemilik Toko salah! Otorisasi ditolak.'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sahkan Shift', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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

    final recipientName = _selectedNextUser?.name ?? _nextCashierController.text.trim();

    final shiftRecord = ShiftRecord(
      id: 'SHIFT-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: widget.currentCashier,
      shiftName: 'Shift Operan ${widget.storeName}',
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
      nextCashierName: recipientName,
    );

    if (_selectedNextUser != null) {
      await InventoryStorageService().saveScheduledNextUser(_selectedNextUser!);
    }

    widget.onShiftHandoverCompleted(shiftRecord, _selectedNextUser);
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
              child: const Icon(Icons.sync_alt_rounded, color: AppTheme.primaryDark, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Serah Terima Shift Kasir',
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
                'Kasir: ${widget.currentCashier}',
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
                  // 1. Ringkasan Shift Aktif Banner (Obsidian & Gold)
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Transaksi Shift Ini:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
                              const SizedBox(height: 3),
                              Text(
                                '${widget.currentShiftTransactions} Transaksi',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white),
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
                              const Text('Total Omzet Shift:', style: TextStyle(fontSize: 11, color: AppTheme.textSubtle)),
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
                  ),
                  const SizedBox(height: 14),

                  // 2. Rekonsiliasi Uang Fisik Laci
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
                                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.point_of_sale_rounded, color: AppTheme.goldMuted, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '1. Rekonsiliasi Uang Fisik Laci Kasir',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Modal Kas Awal (Rp)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _startingCashController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
                                  const SizedBox(height: 5),
                                  TextField(
                                    controller: _physicalCashController,
                                    keyboardType: TextInputType.number,
                                    onChanged: (_) => setState(() {}),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      prefixText: 'Rp ',
                                      prefixStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Indikator Status Selisih Kas
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
                                    ? 'Kas Sesuai / Pas (Target: ${AppTheme.formatRupiah(_expectedCash)})'
                                    : (_cashDiff > 0 ? 'Kas Lebih (+)' : 'Kas Selisih / Kurang (-)'),
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
                              '2. Hitung Fisik Barang Sensitif (Rokok & Sembako)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
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

                  // 4. Kasir Penerima Shift & Catatan Serah Terima (Terintegrasi Akun)
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
                                gradient: AppTheme.goldGradient,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.person_pin_rounded, color: AppTheme.primaryDark, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '3. Pilih Kasir Penerima Shift Baru',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pilih akun kasir yang bertugas di shift selanjutnya:',
                          style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 10),

                        // User account selection chips
                        if (widget.users.isNotEmpty) ...[
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
                                        const Text('(Kasir Saat Ini)', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted)),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],

                        TextField(
                          controller: _notesController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 12),
                          decoration: InputDecoration(
                            labelText: 'Catatan Khusus Serah Terima (Opsional)',
                            hintText: 'cth: Uang rokok kurang 5rb, gas 3kg titipan ibu RT, koin kembalian menipis...',
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
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _selectedNextUser != null
                        ? 'SELESAIKAN & SERAHKAN KE ${_selectedNextUser!.name.toUpperCase()}'
                        : 'SELESAIKAN SERAH TERIMA SHIFT',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, letterSpacing: 0.2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.primaryDark,
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
