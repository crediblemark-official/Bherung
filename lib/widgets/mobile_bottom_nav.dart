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
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: AppTheme.primaryDark,
      elevation: 12,
      padding: EdgeInsets.zero,
      height: 58,
      child: SafeArea(
        top: false,
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

            // Space for the center notched floating button
            const SizedBox(width: 68),

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
    );
  }

  Widget _buildBarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return InkWell(
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
                  size: 20,
                  color: isActive ? AppTheme.secondaryTeal : Colors.white70,
                ),
                if (badgeCount != null && badgeCount > 0)
                  Positioned(
                    right: -7,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
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
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppTheme.secondaryTeal : Colors.white60,
              ),
            ),
          ],
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF059669)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.45),
            blurRadius: 10,
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
                Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                SizedBox(height: 1),
                Text(
                  'SCAN',
                  style: TextStyle(
                    color: Colors.white,
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
