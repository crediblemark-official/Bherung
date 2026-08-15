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
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            children: [
              // Row 1: Search Field + Kamera Scanner HP Button + Quick Add + View Mode Switcher
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onSubmitted: onBarcodeSubmitted,
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: isSmallMobile ? 'Cari / scan barcode...' : 'Cari sembako / ketik barcode (cth: 8991001, Beras, Indomie, Surya)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primaryGold),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 15),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    searchController.clear();
                                    onSearchChanged('');
                                  },
                                )
                              : const Icon(Icons.keyboard_alt_outlined, size: 16, color: AppTheme.textSubtle),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Kamera Barcode Scanner HP (High Priority Gold Button)
                  Tooltip(
                    message: 'Buka Kamera HP untuk Scan Barcode Produk Bawaan',
                    child: InkWell(
                      onTap: onOpenScanner,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          gradient: AppTheme.goldGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryDark, size: 17),
                            if (!isSmallMobile) ...[
                              const SizedBox(width: 6),
                              const Text(
                                'Scan HP',
                                style: TextStyle(
                                  color: AppTheme.primaryDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol Tambah Produk Cepat
                  Tooltip(
                    message: 'Tambah Produk / Barcode Baru Kilat',
                    child: InkWell(
                      onTap: onOpenQuickAdd,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        padding: EdgeInsets.symmetric(horizontal: isSmallMobile ? 9 : 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGold, size: 16),
                            if (!isSmallMobile) ...[
                              const SizedBox(width: 5),
                              const Text(
                                '+ Produk',
                                style: TextStyle(
                                  color: AppTheme.textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Category Chips Bar + View Mode Toggle (Grid vs Dense List) - Always Visible!
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
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
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              onTap: () => onCategorySelected(cat.id),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: isSelected ? AppTheme.goldGradient : null,
                                  color: isSelected ? null : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryGold : AppTheme.borderColor,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.primaryGold.withValues(alpha: 0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : AppTheme.softShadow,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      cat.icon,
                                      size: 13,
                                      color: isSelected ? AppTheme.primaryDark : cat.color,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                                        color: isSelected ? AppTheme.primaryDark : AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryDark.withValues(alpha: 0.15)
                                            : AppTheme.bgSubtle,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: isSelected ? AppTheme.primaryDark : AppTheme.textMuted,
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
                  ),
                  const SizedBox(width: 4),

                  // View Mode Toggle Switcher (Grid vs List)
                  Container(
                    height: 32,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: 'Tampilan Grid (Kotak Kartu)',
                          child: InkWell(
                            onTap: () => onViewModeChanged(false),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: !isListView ? AppTheme.primaryDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.grid_view_rounded,
                                size: 14,
                                color: !isListView ? AppTheme.goldAccent : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        Tooltip(
                          message: 'Tampilan List / Daftar Rapat',
                          child: InkWell(
                            onTap: () => onViewModeChanged(true),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: isListView ? AppTheme.primaryDark : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.view_list_rounded,
                                size: 14,
                                color: isListView ? AppTheme.goldAccent : AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
