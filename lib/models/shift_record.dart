class SensitiveProductAudit {
  final String productId;
  final String productName;
  final int systemStock;
  final int physicalStock;
  final int difference; // physicalStock - systemStock
  final String? note;

  const SensitiveProductAudit({
    required this.productId,
    required this.productName,
    required this.systemStock,
    required this.physicalStock,
    required this.difference,
    this.note,
  });

  bool get hasDifference => difference != 0;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'systemStock': systemStock,
      'physicalStock': physicalStock,
      'difference': difference,
      'note': note,
    };
  }

  factory SensitiveProductAudit.fromJson(Map<String, dynamic> json) {
    return SensitiveProductAudit(
      productId: json['productId']?.toString() ?? '',
      productName: json['productName']?.toString() ?? '',
      systemStock: (json['systemStock'] as num?)?.toInt() ?? 0,
      physicalStock: (json['physicalStock'] as num?)?.toInt() ?? 0,
      difference: (json['difference'] as num?)?.toInt() ?? 0,
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
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashierName': cashierName,
      'shiftName': shiftName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'startingCashDrawer': startingCashDrawer,
      'systemCashSales': systemCashSales,
      'systemQrisSales': systemQrisSales,
      'systemKasbonSales': systemKasbonSales,
      'totalSystemSales': totalSystemSales,
      'physicalCashCounted': physicalCashCounted,
      'cashDifference': cashDifference,
      'stockAudits': stockAudits.map((a) => a.toJson()).toList(),
      'handoverNotes': handoverNotes,
      'nextCashierName': nextCashierName,
      'isVerifiedByOwner': isVerifiedByOwner,
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
      id: json['id']?.toString() ?? 'SHIFT-${DateTime.now().millisecondsSinceEpoch}',
      cashierName: json['cashierName']?.toString() ?? 'Kasir',
      shiftName: json['shiftName']?.toString() ?? 'Shift 24 Jam',
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) ?? DateTime.now() : DateTime.now(),
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) ?? DateTime.now() : DateTime.now(),
      startingCashDrawer: (json['startingCashDrawer'] as num?)?.toDouble() ?? 0.0,
      systemCashSales: (json['systemCashSales'] as num?)?.toDouble() ?? 0.0,
      systemQrisSales: (json['systemQrisSales'] as num?)?.toDouble() ?? 0.0,
      systemKasbonSales: (json['systemKasbonSales'] as num?)?.toDouble() ?? 0.0,
      totalSystemSales: (json['totalSystemSales'] as num?)?.toDouble() ?? 0.0,
      physicalCashCounted: (json['physicalCashCounted'] as num?)?.toDouble() ?? 0.0,
      cashDifference: (json['cashDifference'] as num?)?.toDouble() ?? 0.0,
      stockAudits: loadedAudits,
      handoverNotes: json['handoverNotes']?.toString(),
      nextCashierName: json['nextCashierName']?.toString() ?? 'Kasir',
      isVerifiedByOwner: json['isVerifiedByOwner'] == true,
    );
  }
}
