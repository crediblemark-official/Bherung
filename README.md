# 🛒 Bherung POS — Aplikasi Kasir & Manajemen Toko Kelontong 24 Jam

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Web%20|%20Android%20|%20Desktop-4CAF50?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production%20Ready-0D9488?style=for-the-badge)

**Bherung** adalah sistem kasir Point of Sale (POS) modern, cepat, dan *offline-first* yang dirancang khusus untuk memenuhi kebutuhan toko kelontong, agen sembako, dan **Toko Madura 24 Jam**. Didesain dengan antarmuka yang intuitif, mendukung pemindaian barcode kamera, pencatatan kasbon, serah terima shift kasir non-stop, dan manajemen stok lengkap.

---

## 🌟 Fitur Utama

### ⚡ 1. Kasir Cepat & Etalase Produk
- **Grid 3 Kolom Responsif**: Tampilan kartu produk kompak dan proporsional untuk perangkat smartphone.
- **Filter Stok Otomatis**: Hanya menampilkan produk yang memiliki stok tersedia (`stock > 0`) di etalase penjualan.
- **Kategori Dinamis (*Smart Category Picker*)**:
  - Pencarian kategori secara *real-time*.
  - Ketik nama kategori baru langsung tersimpan otomatis dengan penentuan ikon & palet warna cerdas.
- **Identitas Pembeli Fleksibel**:
  - Default transaksi untuk pelanggan `Umum`.
  - Formulir pencatatan nama pelanggan untuk transaksi kasbon, titipan, atau langganan.
- **Hold / Tahan Transaksi**: Parkir pesanan pelanggan saat ada tambahan barang belanjaan tanpa menghambat antrean berikutnya.

### 📷 2. Pemindai Barcode Kamera & Master Lookup
- **Scanner Kamera HP / Webcam**: Dilengkapi kontrol senter (*flashlight*), tombol ganti kamera (*flip*), dan animasi bidik laser.
- **Database Master Barcode FMCG**: Otomatis mengenali barcode ribuan produk populer sembako, rokok, dan minuman di Indonesia tanpa perlu input nama barang manual.
- **Quick Add Barcode Baru**: Pendaftaran kilat produk baru saat barcode belum terdata.
- **Tombol Scan Terintegrasi**: Floating action button yang menyatu rapi dalam lengkungan *curved bottom navigation bar*.

### 💳 3. Pembayaran Lengkap & Kasbon Pelanggan
- **Tunai / Cash**: Kalkulator kembalian otomatis dengan tombol cepat pecahan uang pas (Rp10rb, Rp20rb, Rp50rb, Rp100rb).
- **QRIS / Non-Tunai**: Penerimaan pembayaran transfer bank & QRIS dompet digital.
- **Buku Kasbon / Hutang**:
  - Pencatatan kasbon per nama pelanggan dengan nomor kontak dan batas jatuh tempo.
  - Riwayat pelunasan bertahap dan pelunasan lunas.
- **Struk Digital & Thermal Print**: Format struk kasir yang siap dicetak ke printer Bluetooth Thermal atau dibagikan via WhatsApp.

### 🔄 4. Serah Terima Shift 24 Jam (*Handover*)
- Dirancang khusus untuk toko yang beroperasi non-stop 24 jam.
- Perhitungan rekonsiliasi kas riil di laci uang vs total penjualan sistem POS.
- Audit stok barang bernilai tinggi / sensitif (Rokok, Minyak Goreng, Beras).
- Riwayat serah terima kasir antar shift tersimpan rapi.

### 📦 5. Manajemen Stok & Nilai Aset
- **Peringatan Stok Menipis (*Low Stock Alert*)**: Deteksi otomatis produk yang mendekati batas minimum stok.
- **Peringatan Kedaluwarsa (*Near Expiry Alert*)**: Pantau produk makanan/minuman yang mendekati tanggal kedaluwarsa.
- **Riwayat Mutasi Stok**: Pencatatan log lengkap (Restock, Penjualan Kasir, Penyesuaian/Barang Rusak).
- **Valuasi Modal**: Estimasi total nilai aset modal toko secara *real-time*.

### 🔐 6. Role Pengguna (Owner vs Kasir)
- **Mode Owner**: Akses penuh ke laporan laba kotor, harga modal kulakan, dan konfigurasi master data yang dilindungi PIN.
- **Mode Kasir/Staff**: Antarmuka bersih yang difokuskan khusus untuk kecepatan transaksi kasir.

---

## 🛠️ Arsitektur & Teknologi

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.x)
- **Language**: [Dart](https://dart.dev/) (SDK ^3.x)
- **State Management & UI**: Modular Widgets, Stateful/Stateless Component Architecture, Reactive Controllers
- **Local Persistence**: `shared_preferences` & JSON Local Storage Adapter (*Offline-first*)
- **Barcode & Scanner**: `mobile_scanner`
- **UI Design System**: Curated Emerald/Teal palette, Glassmorphism, Dark/Light contrast, Floating SnackBar theme

---

## 📂 Struktur Direktori Proyek

```text
lib/
├── main.dart                      # Entry point aplikasi
├── models/                        # Data models
│   ├── cart_item.dart             # Model keranjang belanja
│   ├── category.dart              # Model kategori produk
│   ├── held_order.dart            # Model pesanan ditahan (hold)
│   ├── kasbon_record.dart         # Model catatan kasbon pelanggan
│   ├── product.dart               # Model produk & sembako
│   ├── sample_data.dart           # Data inisial produk & master kategori
│   ├── shift_record.dart          # Model catatan shift kasir
│   ├── stock_mutation.dart        # Model log mutasi inventori
│   ├── transaction_type.dart      # Enum tipe pembayaran
│   └── user_role.dart             # Model pengguna & hak akses
├── screens/                       # Layar utama aplikasi
│   ├── pos_dashboard_screen.dart  # Layar kasir utama POS
│   ├── quick_add_product_screen.dart # Layar tambah cepat produk
│   ├── scanner_screen.dart        # Layar pemindai barcode kamera
│   ├── shift_handover_screen.dart # Layar serah terima shift kasir
│   └── stock_control_screen.dart  # Layar manajemen stok & inventori
├── services/                      # Layanan & helper bisnis
│   ├── barcode_master_lookup_service.dart # Lookup master barcode nasional
│   └── inventory_storage_service.dart     # Persistensi data lokal
├── theme/                         # Desain sistem & tema
│   └── app_theme.dart             # Palet warna, tipografi, dan tema aplikasi
└── widgets/                       # Komponen widget modular
    ├── cart_sidebar.dart          # Sidebar keranjang belanja & kasbon
    ├── checkout_dialog.dart       # Dialog konfirmasi pembayaran
    ├── dynamic_category_picker.dart # Pemilih & pembuat kategori dinamis
    ├── kasbon_list_dialog.dart    # Dialog daftar buku kasbon
    ├── product_card.dart          # Komponen kartu produk etalase
    ├── product_catalog_view.dart  # Grid etalase katalog produk
    ├── quick_add_product_dialog.dart # Dialog tambah cepat produk
    ├── receipt_dialog.dart        # Dialog cetak struk pembayaran
    ├── restock_inventory_dialog.dart # Dialog tambah stok/kulakan barang
    ├── role_switcher_dialog.dart  # Dialog ganti peran & verifikasi PIN
    └── search_filter_bar.dart     # Bar pencarian & filter kategori
```

---

## 🚀 Panduan Menjalankan Aplikasi

### 1. Prasyarat
Pastikan Flutter SDK sudah terpasang di komputer Anda:
```bash
flutter --version
```

### 2. Pasang Dependensi
Jalankan perintah berikut di direktori proyek:
```bash
flutter pub get
```

### 3. Jalankan Aplikasi
Jalankan aplikasi di perangkat target (Web Browser, Chrome, Android, atau Desktop):
```bash
# Menjalankan di Chrome / Web Browser
flutter run -d chrome

# Menjalankan di perangkat Android fisik / emulator
flutter run -d android
```

### 4. Periksa Analisis Kode
Pastikan seluruh kode bersih tanpa error:
```bash
flutter analyze
```

---

## 📝 Lisensi
Proyek ini dikembangkan untuk kebutuhan operasional toko ritel, sembako, dan toko kelontong modern. Hak cipta dilindungi undang-undang.
