import 'cart_item.dart';
import 'transaction_type.dart';

class HeldOrder {
  final String id;
  final String customerName;
  final TransactionType transactionType;
  final List<CartItem> items;
  final double deliveryFee;
  final DateTime createdAt;
  final String? branchId;
  final String? branchName;

  HeldOrder({
    required this.id,
    required this.customerName,
    required this.transactionType,
    required this.items,
    this.deliveryFee = 0.0,
    required this.createdAt,
    this.branchId,
    this.branchName,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0, (sum, item) => sum + item.totalPrice);
  double get total => subtotal + deliveryFee;
}
