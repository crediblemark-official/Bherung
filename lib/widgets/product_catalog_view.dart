import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import 'product_card.dart';

class ProductCatalogView extends StatelessWidget {
  final List<Product> filteredProducts;
  final bool isListView;
  final int Function(String productId) getCartQuantity;
  final ValueChanged<Product> onAddToCart;
  final ValueChanged<Product> onIncrement;
  final ValueChanged<Product> onDecrement;
  final VoidCallback onResetSearch;
  final Future<void> Function()? onRefresh;

  const ProductCatalogView({
    super.key,
    required this.filteredProducts,
    required this.isListView,
    required this.getCartQuantity,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onResetSearch,
    this.onRefresh,
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
              'Barang Sembako Tidak Ditemukan',
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
