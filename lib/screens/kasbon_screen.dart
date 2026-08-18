import 'package:flutter/material.dart';
import '../models/kasbon_record.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

class KasbonScreen extends StatefulWidget {
  final List<KasbonRecord> kasbonRecords;
  final ValueChanged<KasbonRecord> onKasbonPaid;
  final String storeName;

  const KasbonScreen({
    super.key,
    required this.kasbonRecords,
    required this.onKasbonPaid,
    this.storeName = 'Bherung',
  });

  @override
  State<KasbonScreen> createState() => _KasbonScreenState();
}

class _KasbonScreenState extends State<KasbonScreen> {
  String _searchQuery = '';
  int _activeTab = 0; // 0: Belum Lunas, 1: Sudah Lunas
  final Set<String> _expandedIds = {};

  double get _totalKasbonActive => widget.kasbonRecords
      .where((k) => !k.isPaid)
      .fold(0, (sum, k) => sum + k.amount);

  Future<void> _handleRefresh() async {
    final appsScript = AppsScriptService();
    if (appsScript.isConnected) {
      final cloudKasbon = await appsScript.fetchKasbonFromSpreadsheet();
      if (cloudKasbon != null && mounted) {
        setState(() {
          widget.kasbonRecords.clear();
          widget.kasbonRecords.addAll(cloudKasbon);
        });
        InventoryStorageService().saveKasbon(widget.kasbonRecords);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil memuat ${cloudKasbon.length} data kasbon dari Google Spreadsheet!'),
            backgroundColor: AppTheme.primaryTeal,
          ),
        );
      }
    } else {
      final localKasbon = await InventoryStorageService().loadKasbon();
      if (mounted) {
        setState(() {
          widget.kasbonRecords.clear();
          widget.kasbonRecords.addAll(localKasbon);
        });
      }
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _showKasbonReceipt(BuildContext ctx, KasbonRecord kasbon, {bool isPelunasan = false}) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final createdStr = '${kasbon.createdAt.day.toString().padLeft(2, '0')}/${kasbon.createdAt.month.toString().padLeft(2, '0')}/${kasbon.createdAt.year}';

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isPelunasan ? 'Bukti Pelunasan Kasbon' : 'Struk Kasbon',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            widget.storeName.toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPelunasan ? 'BUKTI PELUNASAN KASBON' : 'BUKTI KASBON / UTANG',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isPelunasan ? AppTheme.successGreen : AppTheme.dangerRed,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _receiptDivider(),
                    const SizedBox(height: 10),
                    _receiptRow('No. Kasbon', kasbon.id),
                    const SizedBox(height: 4),
                    _receiptRow('Tanggal Kasbon', createdStr),
                    const SizedBox(height: 4),
                    if (isPelunasan) ...[
                      _receiptRow('Tanggal Lunas', dateStr),
                      const SizedBox(height: 4),
                    ],
                    _receiptRow('Nama Pelanggan', kasbon.customerName, bold: true),
                    if (kasbon.customerPhone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _receiptRow('No. HP / WA', kasbon.customerPhone),
                    ],
                    if (kasbon.branchName != null && kasbon.branchName!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _receiptRow('Cabang Toko', kasbon.branchName!),
                    ],
                    if (kasbon.dueDate != null) ...[

                      const SizedBox(height: 4),
                      _receiptRow(
                        'Jatuh Tempo',
                        '${kasbon.dueDate!.day.toString().padLeft(2, '0')}/${kasbon.dueDate!.month.toString().padLeft(2, '0')}/${kasbon.dueDate!.year}',
                        highlight: !isPelunasan,
                      ),
                    ],
                    const SizedBox(height: 10),
                    _receiptDivider(),
                    const SizedBox(height: 10),
                    const Text('Rincian Barang:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
                    const SizedBox(height: 8),
                    ...kasbon.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name}\n${item.quantity} ${item.product.unit} \u00d7 ${AppTheme.formatRupiah(item.unitPrice)}',
                              style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark, height: 1.4),
                            ),
                          ),
                          Text(
                            AppTheme.formatRupiah(item.totalPrice),
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                    )),
                    const SizedBox(height: 10),
                    _receiptDivider(),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isPelunasan ? 'TOTAL DILUNASI' : 'TOTAL UTANG',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                        ),
                        Text(
                          AppTheme.formatRupiah(kasbon.amount),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isPelunasan ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _receiptDivider(),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPelunasan ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isPelunasan ? AppTheme.successGreen : AppTheme.dangerRed),
                        ),
                        child: Text(
                          isPelunasan ? '\u2713 LUNAS' : '\u26a0 BELUM LUNAS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isPelunasan ? AppTheme.successGreen : AppTheme.dangerRed,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text('Dicetak: $dateStr', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted))),
                    const SizedBox(height: 4),
                    const Center(child: Text('Bherung POS — Sistem Kasir Toko Sembako', style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted))),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _receiptDivider() => Row(
    children: List.generate(40, (i) => Expanded(
      child: Container(margin: const EdgeInsets.symmetric(horizontal: 1), height: 1, color: i.isEven ? AppTheme.borderColor : Colors.transparent),
    )),
  );

  Widget _receiptRow(String label, String value, {bool bold = false, bool highlight = false}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
      const Text(':', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          style: TextStyle(fontSize: 11.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: highlight ? AppTheme.dangerRed : AppTheme.textDark),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final filtered = widget.kasbonRecords.where((k) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          k.customerName.toLowerCase().contains(query) ||
          k.customerPhone.contains(_searchQuery) ||
          (k.branchName != null && k.branchName!.toLowerCase().contains(query));
      final matchesTab = _activeTab == 0 ? !k.isPaid : k.isPaid;
      return matchesSearch && matchesTab;
    }).toList();

    final activeCount = widget.kasbonRecords.where((k) => !k.isPaid).length;
    final paidCount = widget.kasbonRecords.where((k) => k.isPaid).length;

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
              'Buku Kasbon Pelanggan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Catatan utang sembako, jatuh tempo & pelunasan',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Top Banner Ringkasan Total Piutang
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B18), Color(0xFF2C241D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4), width: 1.2),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: Color(0xFFF59E0B), size: 18),
                              SizedBox(width: 6),
                              Text('Total Kasbon Belum Lunas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text('Piutang Warung Aktif', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        AppTheme.formatRupiah(_totalKasbonActive),
                        style: const TextStyle(
                          color: Color(0xFFFBBF24),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Search & Filter Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari nama pelanggan / no. HP...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text('Belum Lunas ($activeCount)')),
                              selected: _activeTab == 0,
                              selectedColor: const Color(0xFFFEF3C7),
                              onSelected: (val) => setState(() => _activeTab = 0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: Center(child: Text('Riwayat Lunas ($paidCount)')),
                              selected: _activeTab == 1,
                              selectedColor: AppTheme.primaryGold,
                              onSelected: (val) => setState(() => _activeTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // List Records (Collapsible Cards)
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    color: AppTheme.primaryTeal,
                    backgroundColor: Colors.white,
                    child: filtered.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _activeTab == 0 ? Icons.check_circle_outline_rounded : Icons.history_rounded,
                                        size: 48,
                                        color: AppTheme.textSubtle,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _activeTab == 0
                                            ? 'Tidak ada kasbon yang belum lunas.'
                                            : 'Belum ada riwayat kasbon yang lunas.',
                                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Tarik ke bawah untuk memuat ulang dari Spreadsheet',
                                        style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                            itemCount: filtered.length,
                            separatorBuilder: (c, i) => const SizedBox(height: 10),
                            itemBuilder: (c, i) {
                              final kasbon = filtered[i];
                            final bool isExpanded = _expandedIds.contains(kasbon.id);

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: kasbon.isPaid ? Colors.white : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: kasbon.isPaid ? AppTheme.borderColor : const Color(0xFFFDE68A),
                                  width: kasbon.isPaid ? 1 : 1.2,
                                ),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Column(
                                children: [
                                  // Header Kartu (Dapat di-klik untuk Expand / Collapse)
                                  InkWell(
                                    onTap: () => _toggleExpand(kasbon.id),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: kasbon.isPaid ? Colors.grey.shade200 : const Color(0xFFFEF3C7),
                                            child: Icon(
                                              kasbon.isPaid ? Icons.check_rounded : Icons.person_rounded,
                                              color: kasbon.isPaid ? AppTheme.successGreen : const Color(0xFFD97706),
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
                                                    Expanded(
                                                      child: Text(
                                                        kasbon.customerName,
                                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      AppTheme.formatRupiah(kasbon.amount),
                                                      style: TextStyle(
                                                        fontSize: 13.5,
                                                        fontWeight: FontWeight.w900,
                                                        color: kasbon.isPaid ? AppTheme.textMuted : AppTheme.dangerRed,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    if (kasbon.dueDate != null) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFEF3C7),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          'Jatuh Tempo: ${kasbon.dueDate!.day}/${kasbon.dueDate!.month}/${kasbon.dueDate!.year}',
                                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    if (kasbon.branchName != null && kasbon.branchName!.isNotEmpty) ...[
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFE0F2FE),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          '📍 ${kasbon.branchName}',
                                                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                    ],
                                                    Text(
                                                      '${kasbon.items.length} Barang Belanja',
                                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Tombol Lunasi Cepat
                                          if (!kasbon.isPaid) ...[
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() => kasbon.isPaid = true);
                                                widget.onKasbonPaid(kasbon);
                                                AppsScriptService().payKasbon(kasbon.id);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Kasbon ${kasbon.customerName} (${AppTheme.formatRupiah(kasbon.amount)}) ditandai LUNAS!'),
                                                    backgroundColor: AppTheme.successGreen,
                                                  ),
                                                );
                                                _showKasbonReceipt(context, kasbon, isPelunasan: true);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppTheme.successGreen,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                              ),
                                              child: const Text('Lunasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                            const SizedBox(width: 4),
                                          ],

                                          // Ikon Chevron Collapsible (Expand/Collapse)
                                          Icon(
                                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                            size: 22,
                                            color: AppTheme.textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Konten Rincian Detail yang Di-collapse / Expand
                                  if (isExpanded) ...[
                                    const Divider(height: 1, color: Color(0xFFFDE68A)),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (kasbon.customerPhone.isNotEmpty) ...[
                                            Row(
                                              children: [
                                                const Icon(Icons.phone_android_rounded, size: 14, color: AppTheme.primaryGold),
                                                const SizedBox(width: 6),
                                                Text('WhatsApp / HP: ${kasbon.customerPhone}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                          ],

                                          const Text('Rincian Barang yang Diutang:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E))),
                                          const SizedBox(height: 6),

                                          // Daftar Item Barang
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFFDE68A)),
                                            ),
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: kasbon.items.length,
                                              separatorBuilder: (c, i) => const Divider(height: 8),
                                              itemBuilder: (c, i) {
                                                final item = kasbon.items[i];
                                                return Row(
                                                  children: [
                                                    Container(
                                                      width: 6,
                                                      height: 6,
                                                      decoration: const BoxDecoration(
                                                        color: AppTheme.primaryGold,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        '${item.product.name} (x${item.quantity} ${item.product.unit})',
                                                        style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Text(
                                                      AppTheme.formatRupiah(item.totalPrice),
                                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Tanggal Transaksi Dicatat
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Dicatat: ${kasbon.createdAt.day}/${kasbon.createdAt.month}/${kasbon.createdAt.year} ${kasbon.createdAt.hour.toString().padLeft(2, "0")}:${kasbon.createdAt.minute.toString().padLeft(2, "0")}',
                                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  // Tombol Struk
                                                  InkWell(
                                                    onTap: () => _showKasbonReceipt(context, kasbon, isPelunasan: kasbon.isPaid),
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: AppTheme.bgSubtle,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: AppTheme.borderColor),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.receipt_long_rounded, size: 13, color: AppTheme.primaryTeal),
                                                          SizedBox(width: 4),
                                                          Text('Struk', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (!kasbon.isPaid) ...[
                                                    const SizedBox(width: 8),
                                                    InkWell(
                                                      onTap: () {
                                                        setState(() => kasbon.isPaid = true);
                                                        widget.onKasbonPaid(kasbon);
                                                        AppsScriptService().payKasbon(kasbon.id);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(
                                                            content: Text('Kasbon ${kasbon.customerName} ditandai LUNAS!'),
                                                            backgroundColor: AppTheme.successGreen,
                                                          ),
                                                        );
                                                        _showKasbonReceipt(context, kasbon, isPelunasan: true);
                                                      },
                                                      child: const Row(
                                                        children: [
                                                          Icon(Icons.check_circle_outline_rounded, size: 13, color: AppTheme.successGreen),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'Tandai Sudah Lunas',
                                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
