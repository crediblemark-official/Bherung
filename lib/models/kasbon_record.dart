import 'package:flutter/material.dart';
import 'product.dart';

class KasbonRecord {
  final String id;
  final String customerName;
  final String customerPhone;
  final double amount;
  final List<CartItem> items;
  final DateTime createdAt;
  final DateTime? dueDate;
  bool isPaid;

  KasbonRecord({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.amount,
    required this.items,
    required this.createdAt,
    this.dueDate,
    this.isPaid = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'items': items.map((i) => {
        'product': i.product.toJson(),
        'quantity': i.quantity,
        'note': i.note,
        'forceWholesale': i.forceWholesalePrice,
      }).toList(),
    };
  }

  factory KasbonRecord.fromJson(Map<String, dynamic> json) {
    final List<CartItem> loadedItems = [];
    final itemsJson = json['items'] as List<dynamic>?;
    if (itemsJson != null) {
      for (final itemMap in itemsJson) {
        Product prod;
        if (itemMap['product'] != null) {
          prod = Product.fromJson(itemMap['product'] as Map<String, dynamic>);
        } else {
          prod = Product(
            id: itemMap['productId']?.toString() ?? 'prd-unknown',
            name: itemMap['productName']?.toString() ?? 'Barang Kasbon',
            price: (itemMap['unitPrice'] as num?)?.toDouble() ?? 0.0,
            categoryId: 'sembako',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFF0D9488),
            code: '',
          );
        }

        loadedItems.add(CartItem(
          product: prod,
          quantity: (itemMap['quantity'] as num?)?.toInt() ?? 1,
          note: itemMap['note']?.toString(),
          forceWholesalePrice: itemMap['forceWholesale'] == true,
        ));
      }
    }

    return KasbonRecord(
      id: json['id']?.toString() ?? 'KSB-${DateTime.now().millisecondsSinceEpoch}',
      customerName: json['customerName']?.toString() ?? 'Umum',
      customerPhone: json['customerPhone']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      items: loadedItems,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'].toString()) : null,
      isPaid: json['isPaid'] == true,
    );
  }
}
