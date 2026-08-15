import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  // Pemetaan Cerdas Ikon & Warna Berdasarkan Nama / ID Kategori
  static Category fromId(String rawId, [String? customName]) {
    final cleanId = rawId.trim().toLowerCase();

    // 1. Kategori Standard Khas Toko Sembako & Madura
    switch (cleanId) {
      case 'all':
      case 'semua':
        return const Category(
          id: 'all',
          name: 'Semua',
          icon: Icons.grid_view_rounded,
          color: Color(0xFF0D9488), // Teal
        );
      case 'sembako':
      case 'beras':
      case 'beras_sembako':
        return Category(
          id: cleanId,
          name: customName ?? 'Beras & Sembako',
          icon: Icons.rice_bowl_rounded,
          color: const Color(0xFFF59E0B), // Amber
        );
      case 'mie':
      case 'makanan':
      case 'mie_makanan':
      case 'instan':
        return Category(
          id: cleanId,
          name: customName ?? 'Mie & Makanan',
          icon: Icons.ramen_dining_rounded,
          color: const Color(0xFFEA580C), // Orange
        );
      case 'minuman':
      case 'minuman_dingin':
      case 'beverages':
      case 'kopi':
        return Category(
          id: cleanId,
          name: customName ?? 'Minuman Dingin',
          icon: Icons.local_drink_rounded,
          color: const Color(0xFF06B6D4), // Cyan
        );
      case 'bumbu':
      case 'bumbu_dapur':
      case 'masak':
        return Category(
          id: cleanId,
          name: customName ?? 'Bumbu Dapur',
          icon: Icons.soup_kitchen_rounded,
          color: const Color(0xFF10B981), // Emerald
        );
      case 'rokok':
      case 'rokok_tembakau':
      case 'tembakau':
      case 'cigars':
        return Category(
          id: cleanId,
          name: customName ?? 'Rokok & Tembakau',
          icon: Icons.smoking_rooms_rounded,
          color: const Color(0xFFEF4444), // Red
        );
      case 'sabun':
      case 'sabun_cuci':
      case 'sabun_rumah':
      case 'kebersihan':
      case 'toiletries':
        return Category(
          id: cleanId,
          name: customName ?? 'Sabun & Cuci',
          icon: Icons.cleaning_services_rounded,
          color: const Color(0xFF6366F1), // Indigo
        );
      case 'gas':
      case 'galon':
      case 'gas_galon':
      case 'lpg':
        return Category(
          id: cleanId,
          name: customName ?? 'Gas LPG & Galon',
          icon: Icons.propane_tank_rounded,
          color: const Color(0xFF0284C7), // Sky Blue
        );
      case 'snack':
      case 'cemilan':
      case 'camilan':
      case 'biskuit':
        return Category(
          id: cleanId,
          name: customName ?? 'Snack & Cemilan',
          icon: Icons.cookie_rounded,
          color: const Color(0xFFD97706),
        );
      case 'obat':
      case 'obat_p3k':
      case 'farmasi':
      case 'kesehatan':
        return Category(
          id: cleanId,
          name: customName ?? 'Obat & P3K',
          icon: Icons.medical_services_rounded,
          color: const Color(0xFFE11D48),
        );
      case 'atk':
      case 'alat_tulis':
      case 'kantor':
        return Category(
          id: cleanId,
          name: customName ?? 'Alat Tulis / ATK',
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF8B5CF6),
        );
      case 'elektronik':
      case 'listrik':
      case 'alat_listrik':
        return Category(
          id: cleanId,
          name: customName ?? 'Listrik & Elektronik',
          icon: Icons.electric_bolt_rounded,
          color: const Color(0xFFEAB308),
        );
      case 'pulsa':
      case 'token':
      case 'voucher':
        return Category(
          id: cleanId,
          name: customName ?? 'Pulsa & Token Listrik',
          icon: Icons.phonelink_ring_rounded,
          color: const Color(0xFF3B82F6),
        );
      case 'buah':
      case 'sayur':
      case 'sayuran':
      case 'segar':
        return Category(
          id: cleanId,
          name: customName ?? 'Sayur & Buah Segar',
          icon: Icons.eco_rounded,
          color: const Color(0xFF22C55E),
        );
      case 'frozen':
      case 'frozen_food':
      case 'beku':
        return Category(
          id: cleanId,
          name: customName ?? 'Frozen Food',
          icon: Icons.ac_unit_rounded,
          color: const Color(0xFF38BDF8),
        );
    }

    // 2. Kategori Dinamis Kustom Baru (Auto Format Name & Curated Palette)
    final formattedName = customName ?? _formatCategoryName(rawId);
    final curatedColor = _generateCuratedColor(cleanId);
    final icon = _guessCategoryIcon(cleanId);

    return Category(
      id: cleanId,
      name: formattedName,
      icon: icon,
      color: curatedColor,
    );
  }

  // Generate Kategori Dinamis Otomatis dari Daftar Produk
  static List<Category> buildDynamicCategories(List<dynamic> products) {
    final Map<String, Category> categoriesMap = {
      'all': fromId('all'),
    };

    for (final p in products) {
      final catId = (p.categoryId ?? '').toString().trim();
      if (catId.isNotEmpty && catId.toLowerCase() != 'all') {
        final cleanKey = catId.toLowerCase();
        if (!categoriesMap.containsKey(cleanKey)) {
          categoriesMap[cleanKey] = fromId(catId);
        }
      }
    }

    return categoriesMap.values.toList();
  }

  // Format ID snake_case / kebab-case menjadi Title Case yang rapi
  static String _formatCategoryName(String text) {
    if (text.isEmpty) return 'Lain-lain';
    final words = text.replaceAll('_', ' ').replaceAll('-', ' ').split(' ');
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  // Palet Warna Harmonis Modern
  static Color _generateCuratedColor(String seed) {
    const List<Color> palette = [
      Color(0xFF0D9488), // Teal
      Color(0xFFF59E0B), // Amber
      Color(0xFFEA580C), // Orange
      Color(0xFF06B6D4), // Cyan
      Color(0xFF10B981), // Emerald
      Color(0xFFEF4444), // Red
      Color(0xFF6366F1), // Indigo
      Color(0xFF0284C7), // Sky
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEC4899), // Pink
      Color(0xFF14B8A6), // Mint
      Color(0xFFF97316), // Bright Orange
    ];
    final hash = seed.hashCode.abs();
    return palette[hash % palette.length];
  }

  // Tebak Ikon Sesuai Kata Kunci
  static IconData _guessCategoryIcon(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('makan') || lower.contains('food') || lower.contains('snack')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('minum') || lower.contains('drink') || lower.contains('beverage') || lower.contains('jus')) {
      return Icons.local_drink_rounded;
    }
    if (lower.contains('cuci') || lower.contains('clean') || lower.contains('sabun') || lower.contains('deterjen')) {
      return Icons.cleaning_services_rounded;
    }
    if (lower.contains('rokok') || lower.contains('smoke')) {
      return Icons.smoking_rooms_rounded;
    }
    if (lower.contains('obat') || lower.contains('med') || lower.contains('sehat')) {
      return Icons.medical_services_rounded;
    }
    if (lower.contains('elektronik') || lower.contains('listrik') || lower.contains('lampu')) {
      return Icons.electric_bolt_rounded;
    }
    if (lower.contains('gas') || lower.contains('galon') || lower.contains('air')) {
      return Icons.propane_tank_rounded;
    }
    if (lower.contains('dapur') || lower.contains('bumbu') || lower.contains('masak')) {
      return Icons.soup_kitchen_rounded;
    }
    if (lower.contains('pakaian') || lower.contains('baju') || lower.contains('kain')) {
      return Icons.checkroom_rounded;
    }
    return Icons.inventory_2_rounded;
  }
}
