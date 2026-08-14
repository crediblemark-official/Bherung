import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../theme/app_theme.dart';

class AppDrawerMenu extends StatelessWidget {
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

  const AppDrawerMenu({
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
  });

  @override
  Widget build(BuildContext context) {
    final hourStr = currentTime.hour.toString().padLeft(2, '0');
    final minStr = currentTime.minute.toString().padLeft(2, '0');
    final secStr = currentTime.second.toString().padLeft(2, '0');
    final isCloudConnected = AppsScriptService().isConnected;

    return Drawer(
      backgroundColor: AppTheme.bgLight,
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF059669)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.store_mall_directory_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            storeName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 14.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (storeTagline.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFEF4444)),
                              ),
                              child: Text(
                                storeTagline.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 8.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Live Clock & Cloud Sync Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF5EEAD4), size: 12),
                          const SizedBox(width: 5),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCloudConnected
                            ? const Color(0xFF047857).withValues(alpha: 0.3)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
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
                            isCloudConnected ? 'Cloud Online' : 'Lokal',
                            style: TextStyle(
                              color: isCloudConnected ? const Color(0xFF34D399) : Colors.white60,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Omzet Shift Card
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Omzet Shift Ini:', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                          const SizedBox(height: 2),
                          Text(
                            AppTheme.formatRupiah(totalSalesToday),
                            style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 13.5, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$completedTransactions Trx',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // User / Role Section
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: currentUser.isOwner ? const Color(0xFFFEF3C7) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      currentUser.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                      color: currentUser.isOwner ? const Color(0xFFD97706) : const Color(0xFF0284C7),
                      size: 20,
                    ),
                  ),
                  title: Text(currentUser.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    currentUser.isOwner ? '👑 Pemilik Akun (Owner)' : '👤 Penjaga Toko (Kasir)',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                  trailing: const Icon(Icons.swap_horiz_rounded, size: 18, color: AppTheme.textMuted),
                  onTap: () {
                    Navigator.pop(context);
                    onOpenRoleSwitcher();
                  },
                ),
                const Divider(height: 16),

                // 1. Kontrol Stok & Expired
                _buildDrawerItem(
                  context: context,
                  icon: Icons.inventory_2_rounded,
                  iconColor: const Color(0xFF0D9488),
                  title: 'Kontrol Stok, Slow-Moving & Expired',
                  subtitle: 'Pantau barang macet, kadaluwarsa & kartu mutasi',
                  onTap: onOpenStockControl,
                ),

                // 2. Kulakan / Restock
                _buildDrawerItem(
                  context: context,
                  icon: Icons.add_box_rounded,
                  iconColor: const Color(0xFF059669),
                  title: 'Kulakan / Tambah Stok',
                  subtitle: 'Restock barang masuk dari agen sembako',
                  onTap: onOpenRestock,
                ),

                // 3. Serah Terima Shift
                _buildDrawerItem(
                  context: context,
                  icon: Icons.sync_alt_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Serah Terima Shift & Kas',
                  subtitle: 'Tutup shift, rekonsiliasi kas laci & rokok',
                  onTap: onOpenShiftHandover,
                ),

                // 4. Buku Kasbon
                _buildDrawerItem(
                  context: context,
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFFD97706),
                  title: 'Buku Kasbon Pelanggan',
                  subtitle: 'Catatan utang belanja & tanggal jatuh tempo',
                  badgeCount: activeKasbonCount,
                  onTap: onOpenKasbon,
                ),

                // 5. Pesanan Ditahan (Hold)
                _buildDrawerItem(
                  context: context,
                  icon: Icons.pause_circle_outline_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Pesanan Ditahan (Hold Orders)',
                  subtitle: 'Daftar nota belanja yang ditunda sementara',
                  badgeCount: heldOrdersCount,
                  onTap: onOpenHeldOrders,
                ),

                const Divider(height: 16),

                // 6. Sinkronisasi Cloud & Settings
                _buildDrawerItem(
                  context: context,
                  icon: Icons.settings_rounded,
                  iconColor: AppTheme.textDark,
                  title: 'Pengaturan & Cloud Sync',
                  subtitle: 'Google Sheets backend, profil toko & printer',
                  onTap: onOpenSettings,
                ),

                // 7. Panduan Toko Madura
                _buildDrawerItem(
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
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
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
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 19),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted)),
      trailing: (badgeCount != null && badgeCount > 0)
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
