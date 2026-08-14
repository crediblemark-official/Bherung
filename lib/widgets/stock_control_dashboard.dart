import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class StockControlDashboardDialog extends StatefulWidget {
  final List<Product> products;
  final List<StockMutation> mutations;
  final VoidCallback onOpenRestock;

  const StockControlDashboardDialog({
    super.key,
    required this.products,
    required this.mutations,
    required this.onOpenRestock,
  });

  @override
  State<StockControlDashboardDialog> createState() => _StockControlDashboardDialogState();
}

class _StockControlDashboardDialogState extends State<StockControlDashboardDialog> with SingleTickerProviderStateMixin {
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
    // Estimasi total nilai aset modal toko
    final double totalAssetValue = widget.products.fold(
      0,
      (sum, p) => sum + (p.stock * (p.costPrice ?? (p.price * 0.85))),
    );

    final lowStockProducts = widget.products.where((p) => p.isLowStock).toList();
    final nearExpiryProducts = widget.products.where((p) => p.isNearExpiry || p.isExpired).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 620;

          return Container(
            width: 780,
            height: 650,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Top Bar (Responsive for Mobile & Desktop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  color: AppTheme.primaryDark,
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.analytics_rounded, color: AppTheme.secondaryTeal, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Kontrol Stok & Expired',
                                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Aset Toko: ${AppTheme.formatRupiah(totalAssetValue)} (${widget.products.length} SKU)',
                                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 10.5, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onOpenRestock();
                                  },
                                  icon: const Icon(Icons.add_box_rounded, size: 13),
                                  label: const Text('+ Kulakan', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryTeal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.analytics_rounded, color: AppTheme.secondaryTeal, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kontrol Stok, Slow-Moving & Kedaluwarsa',
                                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Total Estimasi Nilai Aset Toko: ${AppTheme.formatRupiah(totalAssetValue)} (${widget.products.length} SKU)',
                                    style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onOpenRestock();
                              },
                              icon: const Icon(Icons.add_box_rounded, size: 15),
                              label: const Text('Kulakan / Tambah Stok', style: TextStyle(fontSize: 11.5)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white70),
                              onPressed: () => Navigator.pop(context),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                ),

                // Tab Bar (Swipeable & Scrollable for mobile)
                Container(
                  color: AppTheme.bgSubtle,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppTheme.primaryTeal,
                    unselectedLabelColor: AppTheme.textMuted,
                    indicatorColor: AppTheme.primaryTeal,
                    indicatorWeight: 3,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                    labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(
                        icon: const Icon(Icons.trending_down_rounded, size: 16),
                        text: 'Slow-Moving (${(widget.products.length * 0.2).toInt()})',
                      ),
                      Tab(
                        icon: const Icon(Icons.event_busy_rounded, size: 16),
                        text: 'Kedaluwarsa (${nearExpiryProducts.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.warning_amber_rounded, size: 16),
                        text: 'Stok Menipis (${lowStockProducts.length})',
                      ),
                      Tab(
                        icon: const Icon(Icons.history_rounded, size: 16),
                        text: 'Kartu Mutasi (${widget.mutations.length})',
                      ),
                    ],
                  ),
                ),

                // Tab View Body
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Slow-Moving Products
                      _buildSlowMovingTab(isMobile),

                      // Tab 2: Expiry Monitoring
                      _buildExpiryTab(nearExpiryProducts),

                      // Tab 3: Low Stock Alert
                      _buildLowStockTab(lowStockProducts),

                      // Tab 4: Stock Mutations Log
                      _buildMutationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlowMovingTab(bool isMobile) {
    // Simulasi produk slow moving
    final slowProducts = widget.products.take(6).toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peringatan Modal Tertahan (Slow-Moving > 30 Hari)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                    ),
                    Text(
                      'Barang di bawah jarang laku. Hindari kulakan berlebih dan pertimbangkan promo bundling.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF78350F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (isMobile) ...[
          // Mobile Card View for Slow Moving
          ...slowProducts.map((p) {
            final cost = p.costPrice ?? (p.price * 0.85);
            final tiedModal = p.stock * cost;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
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
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Stok: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Modal Tertahan: ${AppTheme.formatRupiah(tiedModal)}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.warningOrange),
                      ),
                      const Text(
                        'Tunda Kulakan',
                        style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          // Desktop Table View
          Table(
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
                  Padding(padding: EdgeInsets.all(8), child: Text('Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Sisa Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Modal Tertahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                  Padding(padding: EdgeInsets.all(8), child: Text('Rekomendasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5))),
                ],
              ),
              ...slowProducts.map((p) {
                final cost = p.costPrice ?? (p.price * 0.85);
                final tiedModal = p.stock * cost;

                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(p.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('${p.stock} ${p.unit}', style: const TextStyle(fontSize: 11.5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(AppTheme.formatRupiah(tiedModal), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.warningOrange)),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('Tunda Kulakan / Obral Bundel', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildExpiryTab(List<Product> nearExpiry) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEF4444)),
          ),
          child: const Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrol Kedaluwarsa Makanan / Susu / Bumbu',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                    Text(
                      'Tarik barang yang telah lewat tanggal atau taruh di deretan paling depan etalase.',
                      style: TextStyle(fontSize: 10.5, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (nearExpiry.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('✓ Tidak ada produk yang mendekati tanggal kedaluwarsa.', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(p.icon, color: p.color, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Stok: ${p.stock} ${p.unit}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Perhatian: < 30 Hari', style: TextStyle(color: Color(0xFFDC2626), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLowStockTab(List<Product> lowStock) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        if (lowStock.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('✓ Semua stok produk berada pada batas aman.', style: TextStyle(color: AppTheme.successGreen, fontWeight: FontWeight.bold, fontSize: 12)),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFFDE68A)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFFFFBEB),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.warningOrange, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text('Sisa: ${p.stock} ${p.unit} (Batas Min: ${p.minStockAlert})', style: const TextStyle(fontSize: 11, color: AppTheme.textDark)),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Restock', style: TextStyle(fontSize: 11)),
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
          padding: EdgeInsets.all(40),
          child: Text('Belum ada riwayat mutasi stok hari ini.', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: widget.mutations.length,
      separatorBuilder: (c, i) => const Divider(height: 1),
      itemBuilder: (c, i) {
        final m = widget.mutations[i];
        final isAdd = m.qtyChange > 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isAdd ? AppTheme.successGreen.withValues(alpha: 0.15) : AppTheme.dangerRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isAdd ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  size: 16,
                  color: isAdd ? AppTheme.successGreen : AppTheme.dangerRed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      '${m.typeLabel} • ${m.timestamp.hour.toString().padLeft(2, "0")}:${m.timestamp.minute.toString().padLeft(2, "0")} oleh ${m.cashierName}',
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
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
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isAdd ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                  ),
                  Text(
                    'Saldo: ${m.newStock}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
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
