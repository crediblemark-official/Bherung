import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../theme/app_theme.dart';

class AppMenuScreen extends StatelessWidget {
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
  final VoidCallback? onLogoutOwner;

  const AppMenuScreen({
    super.key,
    required this.storeName,
    required this.storeTagline,
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
    this.onLogoutOwner,
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = currentTime.hour.toString().padLeft(2, '0');
    final minStr = currentTime.minute.toString().padLeft(2, '0');
    final secStr = currentTime.second.toString().padLeft(2, '0');
    final isCloudConnected = AppsScriptService().isConnected;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali ke Kasir',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGold.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.store_mall_directory_rounded, color: AppTheme.primaryDark, size: 16),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      storeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (storeTagline.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          storeTagline.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Text(
                  'Menu & Pusat Fitur POS',
                  style: TextStyle(color: AppTheme.textSubtle, fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          children: [
            // 1. Live Stats & Omzet Shift Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Clock
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_filled_rounded, color: Color(0xFF5EEAD4), size: 13),
                            const SizedBox(width: 5),
                            Text(
                              '$hourStr:$minStr:$secStr',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Cloud Status
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCloudConnected
                              ? const Color(0xFF047857).withValues(alpha: 0.3)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isCloudConnected ? const Color(0xFF10B981) : Colors.white24,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                              color: isCloudConnected ? const Color(0xFF34D399) : Colors.white60,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCloudConnected ? 'Cloud Online' : 'Penyimpanan Lokal',
                              style: TextStyle(
                                color: isCloudConnected ? const Color(0xFF34D399) : Colors.white70,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Omzet Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Omzet Jaga Ini:', style: TextStyle(color: Colors.white60, fontSize: 11)),
                            const SizedBox(height: 3),
                            Text(
                              AppTheme.formatRupiah(totalSalesToday),
                              style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 16, fontWeight: FontWeight.w900),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$completedTransactions Transaksi',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Akun & Ganti Peran (Wrapped in Material to enable ink splash & correct rendering)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              shadowColor: Colors.black12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: currentUser.isOwner ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      color: currentUser.isOwner ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                      size: 22,
                    ),
                  ),
                  title: Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text(
                    currentUser.isOwner ? 'Pemilik Akun (Owner Toko)' : 'Penjaga Toko (Kasir)',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Ganti Akun', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        SizedBox(width: 4),
                        Icon(Icons.swap_horiz_rounded, size: 14, color: AppTheme.textDark),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onOpenRoleSwitcher();
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'MENU OPERASIONAL TOKO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5),
              ),
            ),

            // 3. Menu Items List Card (Wrapped in Material)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              shadowColor: Colors.black12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    // Serah Terima Jaga & Cekan Toko
                    _buildMenuItem(
                      context: context,
                      icon: Icons.fact_check_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Serah Terima Jaga & Cekan Toko',
                      subtitle: 'Pencocokan stok fisik vs stok lama, omzet & estafet jaga',
                      onTap: onOpenShiftHandover,
                    ),
                    const Divider(height: 1, indent: 56),

                    // Kontrol Stok
                    _buildMenuItem(
                      context: context,
                      icon: Icons.inventory_2_rounded,
                      iconColor: const Color(0xFF0D9488),
                      title: 'Kontrol Stok, Slow-Moving & Expired',
                      subtitle: 'Pantau barang macet, kedaluwarsa & kartu mutasi',
                      onTap: onOpenStockControl,
                    ),
                    const Divider(height: 1, indent: 56),

                    // Kulakan
                    _buildMenuItem(
                      context: context,
                      icon: Icons.add_box_rounded,
                      iconColor: const Color(0xFF059669),
                      title: 'Kulakan / Tambah Stok',
                      subtitle: 'Restock barang masuk dari agen sembako',
                      onTap: onOpenRestock,
                    ),
                    const Divider(height: 1, indent: 56),

                    // Kasbon
                    _buildMenuItem(
                      context: context,
                      icon: Icons.menu_book_rounded,
                      iconColor: const Color(0xFFD97706),
                      title: 'Buku Kasbon Pelanggan',
                      subtitle: 'Catatan utang belanja & tanggal jatuh tempo',
                      badgeCount: activeKasbonCount,
                      onTap: onOpenKasbon,
                    ),
                    const Divider(height: 1, indent: 56),

                    // Hold
                    _buildMenuItem(
                      context: context,
                      icon: Icons.pause_circle_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'Pesanan Ditahan (Hold Orders)',
                      subtitle: 'Daftar nota belanja yang ditunda sementara',
                      badgeCount: heldOrdersCount,
                      onTap: onOpenHeldOrders,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'SISTEM & PENGATURAN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.textMuted, letterSpacing: 0.5),
              ),
            ),

            // 4. System Settings & Guide (Wrapped in Material)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              elevation: 1,
              shadowColor: Colors.black12,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context: context,
                      icon: Icons.settings_rounded,
                      iconColor: AppTheme.textDark,
                      title: 'Pengaturan & Cloud Sync',
                      subtitle: 'Google Sheets backend, profil toko & printer',
                      onTap: onOpenSettings,
                    ),
                    const Divider(height: 1, indent: 56),
                    _buildMenuItem(
                      context: context,
                      icon: Icons.help_outline_rounded,
                      iconColor: AppTheme.textMuted,
                      title: 'Panduan Operasional POS',
                      subtitle: 'Petunjuk scan kamera HP, shift & kasbon',
                      onTap: onOpenGuide,
                    ),
                  ],
                ),
              ),
            ),
            if (currentUser.isOwner && onLogoutOwner != null) ...[
              const SizedBox(height: 14),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFFECACA)),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
                  ),
                  title: const Text(
                    'Keluar Akun Pemilik Toko',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFDC2626)),
                  ),
                  subtitle: const Text(
                    'Kunci sistem POS dan kembali ke layar PIN kasir',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                  onTap: () {
                    Navigator.pop(context);
                    onLogoutOwner!();
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
      trailing: (badgeCount != null && badgeCount > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
              ),
            )
          : const Icon(Icons.chevron_right_rounded, size: 18, color: AppTheme.textMuted),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
