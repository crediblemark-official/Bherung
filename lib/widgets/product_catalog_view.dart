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

  const ProductCatalogView({
    super.key,
    required this.filteredProducts,
    required this.isListView,
    required this.getCartQuantity,
    required this.onAddToCart,
    required this.onIncrement,
    required this.onDecrement,
    required this.onResetSearch,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    if (isListView) {
      return ListView.separated(
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
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: screenWidth > 1300
            ? 5
            : screenWidth > 900
                ? 4
                : 3, // 3 Kolom Grid di Mobile & Tablet
        childAspectRatio: screenWidth > 1200
            ? 1.25
            : screenWidth > 900
                ? 1.12
                : screenWidth > 600
                    ? 0.92
                    : 0.76, // Proporsi tinggi ideal untuk 3 kolom di layar HP
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
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
              'Coba scan ulang barcode atau gunakan kata kunci lain.',
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
