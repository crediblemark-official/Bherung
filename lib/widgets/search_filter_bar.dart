import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final String selectedCategoryId;
  final bool isListView;
  final List<Category> categories;
  final List<Product> allProducts;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onBarcodeSubmitted;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<bool> onViewModeChanged;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenQuickAdd;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.isListView,
    required this.categories,
    required this.allProducts,
    required this.onSearchChanged,
    required this.onBarcodeSubmitted,
    required this.onCategorySelected,
    required this.onViewModeChanged,
    required this.onOpenScanner,
    required this.onOpenQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallMobile = constraints.maxWidth < 460;

        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            children: [
              // Row 1: Search Field + Kamera Scanner HP Button + Quick Add + View Mode Switcher
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onSubmitted: onBarcodeSubmitted,
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: isSmallMobile ? 'Cari / scan barcode...' : 'Cari sembako / ketik barcode (cth: 8991001, Beras, Indomie, Surya)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 17, color: AppTheme.primaryTeal),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 14),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                  },
                                )
                              : const Icon(Icons.keyboard_alt_outlined, size: 16, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tombol Kamera Barcode Scanner HP (High Priority)
                  Tooltip(
                    message: 'Buka Kamera HP untuk Scan Barcode Produk Bawaan',
                    child: InkWell(
                      onTap: onOpenScanner,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 8 : 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                            if (!isSmallMobile) ...[
                              const SizedBox(width: 5),
                              const Text(
                                'Scan HP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Tombol Tambah Produk Cepat
                  Tooltip(
                    message: 'Tambah Produk / Barcode Baru Kilat',
                    child: InkWell(
                      onTap: onOpenQuickAdd,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        height: 36,
                        padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 8 : 9),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryTeal, size: 15),
                            if (!isSmallMobile) ...[
                              const SizedBox(width: 4),
                              const Text(
                                '+ Produk',
                                style: TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // View Mode Toggle (Grid vs Dense List)
                  if (!isSmallMobile) ...[
                    const SizedBox(width: 6),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => onViewModeChanged(false),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: !isListView ? AppTheme.primaryTeal : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 15,
                                color: !isListView ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => onViewModeChanged(true),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isListView ? AppTheme.primaryTeal : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.view_list_rounded,
                                size: 15,
                                color: isListView ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),

          // Row 2: Category Chips Bar (Sembako, Rokok, Gas LPG, dll.)
          SizedBox(
            height: 30,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 6),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final bool isSelected = selectedCategoryId == cat.id;
                final count = cat.id == 'all'
                    ? allProducts.length
                    : allProducts.where((p) => p.categoryId == cat.id).length;

                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: InkWell(
                    onTap: () => onCategorySelected(cat.id),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryTeal : Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
                        ),
                        boxShadow: isSelected ? AppTheme.softShadow : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cat.icon,
                            size: 12,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.25)
                                  : AppTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
          ),
        );
      },
    );
  }
}
