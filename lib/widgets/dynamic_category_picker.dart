import 'package:flutter/material.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class DynamicCategoryPicker extends StatefulWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final Function(Category newCategory)? onCategoryCreated;

  const DynamicCategoryPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryCreated,
  });

  @override
  State<DynamicCategoryPicker> createState() => _DynamicCategoryPickerState();
}

class _DynamicCategoryPickerState extends State<DynamicCategoryPicker> {
  void _openCategoryPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryPickerSheet(
        categories: widget.categories,
        selectedCategoryId: widget.selectedCategoryId,
        onCategorySelected: (catId) {
          widget.onCategorySelected(catId);
          Navigator.pop(ctx);
        },
        onCategoryCreated: (newCat) {
          if (widget.onCategoryCreated != null) {
            widget.onCategoryCreated!(newCat);
          }
          widget.onCategorySelected(newCat.id);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validCategories = widget.categories.where((c) => c.id != 'all').toList();
    final selectedCategory = validCategories.firstWhere(
      (c) => c.id == widget.selectedCategoryId,
      orElse: () => validCategories.isNotEmpty
          ? validCategories.first
          : Category(
              id: widget.selectedCategoryId,
              name: widget.selectedCategoryId,
              icon: Icons.category_rounded,
              color: AppTheme.primaryTeal,
            ),
    );

    return InkWell(
      onTap: () => _openCategoryPickerModal(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selectedCategory.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(selectedCategory.icon, size: 16, color: selectedCategory.color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedCategory.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final ValueChanged<Category> onCategoryCreated;

  const _CategoryPickerSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.onCategoryCreated,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Color _generateCategoryColor(String name) {
    final colors = [
      const Color(0xFF0D9488),
      const Color(0xFF0284C7),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFD97706),
      const Color(0xFFEA580C),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFF059669),
      const Color(0xFF0891B2),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  IconData _generateCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('rokok') || lower.contains('tembakau')) return Icons.smoking_rooms_rounded;
    if (lower.contains('minum') || lower.contains('kopi') || lower.contains('teh') || lower.contains('susu')) return Icons.local_drink_rounded;
    if (lower.contains('makan') || lower.contains('mie') || lower.contains('snack') || lower.contains('roti')) return Icons.ramen_dining_rounded;
    if (lower.contains('beras') || lower.contains('sembako') || lower.contains('gula') || lower.contains('minyak')) return Icons.rice_bowl_rounded;
    if (lower.contains('sabun') || lower.contains('cuci') || lower.contains('shampoo') || lower.contains('odol')) return Icons.cleaning_services_rounded;
    if (lower.contains('gas') || lower.contains('galon') || lower.contains('elpiji')) return Icons.propane_tank_rounded;
    if (lower.contains('bumbu') || lower.contains('garam') || lower.contains('saus') || lower.contains('kecap')) return Icons.soup_kitchen_rounded;
    if (lower.contains('obat') || lower.contains('farmasi') || lower.contains('p3k')) return Icons.medical_services_rounded;
    if (lower.contains('bayi') || lower.contains('pampers') || lower.contains('anak')) return Icons.child_care_rounded;
    if (lower.contains('listrik') || lower.contains('lampu') || lower.contains('baterai')) return Icons.bolt_rounded;
    if (lower.contains('atk') || lower.contains('tulis') || lower.contains('buku')) return Icons.edit_note_rounded;
    return Icons.category_rounded;
  }

  void _createNewCategory(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final id = cleanName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final newCategory = Category(
      id: id.isNotEmpty ? id : 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      icon: _generateCategoryIcon(cleanName),
      color: _generateCategoryColor(cleanName),
    );

    widget.onCategoryCreated(newCategory);
  }

  @override
  Widget build(BuildContext context) {
    final validCategories = widget.categories.where((c) => c.id != 'all').toList();
    final filtered = validCategories.where((c) {
      return c.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    final bool exactMatchExists = validCategories.any(
      (c) => c.name.trim().toLowerCase() == _query.trim().toLowerCase(),
    );

    final bool canCreateNew = _query.trim().isNotEmpty && !exactMatchExists;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                const Icon(Icons.category_rounded, color: AppTheme.primaryTeal, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pilih atau Buat Kategori',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),

          // Search / Type New Category Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Cari kategori atau ketik nama baru...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.primaryTeal),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              onChanged: (val) => setState(() => _query = val),
              onSubmitted: (val) {
                if (canCreateNew) {
                  _createNewCategory(val);
                }
              },
            ),
          ),

          // Action: Buat Kategori Baru jika belum ada
          if (canCreateNew)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Material(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _createNewCategory(_query),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                              children: [
                                const TextSpan(text: 'Tambah Kategori Baru: '),
                                TextSpan(
                                  text: '"${_query.trim()}"',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.successGreen),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Categories List
          Expanded(
            child: filtered.isEmpty && !canCreateNew
                ? const Center(
                    child: Text(
                      'Kategori tidak ditemukan',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (c, i) => const Divider(height: 1, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final cat = filtered[index];
                      final isSelected = cat.id == widget.selectedCategoryId;

                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        tileColor: isSelected ? AppTheme.primaryTealLight.withValues(alpha: 0.5) : null,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(cat.icon, size: 18, color: cat.color),
                        ),
                        title: Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryTeal : AppTheme.textDark,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryTeal, size: 18)
                            : null,
                        onTap: () => widget.onCategorySelected(cat.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
