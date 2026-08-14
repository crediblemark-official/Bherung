enum StockMutationType {
  sale, // Pengurangan karena transaksi kasir
  restock, // Penambahan stok kulakan
  auditCorrection, // Penyesuaian selisih hasil opname / shift
  damaged, // Barang rusak / basi / kedaluwarsa
}

class StockMutation {
  final String id;
  final String productId;
  final String productName;
  final StockMutationType type;
  final int qtyChange; // - atau +
  final int previousStock;
  final int newStock;
  final DateTime timestamp;
  final String? note;
  final String cashierName;
  final double? costPrice;

  const StockMutation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.qtyChange,
    required this.previousStock,
    required this.newStock,
    required this.timestamp,
    this.note,
    required this.cashierName,
    this.costPrice,
  });

  String get typeLabel {
    switch (type) {
      case StockMutationType.sale:
        return 'Penjualan Kasir';
      case StockMutationType.restock:
        return 'Kulakan / Restock';
      case StockMutationType.auditCorrection:
        return 'Koreksi Opname / Shift';
      case StockMutationType.damaged:
        return 'Rusak / Kedaluwarsa';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type.name,
      'qtyChange': qtyChange,
      'previousStock': previousStock,
      'newStock': newStock,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
      'cashierName': cashierName,
      'costPrice': costPrice,
    };
  }

  factory StockMutation.fromJson(Map<String, dynamic> json) {
    StockMutationType mType = StockMutationType.sale;
    final typeStr = json['type']?.toString();
    if (typeStr != null) {
      for (final t in StockMutationType.values) {
        if (t.name == typeStr) {
          mType = t;
          break;
        }
      }
    }

    return StockMutation(
      id: json['id']?.toString() ?? 'MUT-${DateTime.now().millisecondsSinceEpoch}',
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      type: mType,
      qtyChange: (json['qtyChange'] as num?)?.toInt() ?? 0,
      previousStock: (json['previousStock'] as num?)?.toInt() ?? 0,
      newStock: (json['newStock'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString(),
      cashierName: json['cashierName']?.toString() ?? 'Kasir',
      costPrice: (json['costPrice'] as num?)?.toDouble(),
    );
  }
}
