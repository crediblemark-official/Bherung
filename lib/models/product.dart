import 'package:flutter/material.dart';
export 'transaction_type.dart';
export 'category.dart';
export 'cart_item.dart';
export 'kasbon_record.dart';
export 'held_order.dart';
export 'sample_data.dart';
export 'stock_mutation.dart';
export 'shift_record.dart';
export 'user_role.dart';

class Product {
  final String id;
  final String name;
  final double price; // Harga jual eceran
  final double? costPrice; // Harga modal / kulakan (hanya owner & kalkulasi laba)
  final double? wholesalePrice; // Harga grosir jika beli banyak
  final int? wholesaleMinQty; // Minimal jumlah untuk dapat harga grosir
  final String unit; // 'kg', 'bks', 'pcs', 'botol', 'renceng', 'tabung', 'galon', 'dus'
  final String categoryId;
  final IconData icon;
  final Color color;
  final String code; // Barcode bawaan produk / SKU
  final int stock;
  final int minStockAlert; // Batas peringatan stok menipis
  final DateTime? expiryDate; // Tanggal kedaluwarsa (opsional)
  final DateTime? lastSoldDate; // Tanggal terakhir terjual (untuk slow-moving)
  final bool isSensitiveItem; // Barang prioritas audit shift (Rokok, Minyak, Beras)
  final String? description;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.costPrice,
    this.wholesalePrice,
    this.wholesaleMinQty,
    this.unit = 'pcs',
    required this.categoryId,
    required this.icon,
    required this.color,
    required this.code,
    this.stock = 100,
    this.minStockAlert = 5,
    this.expiryDate,
    this.lastSoldDate,
    this.isSensitiveItem = false,
    this.description,
  });

  bool get isAvailable => stock > 0;
  bool get isLowStock => stock <= minStockAlert;
  bool get hasWholesale => wholesalePrice != null && wholesaleMinQty != null;

  // Margin Laba Kotor
  double get profitMargin => price - (costPrice ?? (price * 0.85));

  // Periksa status kedaluwarsa
  int? get daysUntilExpiry {
    if (expiryDate == null) return null;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  bool get isExpired => daysUntilExpiry != null && daysUntilExpiry! <= 0;
  bool get isNearExpiry => daysUntilExpiry != null && daysUntilExpiry! > 0 && daysUntilExpiry! <= 30;

  // Periksa status Slow-Moving (misal > 30 hari tidak laku)
  bool get isSlowMoving {
    if (lastSoldDate == null) return false;
    return DateTime.now().difference(lastSoldDate!).inDays >= 30;
  }

  // Hitung harga per unit berdasarkan jumlah qty
  double getEffectiveUnitPrice(int quantity) {
    if (hasWholesale && quantity >= wholesaleMinQty!) {
      return wholesalePrice!;
    }
    return price;
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? costPrice,
    double? wholesalePrice,
    int? wholesaleMinQty,
    String? unit,
    String? categoryId,
    IconData? icon,
    Color? color,
    String? code,
    int? stock,
    int? minStockAlert,
    DateTime? expiryDate,
    DateTime? lastSoldDate,
    bool? isSensitiveItem,
    String? description,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      wholesaleMinQty: wholesaleMinQty ?? this.wholesaleMinQty,
      unit: unit ?? this.unit,
      categoryId: categoryId ?? this.categoryId,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      code: code ?? this.code,
      stock: stock ?? this.stock,
      minStockAlert: minStockAlert ?? this.minStockAlert,
      expiryDate: expiryDate ?? this.expiryDate,
      lastSoldDate: lastSoldDate ?? this.lastSoldDate,
      isSensitiveItem: isSensitiveItem ?? this.isSensitiveItem,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'costPrice': costPrice,
      'wholesalePrice': wholesalePrice,
      'wholesaleMinQty': wholesaleMinQty,
      'unit': unit,
      'categoryId': categoryId,
      'code': code,
      'stock': stock,
      'minStockAlert': minStockAlert,
      'expiryDate': expiryDate?.toIso8601String(),
      'lastSoldDate': lastSoldDate?.toIso8601String(),
      'isSensitiveItem': isSensitiveItem,
      'description': description,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper to determine icon & color from category
    IconData icon = Icons.inventory_2_rounded;
    Color color = const Color(0xFF0D9488);
    final catId = json['categoryId']?.toString() ?? 'sembako';

    switch (catId) {
      case 'sembako':
        icon = Icons.rice_bowl_rounded;
        color = const Color(0xFFF59E0B);
        break;
      case 'mie_makanan':
        icon = Icons.ramen_dining_rounded;
        color = const Color(0xFFEA580C);
        break;
      case 'minuman':
        icon = Icons.local_drink_rounded;
        color = const Color(0xFF06B6D4);
        break;
      case 'bumbu':
        icon = Icons.soup_kitchen_rounded;
        color = const Color(0xFF10B981);
        break;
      case 'rokok':
        icon = Icons.smoking_rooms_rounded;
        color = const Color(0xFFEF4444);
        break;
      case 'sabun_rumah':
        icon = Icons.cleaning_services_rounded;
        color = const Color(0xFF6366F1);
        break;
      case 'gas_galon':
        icon = Icons.propane_tank_rounded;
        color = const Color(0xFF0284C7);
        break;
    }

    return Product(
      id: json['id']?.toString() ?? 'prd-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Produk Tanpa Nama',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble(),
      wholesaleMinQty: (json['wholesaleMinQty'] as num?)?.toInt(),
      unit: json['unit']?.toString() ?? 'pcs',
      categoryId: catId,
      icon: icon,
      color: color,
      code: json['code']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      minStockAlert: (json['minStockAlert'] as num?)?.toInt() ?? 5,
      expiryDate: json['expiryDate'] != null ? DateTime.tryParse(json['expiryDate'].toString()) : null,
      lastSoldDate: json['lastSoldDate'] != null ? DateTime.tryParse(json['lastSoldDate'].toString()) : null,
      isSensitiveItem: json['isSensitiveItem'] == true,
      description: json['description']?.toString(),
    );
  }
}
