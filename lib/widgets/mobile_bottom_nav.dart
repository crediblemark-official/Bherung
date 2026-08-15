import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/product.dart';

class CurvedNotchedBottomBar extends StatelessWidget {
  final int activeKasbonCount;
  final int heldOrdersCount;
  final AppUser currentUser;
  final VoidCallback onOpenScanner;
  final VoidCallback onOpenStockControl;
  final VoidCallback onOpenShiftHandover;
  final VoidCallback onOpenKasbon;
  final VoidCallback onOpenRoleSwitcher;
  final VoidCallback onOpenSettings;

  const CurvedNotchedBottomBar({
    super.key,
    required this.activeKasbonCount,
    required this.heldOrdersCount,
    required this.currentUser,
    required this.onOpenScanner,
    required this.onOpenStockControl,
    required this.onOpenShiftHandover,
    required this.onOpenKasbon,
    required this.onOpenRoleSwitcher,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        border: const Border(
          top: BorderSide(color: Color(0xFF2A313C), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Left Group
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBarItem(
                      icon: Icons.storefront_rounded,
                      label: 'Kasir',
                      isActive: true,
                      onTap: () {},
                    ),
                    _buildBarItem(
                      icon: Icons.inventory_2_rounded,
                      label: 'Stok',
                      isActive: false,
                      onTap: onOpenStockControl,
                    ),
                  ],
                ),
              ),

              // Center Floating Scan Button Spacer
              const SizedBox(width: 64),

              // Right Group
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildBarItem(
                      icon: Icons.sync_alt_rounded,
                      label: 'Shift',
                      isActive: false,
                      onTap: onOpenShiftHandover,
                    ),
                    _buildBarItem(
                      icon: Icons.menu_book_rounded,
                      label: 'Kasbon',
                      isActive: false,
                      badgeCount: activeKasbonCount,
                      onTap: onOpenKasbon,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 21,
                    color: isActive ? AppTheme.goldAccent : Colors.white60,
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.dangerRed,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? AppTheme.goldAccent : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotchedCenterFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NotchedCenterFloatingButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      margin: const EdgeInsets.only(top: 22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.goldGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.45),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryDark, size: 24),
                SizedBox(height: 1),
                Text(
                  'SCAN',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
