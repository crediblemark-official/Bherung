import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../theme/app_theme.dart';

class PosHeaderBar extends StatelessWidget {
  final String storeName;
  final String storeTagline;
  final DateTime currentTime;
  final int completedTransactions;
  final double totalSalesToday;
  final int activeKasbonCount;
  final int heldOrdersCount;
  final AppUser currentUser;
  final VoidCallback onOpenKasbon;
  final VoidCallback onOpenHeldOrders;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenShiftHandover;
  final VoidCallback onOpenStockControl;
  final VoidCallback onOpenRestock;
  final VoidCallback onOpenRoleSwitcher;
  final VoidCallback? onOpenDrawer;

  const PosHeaderBar({
    super.key,
    this.storeName = 'TOKO MADURA BHERUNG',
    this.storeTagline = '24 JAM',
    required this.currentTime,
    required this.completedTransactions,
    required this.totalSalesToday,
    required this.activeKasbonCount,
    required this.heldOrdersCount,
    required this.currentUser,
    required this.onOpenKasbon,
    required this.onOpenHeldOrders,
    required this.onOpenSettings,
    required this.onOpenGuide,
    required this.onOpenShiftHandover,
    required this.onOpenStockControl,
    required this.onOpenRestock,
    required this.onOpenRoleSwitcher,
    this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = currentTime.hour.toString().padLeft(2, '0');
    final minStr = currentTime.minute.toString().padLeft(2, '0');
    final secStr = currentTime.second.toString().padLeft(2, '0');
    final isCloudConnected = AppsScriptService().isConnected;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobileOrTablet = constraints.maxWidth < 950;

          return Row(
            children: [
              // Logo & Brand
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D9488), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                isMobileOrTablet && storeName.length > 14 ? '${storeName.substring(0, 14)}...' : storeName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13.5,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),

              // Store Tagline Badge (misal: 24 JAM / KELONTONG)
              if (storeTagline.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444)),
                  ),
                  child: Text(
                    storeTagline.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),

              const Spacer(),

              // Right Navigation
              if (isMobileOrTablet) ...[
                // Mobile/Tablet: Role Pill + Hamburger Menu Button
                InkWell(
                  onTap: onOpenRoleSwitcher,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: currentUser.isOwner
                          ? const Color(0xFFD97706).withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: currentUser.isOwner
                            ? Colors.amberAccent.withValues(alpha: 0.5)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          size: 13,
                          color: currentUser.isOwner ? Colors.amberAccent : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currentUser.name.split(' ').first,
                          style: TextStyle(
                            color: currentUser.isOwner ? Colors.amberAccent : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Hamburger Menu Button (☰)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                    onPressed: () {
                      if (onOpenDrawer != null) {
                        onOpenDrawer!();
                      } else {
                        Scaffold.of(ctx).openDrawer();
                      }
                    },
                    tooltip: 'Menu Utama',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ] else ...[
                // Desktop View: Live Clock, Omzet Shift & Hamburger Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Clock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '$hourStr:$minStr:$secStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Shift Sales Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF047857).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 13, color: Color(0xFF34D399)),
                          const SizedBox(width: 4),
                          Text(
                            AppTheme.formatRupiah(totalSalesToday),
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Role Switcher
                    InkWell(
                      onTap: onOpenRoleSwitcher,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentUser.isOwner
                              ? const Color(0xFFD97706).withValues(alpha: 0.25)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: currentUser.isOwner
                                ? Colors.amberAccent.withValues(alpha: 0.5)
                                : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              size: 13,
                              color: currentUser.isOwner ? Colors.amberAccent : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentUser.name,
                              style: TextStyle(
                                color: currentUser.isOwner ? Colors.amberAccent : Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Cloud Online Status
                    InkWell(
                      onTap: onOpenSettings,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCloudConnected
                              ? const Color(0xFF059669).withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCloudConnected ? const Color(0xFF10B981) : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              size: 13,
                              color: isCloudConnected ? const Color(0xFF34D399) : Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCloudConnected ? 'Cloud Online' : 'Pengaturan',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Hamburger Menu Button (☰)
                    Builder(
                      builder: (ctx) => IconButton(
                        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
                        onPressed: () {
                          if (onOpenDrawer != null) {
                            onOpenDrawer!();
                          } else {
                            Scaffold.of(ctx).openDrawer();
                          }
                        },
                        tooltip: 'Menu Utama',
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
