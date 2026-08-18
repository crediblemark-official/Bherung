import 'package:flutter/material.dart';
import '../models/branch.dart';
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
  final bool isMultiBranchEnabled;
  final Branch? activeBranch;
  final VoidCallback? onSwitchBranch;
  final VoidCallback onOpenKasbon;
  final VoidCallback onOpenHeldOrders;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenGuide;
  final VoidCallback onOpenShiftHandover;
  final VoidCallback onOpenStockControl;
  final VoidCallback onOpenRestock;
  final VoidCallback onOpenRoleSwitcher;
  final VoidCallback? onLockScreen;
  final VoidCallback? onLogoutOwner;
  final VoidCallback? onOpenDrawer;

  const PosHeaderBar({
    super.key,
    this.storeName = 'Bherung',
    this.storeTagline = '24 JAM',
    required this.currentTime,
    required this.completedTransactions,
    required this.totalSalesToday,
    required this.activeKasbonCount,
    required this.heldOrdersCount,
    required this.currentUser,
    this.isMultiBranchEnabled = false,
    this.activeBranch,
    this.onSwitchBranch,
    required this.onOpenKasbon,
    required this.onOpenHeldOrders,
    required this.onOpenSettings,
    required this.onOpenGuide,
    required this.onOpenShiftHandover,
    required this.onOpenStockControl,
    required this.onOpenRestock,
    required this.onOpenRoleSwitcher,
    this.onLockScreen,
    this.onLogoutOwner,
    this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = currentTime.hour.toString().padLeft(2, '0');
    final minStr = currentTime.minute.toString().padLeft(2, '0');
    final secStr = currentTime.second.toString().padLeft(2, '0');
    final isCloudConnected = AppsScriptService().isConnected;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppTheme.primaryDark,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderDark, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobileOrTablet = constraints.maxWidth < 950;

          return Row(
            children: [
              // Logo & Brand with Gold Accent (Expanded & Flexible)
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: AppTheme.goldGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.store_mall_directory_rounded, color: AppTheme.primaryDark, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        storeName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          letterSpacing: 0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (storeTagline.isNotEmpty && constraints.maxWidth >= 500) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          storeTagline.toUpperCase(),
                          style: const TextStyle(color: AppTheme.goldAccent, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
                        ),
                      ),
                    ],
                    if (isMultiBranchEnabled && activeBranch != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Cabang aktif: ${activeBranch!.name} (Sentuh untuk ganti cabang)',
                        child: InkWell(
                          onTap: onSwitchBranch,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: activeBranch!.isMain
                                  ? AppTheme.primaryGold.withValues(alpha: 0.2)
                                  : AppTheme.primaryTeal.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: activeBranch!.isMain
                                    ? AppTheme.primaryGold.withValues(alpha: 0.6)
                                    : AppTheme.primaryTeal.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.storefront_rounded,
                                  size: 12,
                                  color: activeBranch!.isMain ? AppTheme.goldAccent : const Color(0xFF5EEAD4),
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: constraints.maxWidth < 600 ? 95 : 145),
                                  child: Text(
                                    activeBranch!.name,
                                    style: TextStyle(
                                      color: activeBranch!.isMain ? AppTheme.goldAccent : const Color(0xFF5EEAD4),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                if (onSwitchBranch != null) ...[
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 13,
                                    color: activeBranch!.isMain ? AppTheme.goldAccent : const Color(0xFF5EEAD4),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // Right Navigation
              if (isMobileOrTablet) ...[
                // Mobile/Tablet: Role Pill + Hamburger Menu Button
                InkWell(
                  onTap: onOpenRoleSwitcher,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: currentUser.isOwner
                          ? AppTheme.primaryGold.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: currentUser.isOwner
                            ? AppTheme.primaryGold.withValues(alpha: 0.5)
                            : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                          size: 13,
                          color: currentUser.isOwner ? AppTheme.goldAccent : Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 85),
                          child: Text(
                            currentUser.name.split(' ').first,
                            style: TextStyle(
                              color: currentUser.isOwner ? AppTheme.goldAccent : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (currentUser.isOwner && onLogoutOwner != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: onLogoutOwner,
                    icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.goldAccent),
                    tooltip: 'Keluar Akun Pemilik (Kunci POS)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
                const SizedBox(width: 6),

                // Hamburger Menu Button
                Builder(
                  builder: (ctx) => InkWell(
                    onTap: () {
                      if (onOpenDrawer != null) {
                        onOpenDrawer!();
                      } else {
                        Scaffold.of(ctx).openDrawer();
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ] else ...[
                // Desktop View: Live Clock, Omzet Shift & Hamburger Button
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Live Clock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderDark),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.schedule_rounded, size: 13, color: AppTheme.primaryGold),
                          const SizedBox(width: 6),
                          Text(
                            '$hourStr:$minStr:$secStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Shift Sales Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.monetization_on_rounded, size: 14, color: AppTheme.goldAccent),
                          const SizedBox(width: 5),
                          Text(
                            AppTheme.formatRupiah(totalSalesToday),
                            style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Role Switcher
                    InkWell(
                      onTap: onOpenRoleSwitcher,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: currentUser.isOwner
                              ? AppTheme.primaryGold.withValues(alpha: 0.15)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: currentUser.isOwner
                                ? AppTheme.primaryGold.withValues(alpha: 0.5)
                                : AppTheme.borderDark,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                              size: 13,
                              color: currentUser.isOwner ? AppTheme.goldAccent : Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              currentUser.name,
                              style: TextStyle(
                                color: currentUser.isOwner ? AppTheme.goldAccent : Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onLockScreen != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onLockScreen,
                        icon: const Icon(Icons.lock_outline_rounded, size: 16, color: Colors.white70),
                        tooltip: 'Kunci Layar Kasir (Ganti Penjaga)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                    if (currentUser.isOwner && onLogoutOwner != null) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: onLogoutOwner,
                        icon: const Icon(Icons.logout_rounded, size: 16, color: AppTheme.goldAccent),
                        tooltip: 'Keluar Akun Pemilik (Kunci POS)',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // Cloud Online Status
                    InkWell(
                      onTap: onOpenSettings,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCloudConnected
                              ? AppTheme.successGreen.withValues(alpha: 0.15)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCloudConnected ? AppTheme.successGreen.withValues(alpha: 0.4) : AppTheme.borderDark,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                              size: 13,
                              color: isCloudConnected ? AppTheme.successGreen : Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isCloudConnected ? 'Cloud Online' : 'Pengaturan',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Hamburger Menu Button
                    Builder(
                      builder: (ctx) => InkWell(
                        onTap: () {
                          if (onOpenDrawer != null) {
                            onOpenDrawer!();
                          } else {
                            Scaffold.of(ctx).openDrawer();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                        ),
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
