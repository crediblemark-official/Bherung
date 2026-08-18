class SensitiveProductAudit {
  final String productId;
  final String productName;
  final int initialStock; // Stok Lama (disahkan pada serah terima sebelumnya)
  final int systemStock; // Stok Sistem Saat Ini (setelah penjualan & restock)
  final int physicalStock; // Stok Fisik Riil Hasil Hitung Hari Ini (menjadi Stok Lama serah terima berikutnya)
  final int difference; // physicalStock - systemStock
  final String unit;
  final double? costPrice; // HPP Modal (Opsional)
  final double retailPrice; // Harga Jual
  final String? note;

  const SensitiveProductAudit({
    required this.productId,
    required this.productName,
    this.initialStock = 0,
    required this.systemStock,
    required this.physicalStock,
    required this.difference,
    this.unit = 'pcs',
    this.costPrice,
    this.retailPrice = 0.0,
    this.note,
  });

  bool get hasDifference => difference != 0;
  bool get hasCostPrice => costPrice != null && costPrice! > 0;

  double? get lossValueByCost {
    if (costPrice == null) return null;
    return difference * costPrice!;
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'initialStock': initialStock,
      'systemStock': systemStock,
      'physicalStock': physicalStock,
      'difference': difference,
      'unit': unit,
      'costPrice': costPrice,
      'retailPrice': retailPrice,
      'note': note,
    };
  }

  factory SensitiveProductAudit.fromJson(Map<String, dynamic> json) {
    final sys = (json['systemStock'] as num?)?.toInt() ?? 0;
    final phys = (json['physicalStock'] as num?)?.toInt() ?? 0;
    final init = (json['initialStock'] as num?)?.toInt() ?? sys;

    return SensitiveProductAudit(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      initialStock: init,
      systemStock: sys,
      physicalStock: phys,
      difference: (json['difference'] as num?)?.toInt() ?? (phys - sys),
      unit: json['unit']?.toString() ?? 'pcs',
      costPrice: (json['costPrice'] as num?)?.toDouble(),
      retailPrice: (json['retailPrice'] as num?)?.toDouble() ?? 0.0,
      note: json['note']?.toString(),
    );
  }
}

class ShiftRecord {
  final String id;
  final String cashierName;
  final String shiftName;
  final DateTime startTime;
  final DateTime endTime;
  final double startingCashDrawer;
  final double systemCashSales;
  final double systemQrisSales;
  final double systemKasbonSales;
  final double totalSystemSales;
  final double physicalCashCounted;
  final double cashDifference;
  final List<SensitiveProductAudit> stockAudits;
  final String? handoverNotes;
  final String nextCashierName;
  final bool isVerifiedByOwner;
  final int transactionCount; // Jumlah transaksi periode ini

  const ShiftRecord({
    required this.id,
    required this.cashierName,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.startingCashDrawer,
    required this.systemCashSales,
    required this.systemQrisSales,
    required this.systemKasbonSales,
    required this.totalSystemSales,
    required this.physicalCashCounted,
    required this.cashDifference,
    required this.stockAudits,
    this.handoverNotes,
    required this.nextCashierName,
    this.isVerifiedByOwner = false,
    this.transactionCount = 0,
  });

  int get differenceCount => stockAudits.where((a) => a.hasDifference).length;
  int get matchedCount => stockAudits.where((a) => !a.hasDifference).length;

  double get totalLossByCost => stockAudits.fold(0.0, (sum, a) {
        if (a.costPrice != null) {
          return sum + (a.difference * a.costPrice!);
        }
        return sum;
      });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashierName': cashierName,
      'shiftName': shiftName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'totalSystemSales': totalSystemSales,
      'currentShiftTransactions': transactionCount,
      'stockAudits': stockAudits.map((a) => a.toJson()).toList(),
      'handoverNotes': handoverNotes,
      'nextCashierName': nextCashierName,
    };
  }

  factory ShiftRecord.fromJson(Map<String, dynamic> json) {
    final List<SensitiveProductAudit> loadedAudits = [];
    final auditsJson = json['stockAudits'] as List<dynamic>?;
    if (auditsJson != null) {
      for (final a in auditsJson) {
        loadedAudits.add(SensitiveProductAudit.fromJson(a as Map<String, dynamic>));
      }
    }

    return ShiftRecord(
      id: json['id']?.toString() ?? 'LAPORAN-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: json['cashierName']?.toString() ?? 'Penjaga',
      shiftName: json['shiftName']?.toString() ?? 'Laporan Jaga',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startingCashDrawer: 0,
      systemCashSales: (json['totalSystemSales'] as num?)?.toDouble() ?? 0.0,
      systemQrisSales: 0,
      systemKasbonSales: 0,
      totalSystemSales: (json['totalSystemSales'] as num?)?.toDouble() ?? 0.0,
      physicalCashCounted: 0,
      cashDifference: 0,
      stockAudits: loadedAudits,
      handoverNotes: json['handoverNotes']?.toString(),
      nextCashierName: json['nextCashierName']?.toString() ?? 'Penjaga',
      isVerifiedByOwner: false,
      transactionCount: (json['currentShiftTransactions'] as num?)?.toInt() ?? 0,
    );
  }
}
