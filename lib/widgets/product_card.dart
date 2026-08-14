import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onTap,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInCart = cartQuantity > 0;
    final bool isWholesaleApplied = product.hasWholesale && cartQuantity >= product.wholesaleMinQty!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isInCart ? AppTheme.primaryTeal : AppTheme.borderColor,
              width: isInCart ? 1.5 : 1,
            ),
            boxShadow: isInCart
                ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : AppTheme.softShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(7.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Mini Icon + Barcode/SKU & Stock
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            product.color.withValues(alpha: 0.18),
                            product.color.withValues(alpha: 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        product.icon,
                        color: product.color,
                        size: 15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSubtle,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        'Stok: ${product.stock}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Product Name
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                    height: 1.15,
                  ),
                ),

                // Wholesale Info Badge if available
                if (product.hasWholesale) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: isWholesaleApplied ? AppTheme.primaryTealLight : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      'Grosir ≥${product.wholesaleMinQty}: ${AppTheme.formatRupiah(product.wholesalePrice!)}',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        color: isWholesaleApplied ? AppTheme.primaryTeal : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Price & Stepper Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price with Unit
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppTheme.formatRupiah(isWholesaleApplied ? product.wholesalePrice! : product.price),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryTeal,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '/${product.unit}',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isInCart)
                      // Stepper on card
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: onDecrement ?? onTap,
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.remove, size: 12, color: Colors.white),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Text(
                                '$cartQuantity',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: onIncrement ?? onTap,
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(Icons.add, size: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      // Plus button
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 13,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Ultra-Dense Sembako List Row Item
class ProductListItem extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const ProductListItem({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onTap,
    this.onIncrement,
    this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInCart = cartQuantity > 0;
    final bool isWholesale = product.hasWholesale && cartQuantity >= product.wholesaleMinQty!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isInCart ? AppTheme.primaryTealLight.withValues(alpha: 0.3) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isInCart ? AppTheme.primaryTeal : AppTheme.borderColor,
              width: isInCart ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Mini Icon
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(product.icon, size: 15, color: product.color),
              ),
              const SizedBox(width: 8),

              // Code, Name & Unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSubtle,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            product.code,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'Stok: ${product.stock} ${product.unit}',
                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                        ),
                        if (product.hasWholesale) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• Grosir: ${AppTheme.formatRupiah(product.wholesalePrice!)}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppTheme.formatRupiah(isWholesale ? product.wholesalePrice! : product.price),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryTeal,
                    ),
                  ),
                  Text(
                    '/${product.unit}',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Stepper
              if (isInCart)
                Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrement ?? onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.remove, size: 12, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$cartQuantity',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement ?? onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(Icons.add, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppTheme.primaryTeal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
