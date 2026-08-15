import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buku Panduan Kasir & Database',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Petunjuk operasional kasir & panduan setup Google Spreadsheet',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Setup Database Google Spreadsheet (With Visual Screenshots)
                  _buildSectionHeader(
                    icon: Icons.cloud_sync_rounded,
                    title: '1. Panduan Setup Database Google Spreadsheet',
                  ),
                  const SizedBox(height: 10),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '1',
                    title: 'Salin Link Template & Buat Salinan di Google Drive',
                    desc:
                        'Buka menu Pengaturan > Tab 1: Google Sheets, lalu klik tombol "Salin Link Template Google Sheets". Buka link tersebut di browser laptop/HP Anda, lalu klik tombol "Make a copy / Buat salinan" agar database resmi toko tersimpan di akun Google Drive pribadi Anda.',
                    imagePaths: [
                      'assets/docs/step0_salin_template.png',
                    ],
                    badgeText: 'Langkah Pertama (10 Detik)',
                    badgeColor: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '2',
                    title: 'Buka Hak Akses Link Menjadi "Editor"',
                    desc:
                        'Di Google Spreadsheet hasil salinan Anda, klik tombol "Bagikan (Share)". Pada bagian Akses umum, ubah menjadi "Siapa saja yang memiliki link (Anyone with the link)" dan pastikan perannya dipilih "Editor" (bukan Viewer/Pelihat) agar aplikasi kasir dapat mencatat penjualan, memperbarui stok, dan buku kasbon.',
                    imagePaths: [
                      'assets/docs/step1_akses_siapa_saja.png',
                      'assets/docs/step2_pilih_editor.png',
                    ],
                    badgeText: 'PENTING: Wajib Editor',
                    badgeColor: AppTheme.successGreen,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '3',
                    title: 'Jalankan Menu "Bherung POS" di Spreadsheet',
                    desc:
                        'Buka Google Spreadsheet di laptop/komputer. Klik menu khusus "Bherung POS" di bilah atas, lalu pilih opsi:\n"1. Otorisasi & Aktifkan Database Kasir" untuk mengaktifkan seluruh tabel database secara otomatis.',
                    imagePaths: [
                      'assets/docs/step3_menu_otorisasi.png',
                    ],
                    badgeText: 'Menu Otomatis',
                    badgeColor: AppTheme.primaryGold,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '4',
                    title: 'Izinkan Otorisasi Keamanan Google',
                    desc:
                        'Google akan menampilkan dialog "Otorisasi diperlukan". Klik "Oke", lalu pilih akun Google Anda. Jika muncul peringatan "Google belum memverifikasi aplikasi ini", klik tautan "Lanjutan (Advanced)" di bagian bawah kiri, lalu klik "Buka Untitled project (tidak aman)", dan klik "Lanjutkan / Izinkan".',
                    imagePaths: [
                      'assets/docs/step4_dialog_izin.png',
                      'assets/docs/step5_lanjutan_otorisasi.png',
                    ],
                    badgeText: 'Hanya Sekali di Awal',
                    badgeColor: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '5',
                    title: 'Salin Link atau ID Spreadsheet ke Aplikasi Kasir',
                    desc:
                        'Setelah otorisasi berhasil, ID Spreadsheet akan muncul di layar. Anda juga bisa menyalin link URL lengkap dari address bar browser. Buka menu Pengaturan > Tab 1: Google Sheets di aplikasi Bherung POS, tempelkan link tersebut, lalu klik tombol emas "Hubungkan & Simpan Database". Aplikasi kini langsung terhubung dengan Google Drive & Spreadsheet toko Anda!',
                    imagePaths: [
                      'assets/docs/step4_otorisasi_sukses.png',
                      'assets/docs/step6_layar_pengaturan.png',
                    ],
                    badgeText: 'Siap Digunakan 24 Jam',
                    badgeColor: AppTheme.primaryDark,
                  ),
                  const SizedBox(height: 22),

                  // Section 2: Operasional Kasir
                  _buildSectionHeader(
                    icon: Icons.point_of_sale_rounded,
                    title: '2. Panduan Transaksi Kasir Cepat',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard([
                    _buildGuideItem(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Barcode Cepat:',
                      desc: 'Arahkan scanner kamera HP atau ketik barcode/nama di kolom cari atas untuk langsung memasukkan ke keranjang.',
                    ),
                    _buildGuideItem(
                      icon: Icons.price_change_outlined,
                      title: 'Harga Grosir Otomatis:',
                      desc: 'Saat jumlah beli mencapai syarat grosir (misal ≥ 5 bks / dus), harga otomatis turun ke harga grosir.',
                    ),
                    _buildGuideItem(
                      icon: Icons.pause_circle_outline_rounded,
                      title: 'Tahan Transaksi (Hold Order):',
                      desc: 'Jika pembeli lupa ambil barang lain, klik tombol "Hold". Kasir bisa melayani pembeli berikutnya tanpa menghapus keranjang lama.',
                    ),
                    _buildGuideItem(
                      icon: Icons.menu_book_rounded,
                      title: 'Pencatatan Buku Kasbon:',
                      desc: 'Untuk pembeli langganan yang berutang, pilih "Kasbon", isi nama & jatuh tempo. Data tersimpan rapi dan stok otomatis berkurang.',
                    ),
                    _buildGuideItem(
                      icon: Icons.refresh_rounded,
                      title: 'Pull-to-Refresh (Tarik ke Bawah):',
                      desc: 'Tarik ke bawah di katalog atau daftar kasbon untuk menyinkronkan seluruh master barang, akun kasir, rekap shift, dan mutasi dengan Spreadsheet.',
                    ),
                  ]),
                  const SizedBox(height: 22),

                  // Section 3: Shift & Oper Kasir
                  _buildSectionHeader(
                    icon: Icons.sync_alt_rounded,
                    title: '3. Serah Terima Shift & Ganti Penjaga 24 Jam',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard([
                    _buildGuideItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Rekonsiliasi Uang Fisik Laci:',
                      desc: 'Hitung uang kertas dan uang koin di laci kasir, sistem akan menghitung selisih pas, lebih, atau minus secara otomatis.',
                    ),
                    _buildGuideItem(
                      icon: Icons.smoking_rooms_rounded,
                      title: 'Audit Rokok & Barang Sensitif:',
                      desc: 'Cek stok fisik etalase rokok sebelum ganti shift untuk mencegah barang hilang atau selisih hitung.',
                    ),
                    _buildGuideItem(
                      icon: Icons.switch_account_rounded,
                      title: 'Ganti Shift Otomatis:',
                      desc: 'Pilih nama kasir pengganti dari daftar akun terdaftar. Sesi kasir langsung berpindah ke akun kasir baru.',
                    ),
                  ]),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGold.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppTheme.goldMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildVisualStepCard(
    BuildContext context, {
    required String stepNumber,
    required String title,
    required String desc,
    required List<String> imagePaths,
    required String badgeText,
    required Color badgeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Langkah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppTheme.primaryDark,
                  child: Text(
                    stepNumber,
                    style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(color: badgeColor, fontSize: 9.5, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Deskripsi
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Text(
              desc,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.45),
            ),
          ),

          // Screenshot Galeri Gambar jika ada
          if (imagePaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: imagePaths.map((path) {
                  return Container(
                    constraints: const BoxConstraints(maxHeight: 220, maxWidth: 330),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      path,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 120,
                        width: 200,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildGuideItem({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
