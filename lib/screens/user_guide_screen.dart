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
                        'Buka menu Pengaturan > Tab Database & Cloud, lalu klik tombol "Salin Link Template Google Sheets". Buka link tersebut di browser laptop/HP Anda, lalu klik tombol "Make a copy / Buat salinan" agar database resmi toko tersimpan di akun Google Drive pribadi Anda.',
                    imagePaths: [
                      'assets/docs/step0_salin_template.png',
                      'assets/docs/step0_buat_salinan.png',
                    ],
                    badgeText: 'Langkah Pertama (10 Detik)',
                    badgeColor: AppTheme.primaryTeal,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '2',
                    title: 'Jalankan Menu "Bherung POS" di Spreadsheet',
                    desc:
                        'Buka Google Spreadsheet di laptop/komputer. Klik menu khusus "🏪 Bherung POS" di bilah atas, lalu pilih opsi:\n"🔑 1. Otorisasi & Aktifkan Database Kasir" untuk mengaktifkan seluruh 7 tabel database toko serta memberikan akses robot Service Account secara otomatis tanpa perlu atur berbagi manual.',
                    imagePaths: [
                      'assets/docs/step3_menu_otorisasi.png',
                    ],
                    badgeText: 'Otomatis 1-Klik',
                    badgeColor: AppTheme.primaryGold,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: '3',
                    title: 'Izinkan Otorisasi Keamanan Akun Google',
                    desc:
                        'Google akan menampilkan dialog otorisasi izin keamanan. Klik "Oke", pilih akun Google Anda, centang izin Google Drive & Spreadsheet, lalu klik tombol "Lanjutkan / Izinkan". Otorisasi ini hanya perlu dilakukan satu kali saja di awal.',
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
                    stepNumber: '4',
                    title: 'Salin ID Spreadsheet atau URL Apps Script ke Aplikasi',
                    desc:
                        'Setelah otorisasi selesai, ID Spreadsheet akan muncul di layar. Anda juga bisa menyalin link URL lengkap dari address bar browser.\n\nBuka menu Pengaturan > Tab Database & Cloud di aplikasi Bherung POS, tempelkan ID Spreadsheet atau URL Web App Apps Script, lalu klik tombol "Hubungkan & Simpan Database". Aplikasi kini langsung terhubung tanpa batas limit pengguna (Unlimited)!',
                    imagePaths: [
                      'assets/docs/step4_otorisasi_sukses.png',
                      'assets/docs/step6_layar_pengaturan.png',
                    ],
                    badgeText: 'Bebas Limit 100 User (Unlimited)',
                    badgeColor: AppTheme.primaryDark,
                  ),
                  const SizedBox(height: 22),

                  // Section 2: Panduan Deploy Apps Script Mandiri (Opsional)
                  _buildSectionHeader(
                    icon: Icons.code_rounded,
                    title: '2. Panduan Deploy Apps Script Mandiri (Opsional / Custom URL)',
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bagian ini bersifat OPSIONAL. Anda hanya perlu melakukannya jika ingin mendeploy backend script sendiri di Google Drive pribadi Anda untuk mendapatkan URL Web App khusus.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                  _buildVisualStepCard(
                    context,
                    stepNumber: 'A',
                    title: 'Buka Editor Apps Script dari Spreadsheet',
                    desc:
                        'Di Google Spreadsheet toko Anda (di laptop/komputer), klik menu "Ekstensi" (Extensions) di bilah atas, lalu pilih opsi "Apps Script".',
                    imagePaths: [
                      'assets/docs/gas_step1_ekstensi.png',
                    ],
                    badgeText: 'Langkah A (Opsional)',
                    badgeColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: 'B',
                    title: 'Pilih Menu "Terapkan" ➡️ "Deployment baru"',
                    desc:
                        'Pada editor Google Apps Script, klik tombol biru "Terapkan" (Deploy) di pojok kanan atas, kemudian pilih menu "Deployment baru" (New deployment).',
                    imagePaths: [
                      'assets/docs/gas_step2_editor.png',
                      'assets/docs/gas_step3_terapkan.png',
                    ],
                    badgeText: 'Langkah B (Opsional)',
                    badgeColor: const Color(0xFF2563EB),
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: 'C',
                    title: 'Konfigurasi Hak Akses "Siapa saja (Anyone)"',
                    desc:
                        'Pada jendela Deployment baru, atur konfigurasi berikut:\n'
                        '• Pilih jenis: Aplikasi web (Web app)\n'
                        '• Jalankan sebagai: Saya (email akun Google Anda)\n'
                        '• Yang memiliki akses: Siapa saja (Anyone)\n\n'
                        '⚠️ PENTING: Wajib pilih "Siapa saja" agar HP kasir & toko dapat menyimpan data penjualan secara instan. Lalu klik tombol biru "Terapkan".',
                    imagePaths: [
                      'assets/docs/gas_step4_konfigurasi.png',
                    ],
                    badgeText: 'PENTING: Akses Siapa Saja',
                    badgeColor: AppTheme.dangerRed,
                  ),
                  const SizedBox(height: 12),

                  _buildVisualStepCard(
                    context,
                    stepNumber: 'D',
                    title: 'Salin "Aplikasi Web URL" ke Bherung POS',
                    desc:
                        'Setelah penerapan selesai, klik tombol "Salin" pada bagian Aplikasi web URL (link berakhiran /exec).\n\nTempelkan link URL tersebut ke kolom input "URL Web App Google Apps Script" di menu Pengaturan Bherung POS, lalu klik "Hubungkan & Simpan Database". Selesai!',
                    imagePaths: [
                      'assets/docs/gas_step5_salin_url.png',
                      'assets/docs/gas_step6_input_pengaturan.png',
                    ],
                    badgeText: 'URL Web App Siap',
                    badgeColor: AppTheme.successGreen,
                  ),
                  const SizedBox(height: 22),

                  // Section 3: Operasional Kasir
                  _buildSectionHeader(
                    icon: Icons.point_of_sale_rounded,
                    title: '3. Panduan Transaksi Kasir Cepat',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard([
                    _buildGuideItem(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Barcode Cepat:',
                      desc: 'Arahkan scanner kamera HP atau ketik barcode/nama di kolom cari atas untuk langsung memasukkan barang ke keranjang.',
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
                      title: 'Pencatatan Buku Kasbon Pelanggan:',
                      desc: 'Untuk pembeli langganan yang berutang, pilih "Kasbon", isi nama & jatuh tempo. Data tersimpan rapi dan stok otomatis berkurang.',
                    ),
                    _buildGuideItem(
                      icon: Icons.refresh_rounded,
                      title: 'Pull-to-Refresh (Tarik ke Bawah):',
                      desc: 'Tarik ke bawah di katalog atau daftar kasbon untuk menyinkronkan seluruh master barang, stok, dan mutasi dengan Spreadsheet toko.',
                    ),
                  ]),
                  const SizedBox(height: 22),

                  // Section 4: Oper Jaga & Ganti Kasir
                  _buildSectionHeader(
                    icon: Icons.sync_alt_rounded,
                    title: '4. Serah Terima Jaga & Ganti Penjaga 24 Jam (Khusus Owner)',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard([
                    _buildGuideItem(
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Otorisasi Khusus Pemilik Toko (Owner):',
                      desc: 'Menu Serah Terima Jaga hanya bisa dibuka dan disahkan oleh Pemilik Toko (PIN 1234) untuk menjamin transparansi & keamanan toko.',
                    ),
                    _buildGuideItem(
                      icon: Icons.point_of_sale_rounded,
                      title: 'Audit & Rekonsiliasi Fisik Langsung:',
                      desc: 'Pemilik Toko menghitung uang kas riil di laci dan stok fisik rokok/barang berharga bersama penjaga yang sedang bertugas di meja kasir.',
                    ),
                    _buildGuideItem(
                      icon: Icons.lock_clock_rounded,
                      title: 'Auto-Logout & Sambutan Kasir Baru:',
                      desc: 'Begitu serah terima jaga disahkan, sesi kasir lama otomatis terlogout dan layar terkunci menyambut penjaga jaga berikutnya: "Silahkan masuk Tretan [Nama Penjaga]".',
                    ),
                  ]),
                  const SizedBox(height: 22),

                  // Section 5: Manajemen Akun & PIN
                  _buildSectionHeader(
                    icon: Icons.badge_rounded,
                    title: '5. Role Akun Kasir & Autentikasi PIN',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideCard([
                    _buildGuideItem(
                      icon: Icons.workspace_premium_rounded,
                      title: 'Pemilik Toko (Owner / PIN 1234):',
                      desc: 'Akses penuh ke pengaturan toko, harga modal, tambah/edit kasir, serah terima shift, dan memiliki tombol "Keluar Akun Pemilik Toko" di bilah atas.',
                    ),
                    _buildGuideItem(
                      icon: Icons.person_rounded,
                      title: 'Penjaga Toko (Kasir / PIN 5678):',
                      desc: 'Fokus pada kecepatan transaksi belanja, cetak nota, dan scan barcode tanpa bisa mengakses pengaturan master atau menu oper shift.',
                    ),
                    _buildGuideItem(
                      icon: Icons.pin_outlined,
                      title: 'Auto Identifikasi Role:',
                      desc: 'Cukup masukkan 4-digit PIN pada layar login, sistem otomatis mengenali peran pengguna secara instan.',
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
