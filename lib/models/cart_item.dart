import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String? note;
  bool forceWholesalePrice;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.note,
    this.forceWholesalePrice = false,
  });

  double get unitPrice {
    if (forceWholesalePrice && product.wholesalePrice != null) {
      return product.wholesalePrice!;
    }
    return product.getEffectiveUnitPrice(quantity);
  }

  bool get isWholesaleApplied =>
      (forceWholesalePrice && product.wholesalePrice != null) ||
      (product.hasWholesale && quantity >= product.wholesaleMinQty!);

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    String? note,
    bool? forceWholesalePrice,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
      forceWholesalePrice: forceWholesalePrice ?? this.forceWholesalePrice,
    );
  }
}
