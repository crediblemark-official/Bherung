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
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isInCart ? AppTheme.primaryGold : AppTheme.borderColor,
              width: isInCart ? 1.6 : 1,
            ),
            boxShadow: isInCart
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : AppTheme.softShadow,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 175;

              return Padding(
                padding: EdgeInsets.all(isWide ? 10.0 : 7.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Mini Icon + Stock Badge
                    Row(
                      children: [
                        Container(
                          width: isWide ? 30 : 24,
                          height: isWide ? 30 : 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                product.color.withValues(alpha: 0.18),
                                product.color.withValues(alpha: 0.08),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(isWide ? 7 : 6),
                          ),
                          child: Icon(
                            product.icon,
                            color: product.color,
                            size: isWide ? 16 : 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWide ? 6 : 4,
                              vertical: isWide ? 2 : 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: product.stock <= 5
                                  ? AppTheme.dangerRedLight
                                  : AppTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: product.stock <= 5
                                    ? AppTheme.dangerRed.withValues(alpha: 0.3)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Text(
                              'Stok: ${product.stock}',
                              style: TextStyle(
                                fontSize: isWide ? 10.5 : 9,
                                fontWeight: FontWeight.w800,
                                color: product.stock <= 5 ? AppTheme.dangerRed : AppTheme.textMuted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWide ? 6 : 4),

                    // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isWide ? 13 : 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),

                    // Wholesale Info Badge if available
                    if (product.hasWholesale) ...[
                      SizedBox(height: isWide ? 4 : 2),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isWide ? 5 : 3.5,
                          vertical: isWide ? 1.5 : 1,
                        ),
                        decoration: BoxDecoration(
                          color: isWholesaleApplied ? AppTheme.goldLight : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isWholesaleApplied ? AppTheme.primaryGold : const Color(0xFFF59E0B),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Grosir ≥${product.wholesaleMinQty}: ${AppTheme.formatRupiah(product.wholesalePrice!)}',
                          style: TextStyle(
                            fontSize: isWide ? 9 : 7.5,
                            fontWeight: FontWeight.w800,
                            color: isWholesaleApplied ? AppTheme.goldMuted : const Color(0xFF92400E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Price & Stepper Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Price with Unit
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppTheme.formatRupiah(isWholesaleApplied ? product.wholesalePrice! : product.price),
                                style: TextStyle(
                                  fontSize: isWide ? 14 : 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.goldMuted,
                                  letterSpacing: -0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '/${product.unit}',
                                style: TextStyle(
                                  fontSize: isWide ? 10 : 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),

                        if (isInCart)
                          // Stepper on card with Gold Accent
                          Container(
                            height: isWide ? 28 : 24,
                            decoration: BoxDecoration(
                              gradient: AppTheme.goldGradient,
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGold.withValues(alpha: 0.3),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: onDecrement ?? onTap,
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isWide ? 6 : 4),
                                    child: Icon(Icons.remove, size: isWide ? 14 : 12, color: AppTheme.primaryDark),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    '$cartQuantity',
                                    style: TextStyle(
                                      fontSize: isWide ? 12.5 : 11,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: onIncrement ?? onTap,
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isWide ? 6 : 4),
                                    child: Icon(Icons.add, size: isWide ? 14 : 12, color: AppTheme.primaryDark),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // Plus button
                          Container(
                            width: isWide ? 28 : 24,
                            height: isWide ? 28 : 24,
                            decoration: BoxDecoration(
                              color: AppTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: isWide ? 15 : 12.5,
                              color: AppTheme.primaryGold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isInCart ? AppTheme.goldLight.withValues(alpha: 0.4) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isInCart ? AppTheme.primaryGold : AppTheme.borderColor,
              width: isInCart ? 1.4 : 1,
            ),
            boxShadow: isInCart
                ? [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : AppTheme.softShadow,
          ),
          child: Row(
            children: [
              // Mini Icon
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: product.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(product.icon, size: 16, color: product.color),
              ),
              const SizedBox(width: 10),

              // Code, Name & Unit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        if (product.code.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(4),
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
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'Stok: ${product.stock} ${product.unit}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: product.stock <= 5 ? AppTheme.dangerRed : AppTheme.textMuted,
                          ),
                        ),
                        if (product.hasWholesale) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Grosir: ${AppTheme.formatRupiah(product.wholesalePrice!)}',
                            style: const TextStyle(fontSize: 10.5, color: AppTheme.goldMuted, fontWeight: FontWeight.w700),
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
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.goldMuted,
                    ),
                  ),
                  Text(
                    '/${product.unit}',
                    style: const TextStyle(fontSize: 9.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Stepper
              if (isInCart)
                Container(
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGold.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrement ?? onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.remove, size: 13, color: AppTheme.primaryDark),
                        ),
                      ),
                      Text(
                        '$cartQuantity',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement ?? onTap,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(Icons.add, size: 13, color: AppTheme.primaryDark),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: AppTheme.primaryGold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
