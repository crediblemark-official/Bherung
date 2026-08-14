class BarcodeMasterItem {
  final String barcode;
  final String name;
  final double price;
  final double? costPrice;
  final String categoryId;
  final String unit;
  final bool isSensitiveItem;

  const BarcodeMasterItem({
    required this.barcode,
    required this.name,
    required this.price,
    this.costPrice,
    required this.categoryId,
    required this.unit,
    this.isSensitiveItem = false,
  });
}

class BarcodeMasterLookupService {
  static final BarcodeMasterLookupService _instance = BarcodeMasterLookupService._internal();
  factory BarcodeMasterLookupService() => _instance;
  BarcodeMasterLookupService._internal();

  // Database Master Barcode Produk Warung Kelontong & Madura Terpopuler Indonesia (EAN-13 GS1)
  final Map<String, BarcodeMasterItem> _masterDatabase = {
    // ROKOK (Sensitif Shift)
    '8999909001012': const BarcodeMasterItem(
      barcode: '8999909001012',
      name: 'Gudang Garam Surya 16',
      price: 33000,
      costPrice: 30500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8999909001029': const BarcodeMasterItem(
      barcode: '8999909001029',
      name: 'Gudang Garam International 12',
      price: 25000,
      costPrice: 23000,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8999909001036': const BarcodeMasterItem(
      barcode: '8999909001036',
      name: 'Gudang Garam Merah King Size 12',
      price: 18000,
      costPrice: 16500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8998989100112': const BarcodeMasterItem(
      barcode: '8998989100112',
      name: 'Sampoerna A Mild 16',
      price: 35000,
      costPrice: 32500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8998989100129': const BarcodeMasterItem(
      barcode: '8998989100129',
      name: 'Dji Sam Soe 234 Kretek 12',
      price: 21000,
      costPrice: 19500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8999999000123': const BarcodeMasterItem(
      barcode: '8999999000123',
      name: 'Djarum Super 12',
      price: 24000,
      costPrice: 22000,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8999999000130': const BarcodeMasterItem(
      barcode: '8999999000130',
      name: 'Djarum 76 Filter Gold 12',
      price: 17000,
      costPrice: 15500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8997232230018': const BarcodeMasterItem(
      barcode: '8997232230018',
      name: 'Esse Change Juicy 20',
      price: 42000,
      costPrice: 39000,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),
    '8992770': const BarcodeMasterItem(
      barcode: '8992770',
      name: 'Gudang Garam Surya 16',
      price: 33000,
      costPrice: 30500,
      categoryId: 'rokok',
      unit: 'bks',
      isSensitiveItem: true,
    ),

    // MIE INSTAN & MAKANAN
    '8998866200119': const BarcodeMasterItem(
      barcode: '8998866200119',
      name: 'Indomie Goreng Spesial',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),
    '8998866200126': const BarcodeMasterItem(
      barcode: '8998866200126',
      name: 'Indomie Kuah Ayam Bawang',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),
    '8998866200133': const BarcodeMasterItem(
      barcode: '8998866200133',
      name: 'Indomie Kuah Soto Mie',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),
    '8998866200140': const BarcodeMasterItem(
      barcode: '8998866200140',
      name: 'Indomie Goreng Rendang',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),
    '8998866200157': const BarcodeMasterItem(
      barcode: '8998866200157',
      name: 'Mie Sedaap Goreng',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),
    '8998866200164': const BarcodeMasterItem(
      barcode: '8998866200164',
      name: 'Mie Sedaap Soto Madura',
      price: 3500,
      costPrice: 3000,
      categoryId: 'mie_makanan',
      unit: 'bks',
    ),

    // MINUMAN DINGIN
    '8996001304240': const BarcodeMasterItem(
      barcode: '8996001304240',
      name: 'Le Minerale Botol Dingin 600ml',
      price: 3500,
      costPrice: 2800,
      categoryId: 'minuman',
      unit: 'botol',
    ),
    '8998866200331': const BarcodeMasterItem(
      barcode: '8998866200331',
      name: 'Aqua Botol Dingin 600ml',
      price: 4000,
      costPrice: 3200,
      categoryId: 'minuman',
      unit: 'botol',
    ),
    '8998866200010': const BarcodeMasterItem(
      barcode: '8998866200010',
      name: 'Aqua Galon Asli 19 Liter',
      price: 20000,
      costPrice: 17500,
      categoryId: 'gas_galon',
      unit: 'galon',
    ),
    '8992753211112': const BarcodeMasterItem(
      barcode: '8992753211112',
      name: 'Teh Pucuk Harum Dingin 350ml',
      price: 4000,
      costPrice: 3200,
      categoryId: 'minuman',
      unit: 'botol',
    ),
    '8991002101332': const BarcodeMasterItem(
      barcode: '8991002101332',
      name: 'Pocari Sweat Botol 500ml',
      price: 7500,
      costPrice: 6500,
      categoryId: 'minuman',
      unit: 'botol',
    ),
    '8991389220010': const BarcodeMasterItem(
      barcode: '8991389220010',
      name: 'Kopi Kapal Api Spesial Mix (Renceng)',
      price: 15000,
      costPrice: 13000,
      categoryId: 'minuman',
      unit: 'renceng',
    ),

    // SEMBAKO & MINYAK
    '8991003100220': const BarcodeMasterItem(
      barcode: '8991003100220',
      name: 'Minyak Goreng Bimoli 2 Liter Pouch',
      price: 36000,
      costPrice: 33500,
      categoryId: 'sembako',
      unit: 'pouch',
    ),
    '8991003100330': const BarcodeMasterItem(
      barcode: '8991003100330',
      name: 'Minyak Goreng Kita 1 Liter Pouch',
      price: 16500,
      costPrice: 15000,
      categoryId: 'sembako',
      unit: 'pouch',
    ),
    '8998888123456': const BarcodeMasterItem(
      barcode: '8998888123456',
      name: 'Gas Elpiji 3kg Melon (Refill)',
      price: 22000,
      costPrice: 19500,
      categoryId: 'gas_galon',
      unit: 'tabung',
    ),
  };

  /// Cari data produk dari database master barcode (Offline Dictionary)
  BarcodeMasterItem? lookup(String barcode) {
    final clean = barcode.trim();
    if (_masterDatabase.containsKey(clean)) {
      return _masterDatabase[clean];
    }
    // Coba pencocokan substring jika barcode punya leading zero
    for (final entry in _masterDatabase.entries) {
      if (clean.endsWith(entry.key) || entry.key.endsWith(clean)) {
        return entry.value;
      }
    }
    return null;
  }
}
