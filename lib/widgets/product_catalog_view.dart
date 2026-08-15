import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_card.dart';

class ProductCatalogView extends StatelessWidget {
  final List<Product> filteredProducts;
  final int totalStoreProducts;
  final bool isListView;
  final int Function(String productId) getCartQuantity;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onIncrement;
  final ValueChanged<Product> onDecrement;
  final VoidCallback onResetSearch;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onQuickAdd;

  const ProductCatalogView({
    super.key,
    required this.filteredProducts,
    this.totalStoreProducts = 0,
    required this.isListView,
    required this.getCartQuantity,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onResetSearch,
    this.onRefresh,
    this.onOpenSettings,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (filteredProducts.isEmpty) {
      content = LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: _buildEmptyState(),
          ),
        ),
      );
    } else if (isListView) {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: filteredProducts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 5),
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          final qty = getCartQuantity(product.id);
          return ProductListItem(
            product: product,
            cartQuantity: qty,
            onTap: () => onAddToCart(product),
            onIncrement: () => onIncrement(product),
            onDecrement: () => onDecrement(product),
          );
        },
      );
    } else {
      content = LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          // Penyesuaian kolom & rasio aspek agar kartu padat & tulisan besar jelas
          final int crossAxisCount = width > 1300
              ? 5
              : width > 980
                  ? 4
                  : width > 650
                      ? 3
                      : 2;

          final double childAspectRatio = width > 1300
              ? 1.40
              : width > 980
                  ? 1.35
                  : width > 650
                      ? 1.22
                      : 1.08;

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final qty = getCartQuantity(product.id);
              return ProductCard(
                product: product,
                cartQuantity: qty,
                onTap: () => onAddToCart(product),
                onIncrement: () => onIncrement(product),
                onDecrement: () => onDecrement(product),
              );
            },
          );
        },
      );
    }

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppTheme.primaryTeal,
        backgroundColor: Colors.white,
        displacement: 28,
        strokeWidth: 2.5,
        child: content,
      );
    }

    return content;
  }

  Widget _buildEmptyState() {
    // Jika toko benar-benar masih belum memiliki produk sama sekali (Fresh Store)
    if (totalStoreProducts == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.storefront_rounded, size: 40, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 14),
              const Text(
                'Etalase Toko Masih Kosong',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Hubungkan Google Spreadsheet toko Anda di menu Pengaturan\natau tambahkan produk baru untuk mulai transaksi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (onOpenSettings != null)
                    ElevatedButton.icon(
                      onPressed: onOpenSettings,
                      icon: const Icon(Icons.cable_rounded, size: 16),
                      label: const Text('Buka Pengaturan Spreadsheet', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  if (onQuickAdd != null)
                    OutlinedButton.icon(
                      onPressed: onQuickAdd,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Tambah Produk Manual', style: TextStyle(fontSize: 11.5)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: const BorderSide(color: AppTheme.borderColor),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Jika produk ada tapi filter pencarian/kategori tidak menemukan hasil
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.bgSubtle,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 32, color: AppTheme.textSubtle),
            ),
            const SizedBox(height: 10),
            const Text(
              'Barang Tidak Ditemukan',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 3),
            const Text(
              'Coba scan ulang barcode atau gunakan kata kunci lain.\nTarik ke bawah untuk menyinkronkan dengan Google Sheets.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: onResetSearch,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              ),
              child: const Text('Tampilkan Semua Barang', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
