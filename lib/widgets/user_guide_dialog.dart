import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserGuideDialog extends StatelessWidget {
  const UserGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppTheme.primaryTeal, size: 20),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buku Panduan Kasir & Database',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                    Text(
                      'Petunjuk Lengkap Operasional Toko Madura & Sembako',
                      style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16, color: AppTheme.borderColor),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Operasional Kasir
                    _buildSectionHeader(
                      icon: Icons.point_of_sale_rounded,
                      title: '1. Panduan Transaksi Kasir',
                    ),
                    const SizedBox(height: 6),
                    _buildGuideCard([
                      _buildGuideItem(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan Barcode Cepat:',
                        desc: 'Arahkan scanner atau ketik barcode/nama di kolom cari atas. Tekan Enter untuk langsung memasukkan ke keranjang.',
                      ),
                      _buildGuideItem(
                        icon: Icons.price_change_outlined,
                        title: 'Harga Grosir Otomatis:',
                        desc: 'Saat jumlah beli mencapai syarat grosir (misal ≥ 5 bks / dus), harga otomatis turun ke harga grosir.',
                      ),
                      _buildGuideItem(
                        icon: Icons.pause_circle_outline_rounded,
                        title: 'Tahan Transaksi (Hold Order):',
                        desc: 'Jika pembeli lupa ambil barang lain, klik tombol "Tahan Order". Kasir bisa melayani pembeli berikutnya tanpa menghapus keranjang lama.',
                      ),
                      _buildGuideItem(
                        icon: Icons.menu_book_rounded,
                        title: 'Pencatatan Buku Kasbon:',
                        desc: 'Untuk pembeli langganan yang berutang, pilih "Kasbon Pelanggan", isi nama & jatuh tempo. Data tersimpan rapi dan stok otomatis berkurang.',
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Section 2: Setup Database Google Spreadsheet
                    _buildSectionHeader(
                      icon: Icons.cloud_done_rounded,
                      title: '2. Panduan Setup Database Spreadsheet (Toko Baru)',
                    ),
                    const SizedBox(height: 6),
                    _buildGuideCard([
                      _buildStepItem(
                        step: '1',
                        title: 'Salin File Template Google Spreadsheet',
                        desc: 'Buka menu Pengaturan ⚙️ > klik "Salin Link Template". Di browser, buat salinan ke akun Google Drive toko Anda.',
                      ),
                      _buildStepItem(
                        step: '2',
                        title: 'Atur Izin Akses Berbagi ke "Editor"',
                        desc: 'Di file Spreadsheet baru Anda: Klik Bagikan (Share) > Akses umum pilih "Siapa saja yang memiliki link" > Ubah ke "Editor" > Selesai.',
                      ),
                      _buildStepItem(
                        step: '3',
                        title: 'Hubungkan ke Aplikasi Kasir',
                        desc: 'Salin Link atau ID Spreadsheet dari browser Anda, paste ke menu Pengaturan di aplikasi kasir, lalu klik "Hubungkan & Simpan Database".',
                      ),
                      _buildStepItem(
                        step: '4',
                        title: 'Sinkronisasi Katalog Sembako Awal',
                        desc: 'Klik tombol "Sync 17 Katalog Sembako" untuk mengisi master barang sembako awal secara otomatis.',
                      ),
                    ]),
                    const SizedBox(height: 14),

                    // Section 3: Fitur di Dalam Google Spreadsheet
                    _buildSectionHeader(
                      icon: Icons.table_view_rounded,
                      title: '3. Menu Khusus di Google Spreadsheet',
                    ),
                    const SizedBox(height: 6),
                    _buildGuideCard([
                      _buildGuideItem(
                        icon: Icons.verified_rounded,
                        title: 'Menu 🏪 Bherung POS di Bilah Atas Spreadsheet:',
                        desc: 'Di dalam Spreadsheet toko Anda tersedia menu khusus untuk otorisasi, reset tabel, dan hitung rekap omset harian secara instan.',
                      ),
                      _buildGuideItem(
                        icon: Icons.offline_bolt_rounded,
                        title: 'Mode Offline Kasir:',
                        desc: 'Saat internet mati, kasir tetap berjalan normal 100%. Begitu internet terhubung, transaksi offline bisa disinkronkan ke Spreadsheet dengan 1 klik.',
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Footer Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Tutup Buku Panduan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryTeal),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
        ),
      ],
    );
  }

  Widget _buildGuideCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildGuideItem({required IconData icon, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryTeal),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: AppTheme.textDark, height: 1.35),
                children: [
                  TextSpan(text: '$title ', style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: desc, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required String step, required String title, required String desc}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 17,
            height: 17,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primaryTeal,
              shape: BoxShape.circle,
            ),
            child: Text(
              step,
              style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 11, color: AppTheme.textDark, height: 1.35),
                children: [
                  TextSpan(text: '$title\n', style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(text: desc, style: const TextStyle(color: AppTheme.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
