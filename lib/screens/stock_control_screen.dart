import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class StockControlScreen extends StatefulWidget {
  final List<Product> products;
  final List<StockMutation> mutations;
  final VoidCallback onOpenRestock;

  const StockControlScreen({
    super.key,
    required this.products,
    required this.mutations,
    required this.onOpenRestock,
  });

  @override
  State<StockControlScreen> createState() => _StockControlScreenState();
}

class _StockControlScreenState extends State<StockControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 720;

    // Estimasi total nilai aset modal toko
    final double totalAssetValue = widget.products.fold(
      0,
      (sum, p) => sum + (p.stock * (p.costPrice ?? (p.price * 0.85))),
    );

    final lowStockProducts = widget.products.where((p) => p.isLowStock).toList();
    final nearExpiryProducts = widget.products.where((p) => p.isNearExpiry || p.isExpired).toList();

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
              'Kontrol Stok',
              style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppTheme.secondaryTeal.withValues(alpha: 0.4)),
              ),
              child: Text(
                'Aset: ${AppTheme.formatRupiah(totalAssetValue)}',
                style: const TextStyle(color: Color(0xFF5EEAD4), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                widget.onOpenRestock();
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_box_rounded, size: 13, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '+ Kulakan',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Container(
            height: 36,
            color: const Color(0xFF1E293B),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppTheme.secondaryTeal,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppTheme.secondaryTeal,
              indicatorWeight: 2.5,
              labelPadding: const EdgeInsets.symmetric(horizontal: 10),
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              tabs: [
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_down_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Slow-Moving (${(widget.products.length * 0.2).toInt()})'),
                    ],
                  ),
                ),
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_busy_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Expired (${nearExpiryProducts.length})'),
                    ],
                  ),
                ),
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Menipis (${lowStockProducts.length})'),
                    ],
                  ),
                ),
                Tab(
                  height: 34,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.history_rounded, size: 14),
                      const SizedBox(width: 4),
                      Text('Kartu Mutasi (${widget.mutations.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Slow-Moving Products
            _buildSlowMovingTab(isMobile),

            // Tab 2: Expiry Monitoring
            _buildExpiryTab(nearExpiryProducts, isMobile),

            // Tab 3: Low Stock Alert
            _buildLowStockTab(lowStockProducts, isMobile),

            // Tab 4: Stock Mutations Log
            _buildMutationsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSlowMovingTab(bool isMobile) {
    // Simulasi produk slow moving
    final slowProducts = widget.products.take(8).toList();

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peringatan Modal Tertahan (Slow-Moving > 30 Hari)',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                    Text(
                      'Produk di bawah jarang berputar. Tahan kulakan tambahan dan pertimbangkan obral bundel untuk memutar uang modal toko.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (isMobile) ...[
          // Mobile Card View
          ...slowProducts.map((p) {
            final cost = p.costPrice ?? (p.price * 0.85);
            final tiedModal = p.stock * cost;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text('Stok: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Modal Tertahan: ${AppTheme.formatRupiah(tiedModal)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.warningOrange),
                      ),
                      const Text(
                        'Tunda Kulakan',
                        style: TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          // Desktop Table View
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppTheme.borderColor)),
            child: Table(
              border: TableBorder.all(color: AppTheme.borderColor),
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2.5),
                3: FlexColumnWidth(3),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppTheme.bgSubtle),
                  children: const [
                    Padding(padding: EdgeInsets.all(10), child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Sisa Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Modal Tertahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Padding(padding: EdgeInsets.all(10), child: Text('Rekomendasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
                ...slowProducts.map((p) {
                  final cost = p.costPrice ?? (p.price * 0.85);
                  final tiedModal = p.stock * cost;

                  return TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(p.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text('${p.stock} ${p.unit}', style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(AppTheme.formatRupiah(tiedModal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(10),
                        child: Text('Tunda Kulakan / Obral Bundel', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExpiryTab(List<Product> nearExpiry, bool isMobile) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEF4444)),
          ),
          child: const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Color(0xFFDC2626), size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Kedaluwarsa Makanan / Susu / Bumbu',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                    Text(
                      'Pindahkan produk mendekati expired ke barisan paling depan etalase atau diskon cepat.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (nearExpiry.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Column(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppTheme.successGreen, size: 48),
                  SizedBox(height: 10),
                  Text('Semua Produk Aman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Tidak ada produk yang mendekati tanggal kedaluwarsa.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nearExpiry.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final p = nearExpiry[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Icon(p.icon, color: p.color, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('Stok: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Perhatian: < 30 Hari', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLowStockTab(List<Product> lowStock, bool isMobile) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: 14),
      children: [
        if (lowStock.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: Column(
                children: [
                  Icon(Icons.inventory_rounded, color: AppTheme.successGreen, size: 48),
                  SizedBox(height: 10),
                  Text('Stok Aman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Seluruh stok barang di toko berada di atas batas minimal.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: lowStock.length,
            separatorBuilder: (c, i) => const SizedBox(height: 8),
            itemBuilder: (c, i) {
              final p = lowStock[i];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFFFFFBEB),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          Text('Sisa: ${p.stock} ${p.unit} • Batas Min: ${p.minStockAlert}', style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onOpenRestock();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Restock', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMutationsTab() {
    if (widget.mutations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, color: AppTheme.textMuted, size: 48),
              SizedBox(height: 10),
              Text('Belum Ada Mutasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Riwayat keluar-masuk stok barang akan tercatat di sini.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: widget.mutations.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (c, i) {
        final m = widget.mutations[i];
        final isAdd = m.qtyChange > 0;

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: isAdd ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.dangerRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAdd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 17,
                  color: isAdd ? AppTheme.successGreen : AppTheme.dangerRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.productName, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      '${m.typeLabel} • ${m.timestamp.hour.toString().padLeft(2, "0")}:${m.timestamp.minute.toString().padLeft(2, "0")} oleh ${m.cashierName}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isAdd ? "+" : ""}${m.qtyChange}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isAdd ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                  ),
                  Text(
                    'Saldo: ${m.newStock}',
                    style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
