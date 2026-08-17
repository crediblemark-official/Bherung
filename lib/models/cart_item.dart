import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? note;
  bool forceWholesalePrice;
  TransactionType transactionType;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.note,
    this.forceWholesalePrice = false,
    this.transactionType = TransactionType.eceran,
  });

  double get unitPrice {
    // 1. Jika Tab Transaksi = Grosir / Dus, otomatis gunakan harga grosir
    if (transactionType == TransactionType.grosir && product.wholesalePrice != null) {
      return product.wholesalePrice!;
    }
    // 2. Jika Tab Transaksi = Eceran atau Antar / Titip, kembali ke harga eceran normal (kecuali qty >= minimal grosir)
    return product.getEffectiveUnitPrice(quantity);
  }

  bool get isWholesaleApplied =>
      (transactionType == TransactionType.grosir && product.wholesalePrice != null) ||
      (product.hasWholesale && quantity >= product.wholesaleMinQty!);

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? note,
    bool? forceWholesalePrice,
    TransactionType? transactionType,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      forceWholesalePrice: forceWholesalePrice ?? this.forceWholesalePrice,
      transactionType: transactionType ?? this.transactionType,
    );
  }
}
