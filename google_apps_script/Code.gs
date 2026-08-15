/**
 * =======================================================================
 * BHERUNG POS - GOOGLE APPS SCRIPT BACKEND (TOKO SEMBAKO & MADURA 24 JAM)
 * =======================================================================
 * 
 * Script ini mengelola SELURUH DATABASE Spreadsheet untuk aplikasi POS Bherung:
 * 1. Sheet "Produk"         : Master katalog produk, barcode SKU, stok, harga eceran & grosir.
 * 2. Sheet "Transaksi"      : Rekap riwayat transaksi penjualan & rincian belanjaan.
 * 3. Sheet "Buku_Kasbon"    : Catatan utang kasbon pelanggan & status jatuh tempo.
 * 4. Sheet "Pengguna_Kasir" : Akun penjaga toko, role/peran, dan PIN akses.
 * 5. Sheet "Shift_Rekap"    : Catatan rekonsiliasi kas operan shift kasir 24 jam.
 * 6. Sheet "Mutasi_Stok"    : Log kartu mutasi keluar-masuk barang & kulakan.
 * 7. Sheet "Profil_Toko"    : Identitas toko, kas awal default, QRIS, & rekening bank.
 */

// Custom Menu di Bilah Atas Spreadsheet saat dibuka oleh Pemilik Toko
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🏪 Bherung POS')
    .addItem('🔑 1. Otorisasi & Aktifkan Database Kasir', 'authorizeAndGetId')
    .addItem('📦 2. Update Katalog Lengkap 2026 (Tanpa Barcode)', 'updateCatalog2026')
    .addItem('🔄 3. Rapikan Format Seluruh Tabel', 'formatDatabaseSheets')
    .addSeparator()
    .addItem('📊 Cek Rekap Omset Hari Ini', 'calculateTodaySales')
    .addToUi();
}

/**
 * Fungsi 1: Otorisasi & Tampilkan ID Spreadsheet Toko
 */
function authorizeAndGetId() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  formatDatabaseSheets();
  const id = ss.getId();

  SpreadsheetApp.getUi().alert(
    '✅ OTORISASI BERHASIL!\n\n' +
    'Database Toko Bherung POS Anda sudah aktif & siap digunakan.\n\n' +
    'ID Spreadsheet Anda:\n' + id + '\n\n' +
    '👉 Silakan salin ID di atas dan tempelkan ke menu Pengaturan di Aplikasi Kasir Bherung POS!'
  );
}

/**
 * Fungsi 2: Mengisi / Memperbarui Seluruh Katalog Lengkap 2026 (Kolom Barcode Dikosongi)
 */
function updateCatalog2026() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = getOrCreateSheet(ss, 'Produk', true);

  const catalog2026 = [
    // 1. BERAS & SEMBAKO
    ['sbk-01', 'Beras Ramos Setra Pulen 5kg', '', 'sembako', 74000, 72000, 5, 'sak', 50, 'Beras putih pulen wangi kualitas super 5kg'],
    ['sbk-02', 'Beras Pandan Wangi Premium 5kg', '', 'sembako', 82000, 80000, 5, 'sak', 35, 'Beras aroma pandan alami pulen 5kg'],
    ['sbk-03', 'Beras Ramos Curah 1kg', '', 'sembako', 15000, 14500, 10, 'kg', 150, 'Beras timbangan eceran kualitas pulen'],
    ['sbk-04', 'Minyak Goreng Minyakita 1L Pouch', '', 'sembako', 16500, 15500, 12, 'pouch', 120, 'Minyak goreng subsidi pemerintah 1L'],
    ['sbk-05', 'Minyak Goreng Bimoli 2L Pouch', '', 'sembako', 38500, 37000, 6, 'pouch', 60, 'Minyak goreng kelapa sawit murni 2L'],
    ['sbk-06', 'Minyak Goreng SunCo 2L Pouch', '', 'sembako', 39000, 37500, 6, 'pouch', 50, 'Minyak goreng bening tidak beku 2L'],
    ['sbk-07', 'Minyak Goreng Tropical 2L Botol', '', 'sembako', 40000, 38500, 6, 'botol', 40, 'Minyak goreng 2x penyaringan 2L botol'],
    ['sbk-08', 'Telur Ayam Negeri Fresh 1 Kg', '', 'sembako', 29000, 27500, 10, 'kg', 80, 'Telur ayam ras segar pilihan (~16 butir)'],
    ['sbk-09', 'Gula Pasir Gulaku Tebu Kuning 1kg', '', 'sembako', 18500, 17500, 10, 'kg', 70, 'Gula tebu murni kemasan kuning 1kg'],
    ['sbk-10', 'Gula Pasir GMP Curah 1kg', '', 'sembako', 17500, 16800, 10, 'kg', 100, 'Gula pasir putih manis timbangan ecer'],
    ['sbk-11', 'Gula Merah / Jawa Super 1kg', '', 'sembako', 22000, 20500, 5, 'kg', 40, 'Gula kelapa aren asli padat legit'],
    ['sbk-12', 'Tepung Terigu Segitiga Biru 1kg', '', 'sembako', 13000, 12200, 10, 'kg', 60, 'Tepung terigu serbaguna Bogasari 1kg'],
    ['sbk-13', 'Tepung Terigu Cakra Kembar 1kg', '', 'sembako', 14500, 13800, 10, 'kg', 45, 'Tepung terigu protein tinggi donat & roti'],
    ['sbk-14', 'Tepung Tapioka Rose Brand 500g', '', 'sembako', 8000, 7500, 10, 'bks', 50, 'Tepung kanji tapioka murni'],
    ['sbk-15', 'Tepung Beras Rose Brand 500g', '', 'sembako', 8500, 7800, 10, 'bks', 45, 'Tepung beras putih murni higienis'],

    // 2. MIE & MAKANAN INSTAN
    ['mie-01', 'Indomie Goreng Original 85g', '', 'mie_makanan', 3500, 3200, 5, 'bks', 240, 'Mie instan goreng favorit'],
    ['mie-02', 'Indomie Kuah Soto Mie 70g', '', 'mie_makanan', 3500, 3200, 5, 'bks', 180, 'Mie kuah rasa soto mie gurih segar'],
    ['mie-03', 'Indomie Kuah Ayam Bawang 70g', '', 'mie_makanan', 3500, 3200, 5, 'bks', 150, 'Mie instan kuah kaldu ayam bawang'],
    ['mie-04', 'Indomie Kuah Kari Ayam 72g', '', 'mie_makanan', 3800, 3500, 5, 'bks', 120, 'Mie kuah kental rasa kari ayam spesial'],
    ['mie-05', 'Mie Sedaap Goreng Original 90g', '', 'mie_makanan', 3500, 3200, 5, 'bks', 160, 'Mie goreng kriuk bawang renyah'],
    ['mie-06', 'Mie Sedaap Kuah Soto Madura 75g', '', 'mie_makanan', 3500, 3200, 5, 'bks', 140, 'Mie soto dengan serbuk koya gurih'],
    ['mie-07', 'Sarimi Isi 2 Goreng Ayam Kremes', '', 'mie_makanan', 4500, 4000, 5, 'bks', 90, 'Porsi dobel 2 keping mie goreng kenyang'],
    ['mie-08', 'Pop Mie Kuah Ayam Bawang Cup', '', 'mie_makanan', 6000, 5500, 6, 'cup', 60, 'Mie seduh praktis cup rasa ayam bawang'],
    ['mie-09', 'Pop Mie Goreng Pedas Gledek Cup', '', 'mie_makanan', 6500, 6000, 6, 'cup', 50, 'Mie cup goreng ekstra pedas'],
    ['mie-10', 'BihunKu Instan Goreng Spesial 60g', '', 'mie_makanan', 4000, 3500, 5, 'bks', 50, 'Bihun instan lembut rendah kalori'],
    ['mie-11', 'Sarden ABC Saus Tomat 155g (Kaleng Kecil)', '', 'mie_makanan', 11500, 10800, 6, 'kaleng', 40, 'Ikan sarden saus tomat siap saji'],
    ['mie-12', 'Sarden ABC Saus Cabai 425g (Kaleng Besar)', '', 'mie_makanan', 26000, 24500, 4, 'kaleng', 30, 'Ikan sarden saus cabai pedas mantap'],
    ['mie-13', 'Kornet Sapi Pronas 198g', '', 'mie_makanan', 24000, 22500, 4, 'kaleng', 25, 'Daging kornet sapi olahan utama'],

    // 3. MINUMAN DINGIN & SACHET
    ['mnm-01', 'Le Minerale Botol Dingin 600ml', '', 'minuman', 3500, 3000, 12, 'botol', 100, 'Air mineral alami dingin'],
    ['mnm-02', 'Le Minerale Botol Dingin 1500ml', '', 'minuman', 6500, 5800, 6, 'botol', 60, 'Air mineral botol besar 1.5L dingin'],
    ['mnm-03', 'Aqua Botol Dingin 600ml', '', 'minuman', 4000, 3500, 12, 'botol', 120, 'Air mineral Aqua 600ml dingin'],
    ['mnm-04', 'Aqua Botol Dingin 1500ml', '', 'minuman', 7000, 6200, 6, 'botol', 60, 'Air mineral Aqua jumbo 1.5L'],
    ['mnm-05', 'Teh Pucuk Harum Dingin 350ml', '', 'minuman', 4000, 3500, 6, 'botol', 80, 'Teh melati manis segar dingin'],
    ['mnm-06', 'Teh Botol Sosro Kotak 250ml', '', 'minuman', 3500, 3000, 12, 'kotak', 60, 'Teh wangi melati kemasan kotak'],
    ['mnm-07', 'Floridina Orange Dingin 350ml', '', 'minuman', 3500, 3000, 12, 'botol', 70, 'Minuman jus jeruk bulir asli'],
    ['mnm-08', 'Golda Coffee Dolce Latte 200ml', '', 'minuman', 3500, 3000, 12, 'botol', 75, 'Kopi susu creamy Italia dingin'],
    ['mnm-09', 'Bear Brand Susu Steril 189ml', '', 'minuman', 10500, 9800, 6, 'kaleng', 50, 'Susu sapi murni steril 100%'],
    ['mnm-10', 'Pocari Sweat Botol Dingin 500ml', '', 'minuman', 8000, 7500, 6, 'botol', 45, 'Minuman isotonik pengganti ion'],
    ['mnm-11', 'Ultra Milk UHT Cokelat 250ml', '', 'minuman', 6500, 6000, 6, 'kotak', 50, 'Susu cair segar UHT rasa cokelat'],
    ['mnm-12', 'Kopi Kapal Api Spesial Mix (1 Renceng)', '', 'minuman', 15000, 14000, 5, 'renceng', 50, 'Kopi bubuk hitam + gula pas (10 sachet)'],
    ['mnm-13', 'Kopi Good Day Mocacinno (1 Renceng)', '', 'minuman', 16500, 15200, 5, 'renceng', 45, 'Kopi instan rasa moka (10 sachet)'],
    ['mnm-14', 'Kopi Luwak White Koffie (1 Renceng)', '', 'minuman', 15500, 14500, 5, 'renceng', 40, 'Kopi putih aman di lambung (10 sachet)'],
    ['mnm-15', 'Nutrisari Jeruk Peras (1 Renceng)', '', 'minuman', 13000, 12000, 5, 'renceng', 40, 'Serbuk minuman jeruk bervitamin C (10 sachet)'],

    // 4. BUMBU DAPUR & MASAK
    ['bmb-01', 'Kecap Manis Bango Refill 520ml', '', 'bumbu', 24500, 23000, 6, 'pouch', 40, 'Kecap manis kedelai hitam Mallika 520ml'],
    ['bmb-02', 'Kecap Manis ABC Refill 520ml', '', 'bumbu', 20000, 18800, 6, 'pouch', 35, 'Kecap manis mantap kemasan refill 520ml'],
    ['bmb-03', 'Royco Rasa Ayam (1 Renceng/12 Sachet)', '', 'bumbu', 6000, 5500, 5, 'renceng', 60, 'Bumbu penyedap rasa kaldu ayam'],
    ['bmb-04', 'Masako Rasa Sapi (1 Renceng/12 Sachet)', '', 'bumbu', 6000, 5500, 5, 'renceng', 50, 'Bumbu ekstrak daging sapi gurih'],
    ['bmb-05', 'Santan Kelapa Siap Pakai Kara 65ml', '', 'bumbu', 3500, 3200, 10, 'pcs', 90, 'Santan kelapa murni segitiga 65ml'],
    ['bmb-06', 'Saori Saus Tiram 133ml Botol', '', 'bumbu', 12000, 11200, 6, 'botol', 30, 'Saus tiram gurih tumisan 133ml'],
    ['bmb-07', 'Ladaku Merica Bubuk (1 Renceng)', '', 'bumbu', 12000, 11000, 5, 'renceng', 40, 'Merica putih murni 100% (12 sachet)'],
    ['bmb-08', 'Garam Dapur Beryodium Cap Kapal 250g', '', 'bumbu', 3000, 2500, 10, 'bks', 80, 'Garam meja beryodium 250g'],
    ['bmb-09', 'Terasi Udang ABC (1 Pack/20 Pcs)', '', 'bumbu', 12000, 11000, 5, 'pack', 35, 'Terasi udang rebon asli untuk sambal'],

    // 5. ROKOK & TEMBAKAU
    ['rkk-01', 'Gudang Garam Surya 16 Bungkus', '', 'rokok', 36500, 355000, 10, 'bks', 120, 'Rokok filter GG Surya isi 16'],
    ['rkk-02', 'Sampoerna A Mild 16 Bungkus', '', 'rokok', 35500, 345000, 10, 'bks', 100, 'Rokok mild kretek isi 16'],
    ['rkk-03', 'Djarum Super 12 Bungkus', '', 'rokok', 25500, 248000, 10, 'bks', 90, 'Rokok kretek filter Djarum isi 12'],
    ['rkk-04', 'Marlboro Filter Red 20 Bungkus', '', 'rokok', 46000, 450000, 10, 'bks', 50, 'Rokok putih Marlboro Merah 20'],
    ['rkk-05', 'Marlboro Filter Black 20 Bungkus', '', 'rokok', 45000, 440000, 10, 'bks', 50, 'Rokok kretek filter rasa halus hitam 20'],
    ['rkk-06', 'Esse Change Double 20 Bungkus', '', 'rokok', 44000, 430000, 10, 'bks', 40, 'Rokok kapsul ganda rasa segar buah & mint 20'],
    ['rkk-07', 'Camel Yellow Filter 20 Bungkus', '', 'rokok', 32000, 310000, 10, 'bks', 40, 'Rokok Camel kuning filter isi 20'],
    ['rkk-08', 'Dji Sam Soe 234 Kuning 12 Batang', '', 'rokok', 22000, 212000, 10, 'bks', 70, 'Rokok kretek tanpa filter legendaris 234'],
    ['rkk-09', 'LA Bold 20 Bungkus', '', 'rokok', 34000, 330000, 10, 'bks', 60, 'Rokok kretek filter mantap LA Bold 20'],
    ['rkk-10', 'Djarum 76 Filter Gold 12', '', 'rokok', 18000, 172000, 10, 'bks', 50, 'Rokok kretek aroma khas Nusantara 12'],

    // 6. SABUN & KEBUTUHAN RUMAH TANGGA
    ['sbn-01', 'Sabun Cuci Piring Sunlight Jeruk Nipis 650ml', '', 'sabun_rumah', 14500, 13500, 6, 'pouch', 50, 'Pencuci piring jeruk nipis 650ml'],
    ['sbn-02', 'Sabun Cuci Piring Mama Lemon 680ml', '', 'sabun_rumah', 13500, 12500, 6, 'pouch', 45, 'Sabun cuci piring lemon segar 680ml'],
    ['sbn-03', 'Deterjen Bubuk Daia Bunga 850g', '', 'sabun_rumah', 19000, 18000, 6, 'bks', 40, 'Deterjen pembersih pakaian wangi bunga 850g'],
    ['sbn-04', 'Deterjen Bubuk Rinso Molto 770g', '', 'sabun_rumah', 26000, 24500, 6, 'bks', 35, 'Deterjen konsentrat anti noda 770g'],
    ['sbn-05', 'SoKlin Liquid Deterjen Cair 750ml Pouch', '', 'sabun_rumah', 18500, 17500, 6, 'pouch', 35, 'Deterjen cair konsentrat harum 750ml'],
    ['sbn-06', 'Pewangi Pakaian Downy Mystique Refill 650ml', '', 'sabun_rumah', 28000, 26500, 4, 'pouch', 25, 'Pelembut pakaian aroma parfum 650ml'],
    ['sbn-07', 'Sabun Mandi Batang Lifebuoy Total 10 (4x85g)', '', 'sabun_rumah', 16500, 15500, 6, 'pack', 40, 'Sabun perlindungan kuman 4 batang'],
    ['sbn-08', 'Sabun Mandi Cair Dettol Pouch 410ml', '', 'sabun_rumah', 27500, 25500, 4, 'pouch', 30, 'Sabun cair antiseptik kulit 410ml'],
    ['sbn-09', 'Pasta Gigi Pepsodent White 190g', '', 'sabun_rumah', 14500, 13500, 6, 'pcs', 50, 'Pasta gigi perlindungan gigi berlubang 190g'],
    ['sbn-10', 'Obat Nyamuk Semprot Baygon 600ml Kaleng', '', 'sabun_rumah', 39000, 37000, 4, 'kaleng', 25, 'Aerosol pembasmi nyamuk 600ml'],

    // 7. GAS LPG & AIR GALON
    ['gas-01', 'Isi Ulang Gas LPG 3 Kg (Melon)', '', 'gas_galon', 22000, 21000, 5, 'tabung', 40, 'Tukar tabung isi ulang elpiji 3kg bersubsidi'],
    ['gas-02', 'Isi Ulang Gas Bright Gas 5.5 Kg', '', 'gas_galon', 95000, 92000, 3, 'tabung', 15, 'Tukar tabung gas Bright Gas 5.5kg nonsubsidi'],
    ['gas-03', 'Isi Ulang Gas Bright Gas 12 Kg', '', 'gas_galon', 215000, 210000, 2, 'tabung', 10, 'Tukar tabung gas Bright Gas 12kg jumbo'],
    ['gas-04', 'Isi Ulang Galon Aqua 19 Liter Asli Segel', '', 'gas_galon', 20000, 19000, 5, 'galon', 35, 'Tukar galon air mineral Aqua 19L tutup segel asli'],
    ['gas-05', 'Isi Ulang Galon Le Minerale 15 Liter', '', 'gas_galon', 18500, 17500, 5, 'galon', 30, 'Galon Le Minerale 15L bebas BPA'],
    ['gas-06', 'Isi Ulang Galon Cleo 19 Liter', '', 'gas_galon', 18000, 17000, 5, 'galon', 25, 'Air murni Cleo galon 19L tutup segel']
  ];

  // Batch insert ke Google Spreadsheet dalam 1 operasi kilat
  sheet.getRange(2, 1, catalog2026.length, 10).setValues(catalog2026);

  SpreadsheetApp.getUi().alert(
    '✅ SUKSES MEMPERBARUI KATALOG 2026!\n\n' +
    'Sebanyak ' + catalog2026.length + ' produk FMCG resmi telah berhasil diisi ke tab "Produk".\n' +
    'Kolom Barcode_SKU telah dikosongkan ("").\n\n' +
    '👉 Buka Aplikasi Kasir Bherung POS di HP/Komputer dan klik "🔄 Sinkronisasi Penuh Database Toko"!'
  );
}

/**
 * Fungsi 2: Merapikan Format Seluruh 7 Tabel Resmi Database Toko
 */
function formatDatabaseSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  getOrCreateSheet(ss, 'Produk');
  getOrCreateSheet(ss, 'Transaksi');
  getOrCreateSheet(ss, 'Buku_Kasbon');
  getOrCreateSheet(ss, 'Pengguna_Kasir');
  getOrCreateSheet(ss, 'Shift_Rekap');
  getOrCreateSheet(ss, 'Mutasi_Stok');
  getOrCreateSheet(ss, 'Profil_Toko');
}

/**
 * Fungsi 4: Cek Rekap Omset Hari Ini
 */
function calculateTodaySales() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetTrx = ss.getSheetByName('Transaksi');
  if (!sheetTrx || sheetTrx.getLastRow() <= 1) {
    SpreadsheetApp.getUi().alert('Belum ada data transaksi tercatat.');
    return;
  }

  const todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd');
  const data = sheetTrx.getDataRange().getValues();
  let totalOmset = 0;
  let totalTrx = 0;

  for (let i = 1; i < data.length; i++) {
    const rowDate = data[i][1] instanceof Date
      ? Utilities.formatDate(data[i][1], Session.getScriptTimeZone(), 'yyyy-MM-dd')
      : String(data[i][1]);
    
    if (rowDate === todayStr) {
      totalOmset += Number(data[i][7]) || 0;
      totalTrx++;
    }
  }

  SpreadsheetApp.getUi().alert(
    '📊 Rekap Omset Toko Hari Ini (' + todayStr + '):\n\n' +
    '• Total Transaksi : ' + totalTrx + ' transaksi\n' +
    '• Total Omset     : Rp ' + totalOmset.toLocaleString('id-ID')
  );
}

function getTargetSpreadsheet(e, body) {
  let targetId = '';
  if (e && e.parameter && e.parameter.spreadsheetId) {
    targetId = e.parameter.spreadsheetId;
  } else if (body && body.spreadsheetId) {
    targetId = body.spreadsheetId;
  }

  if (targetId && targetId.trim().length > 5) {
    try {
      return SpreadsheetApp.openById(targetId.trim());
    } catch (err) {
      Logger.log('Gagal membuka spreadsheet by ID (' + targetId + '): ' + err);
    }
  }

  const active = SpreadsheetApp.getActiveSpreadsheet();
  if (active) return active;

  return initDatabaseSpreadsheet();
}

function doGet(e) {
  try {
    const action = (e && e.parameter && e.parameter.action) ? e.parameter.action : 'ping';
    const ss = getTargetSpreadsheet(e, {});

    if (action === 'ping') {
      return jsonResponse({
        status: 'success',
        message: 'Bherung POS API aktif & terhubung!',
        spreadsheetId: ss.getId(),
        spreadsheetName: ss.getName(),
        timestamp: new Date().toISOString()
      });
    }

    // 1. GET Produk
    if (action === 'getProducts') {
      const sheet = getOrCreateSheet(ss, 'Produk');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const products = rows.map(r => ({
        id: String(r[0]),
        name: String(r[1]),
        code: String(r[2]),
        categoryId: String(r[3]),
        price: Number(r[4]) || 0,
        wholesalePrice: r[5] ? Number(r[5]) : null,
        wholesaleMinQty: r[6] ? Number(r[6]) : null,
        unit: String(r[7] || 'pcs'),
        stock: Number(r[8]) || 0,
        description: String(r[9] || '')
      }));

      return jsonResponse({ status: 'success', products: products, data: products });
    }

    // 2. GET Kasbon
    if (action === 'getKasbon') {
      const sheet = getOrCreateSheet(ss, 'Buku_Kasbon');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const kasbonList = rows.map(r => ({
        id: String(r[0]),
        customerName: String(r[1]),
        customerPhone: String(r[2] || ''),
        amount: Number(r[3]) || 0,
        createdAt: r[4] instanceof Date ? r[4].toISOString() : String(r[4]),
        dueDate: r[5] instanceof Date ? r[5].toISOString() : String(r[5]),
        isPaid: String(r[6]).toUpperCase() === 'LUNAS',
        detailItems: String(r[7] || '')
      }));

      return jsonResponse({ status: 'success', data: kasbonList });
    }

    // 3. GET Pengguna Kasir
    if (action === 'getUsers') {
      const sheet = getOrCreateSheet(ss, 'Pengguna_Kasir');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const users = rows.map(r => ({
        id: String(r[0]),
        name: String(r[1]),
        phone: String(r[2] || ''),
        role: String(r[3]).toLowerCase() === 'owner' ? 'owner' : 'staff',
        pin: String(r[4] || '1234'),
        isActive: String(r[5]).toLowerCase() !== 'false'
      }));

      return jsonResponse({ status: 'success', users: users, data: users });
    }

    // 4. GET Rekap Shift
    if (action === 'getShifts') {
      const sheet = getOrCreateSheet(ss, 'Shift_Rekap');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const shifts = rows.map(r => ({
        id: String(r[0]),
        cashierName: String(r[1]),
        shiftName: String(r[2] || 'Shift Operan'),
        startTime: r[3] instanceof Date ? r[3].toISOString() : String(r[3]),
        endTime: r[4] instanceof Date ? r[4].toISOString() : String(r[4]),
        startingCashDrawer: Number(r[5]) || 0,
        totalSystemSales: Number(r[6]) || 0,
        physicalCashCounted: Number(r[7]) || 0,
        cashDifference: Number(r[8]) || 0,
        handoverNotes: String(r[9] || ''),
        nextCashierName: String(r[10] || '')
      }));

      return jsonResponse({ status: 'success', shifts: shifts, data: shifts });
    }

    // 5. GET Mutasi Stok
    if (action === 'getMutations') {
      const sheet = getOrCreateSheet(ss, 'Mutasi_Stok');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const mutations = rows.map(r => ({
        id: String(r[0]),
        productId: String(r[1]),
        productName: String(r[2]),
        type: String(r[3]),
        qtyChange: Number(r[4]) || 0,
        previousStock: Number(r[5]) || 0,
        newStock: Number(r[6]) || 0,
        timestamp: r[7] instanceof Date ? r[7].toISOString() : String(r[7]),
        note: String(r[8] || ''),
        cashierName: String(r[9] || '')
      }));

      return jsonResponse({ status: 'success', mutations: mutations, data: mutations });
    }

    // 6. GET Profil Toko
    if (action === 'getStoreProfile') {
      const sheet = getOrCreateSheet(ss, 'Profil_Toko');
      const data = sheet.getDataRange().getValues();
      if (data.length > 1) {
        const r = data[1];
        let bankAccounts = [];
        try {
          bankAccounts = JSON.parse(r[5] || '[]');
        } catch (_) {}

        return jsonResponse({
          status: 'success',
          profile: {
            name: String(r[0] || 'Bherung'),
            tagline: String(r[1] || '24 JAM'),
            defaultStartingCash: Number(r[2]) || 200000,
            qrisName: String(r[3] || ''),
            qrisNmid: String(r[4] || ''),
            bankAccounts: bankAccounts
          }
        });
      }
      return jsonResponse({ status: 'success', profile: null });
    }

    // 7. GET Transaksi Hari Ini & Riwayat Penjualan
    if (action === 'getTransactions') {
      const sheet = getOrCreateSheet(ss, 'Transaksi');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);
      const todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd');

      let todaySales = 0;
      let todayTrxCount = 0;

      const transactions = rows.slice(-100).reverse().map(r => {
        const rowDate = r[1] instanceof Date ? Utilities.formatDate(r[1], Session.getScriptTimeZone(), 'yyyy-MM-dd') : String(r[1]);
        const totalAmount = Number(r[7]) || 0;
        if (rowDate === todayStr) {
          todaySales += totalAmount;
          todayTrxCount++;
        }

        return {
          id: String(r[0]),
          date: rowDate,
          time: String(r[2]),
          transactionType: String(r[3]),
          customerName: String(r[4]),
          subtotal: Number(r[5]) || 0,
          discountAmount: Number(r[6]) || 0,
          totalAmount: totalAmount,
          paymentMethod: String(r[8]),
          cashierName: String(r[9]),
          itemsSummary: String(r[10] || '')
        };
      });

      return jsonResponse({
        status: 'success',
        todaySales: todaySales,
        todayTrxCount: todayTrxCount,
        transactions: transactions
      });
    }

    return jsonResponse({ status: 'error', message: 'Action GET tidak dikenali: ' + action }, 400);

  } catch (err) {
    return jsonResponse({ status: 'error', message: err.toString() }, 500);
  }
}

function doPost(e) {
  try {
    let body = {};
    if (e && e.postData && e.postData.contents) {
      try {
        body = JSON.parse(e.postData.contents);
      } catch (jsonErr) {
        body = {};
      }
    }

    const ss = getTargetSpreadsheet(e, body);
    const action = body.action || (e && e.parameter && e.parameter.action);

    // 1. Simpan Transaksi Penjualan
    if (action === 'addTransaction') {
      const trx = body.data;
      const sheetTrx = getOrCreateSheet(ss, 'Transaksi');
      const dateNow = new Date();

      const itemsSummary = (trx.items || []).map(i => `${i.name} (${i.qty} ${i.unit || 'pcs'} @ ${i.unitPrice})`).join('; ');

      sheetTrx.appendRow([
        trx.id || ('TRX-' + dateNow.getTime()),
        Utilities.formatDate(dateNow, Session.getScriptTimeZone(), 'yyyy-MM-dd'),
        Utilities.formatDate(dateNow, Session.getScriptTimeZone(), 'HH:mm:ss'),
        trx.transactionType || 'Eceran',
        trx.customerName || 'Umum',
        Number(trx.subtotal) || 0,
        Number(trx.discountAmount) || 0,
        Number(trx.totalAmount) || 0,
        trx.paymentMethod || 'Tunai',
        trx.cashierName || 'Kasir',
        itemsSummary
      ]);

      updateStockFromTransaction(ss, trx.items || []);

      return jsonResponse({
        status: 'success',
        message: 'Transaksi berhasil disimpan ke Spreadsheet!',
        transactionId: trx.id,
        spreadsheetName: ss.getName()
      });
    }

    // 2. Catat Kasbon Baru
    if (action === 'addKasbon') {
      const kasbon = body.data;
      const sheetKasbon = getOrCreateSheet(ss, 'Buku_Kasbon');
      const dateNow = new Date();

      const itemsSummary = (kasbon.items || []).map(i => `${i.name} (${i.qty} ${i.unit || 'pcs'})`).join('; ');

      sheetKasbon.appendRow([
        kasbon.id || ('KSB-' + dateNow.getTime()),
        kasbon.customerName || 'Pelanggan Kasbon',
        kasbon.customerPhone || '',
        Number(kasbon.amount) || 0,
        Utilities.formatDate(dateNow, Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm'),
        kasbon.dueDate ? String(kasbon.dueDate).substring(0, 10) : '-',
        'BELUM LUNAS',
        itemsSummary
      ]);

      updateStockFromTransaction(ss, kasbon.items || []);

      return jsonResponse({
        status: 'success',
        message: 'Kasbon pelanggan berhasil dicatat!',
        kasbonId: kasbon.id
      });
    }

    // 3. Pelunasan Kasbon
    if (action === 'payKasbon') {
      const kasbonId = body.kasbonId;
      const sheetKasbon = getOrCreateSheet(ss, 'Buku_Kasbon');
      const data = sheetKasbon.getDataRange().getValues();

      let foundRow = -1;
      for (let r = 1; r < data.length; r++) {
        if (String(data[r][0]) === String(kasbonId)) {
          foundRow = r + 1;
          break;
        }
      }

      if (foundRow !== -1) {
        sheetKasbon.getRange(foundRow, 7).setValue('LUNAS');
        return jsonResponse({
          status: 'success',
          message: 'Status kasbon berhasil diubah menjadi LUNAS!'
        });
      } else {
        return jsonResponse({ status: 'error', message: 'Kasbon ID tidak ditemukan: ' + kasbonId }, 404);
      }
    }

    // 4. Batch Sync Produk ke Spreadsheet (Batch Cepat)
    if (action === 'syncProducts') {
      const products = body.products || [];
      const sheetProd = getOrCreateSheet(ss, 'Produk', true);

      if (products.length > 0) {
        const rows = products.map(p => [
          p.id,
          p.name,
          p.code || '',
          p.categoryId,
          p.price,
          p.wholesalePrice || '',
          p.wholesaleMinQty || '',
          p.unit || 'pcs',
          p.stock || 0,
          p.description || ''
        ]);

        sheetProd.getRange(2, 1, rows.length, 10).setValues(rows);
      }

      return jsonResponse({
        status: 'success',
        message: `Berhasil menyinkronkan ${products.length} produk ke Spreadsheet!`
      });
    }

    // 5. Batch Sync Pengguna / Kasir ke Spreadsheet
    if (action === 'syncUsers') {
      const users = body.users || [];
      const sheetUsers = getOrCreateSheet(ss, 'Pengguna_Kasir', true);

      users.forEach(u => {
        sheetUsers.appendRow([
          u.id,
          u.name,
          u.phone || '',
          u.role || 'staff',
          u.pin || '1234',
          u.isActive !== false ? 'AKTIF' : 'NONAKTIF'
        ]);
      });

      return jsonResponse({
        status: 'success',
        message: `Berhasil menyinkronkan ${users.length} akun penjaga toko ke Spreadsheet!`
      });
    }

    // 6. Simpan Rekap Shift ke Spreadsheet
    if (action === 'addShift') {
      const shift = body.data;
      const sheetShifts = getOrCreateSheet(ss, 'Shift_Rekap');

      sheetShifts.appendRow([
        shift.id || ('SHIFT-' + new Date().getTime()),
        shift.cashierName || 'Kasir',
        shift.shiftName || 'Shift Operan',
        shift.startTime || new Date().toISOString(),
        shift.endTime || new Date().toISOString(),
        Number(shift.startingCashDrawer) || 0,
        Number(shift.totalSystemSales) || 0,
        Number(shift.physicalCashCounted) || 0,
        Number(shift.cashDifference) || 0,
        shift.handoverNotes || '',
        shift.nextCashierName || ''
      ]);

      return jsonResponse({
        status: 'success',
        message: 'Rekap shift berhasil dicatat ke Spreadsheet!'
      });
    }

    // 7. Simpan Mutasi Stok ke Spreadsheet
    if (action === 'addMutation') {
      const mut = body.data;
      const sheetMut = getOrCreateSheet(ss, 'Mutasi_Stok');

      sheetMut.appendRow([
        mut.id || ('MUT-' + new Date().getTime()),
        mut.productId || '',
        mut.productName || '',
        mut.type || 'adjustment',
        Number(mut.qtyChange) || 0,
        Number(mut.previousStock) || 0,
        Number(mut.newStock) || 0,
        mut.timestamp || new Date().toISOString(),
        mut.note || '',
        mut.cashierName || ''
      ]);

      return jsonResponse({
        status: 'success',
        message: 'Mutasi stok berhasil dicatat ke Spreadsheet!'
      });
    }

    // 8. Sync Profil Toko ke Spreadsheet
    if (action === 'syncStoreProfile') {
      const profile = body.profile || {};
      const sheetProfile = getOrCreateSheet(ss, 'Profil_Toko', true);

      sheetProfile.appendRow([
        profile.name || 'Bherung',
        profile.tagline || '24 JAM',
        Number(profile.defaultStartingCash) || 200000,
        profile.qrisName || '',
        profile.qrisNmid || '',
        JSON.stringify(profile.bankAccounts || [])
      ]);

      return jsonResponse({
        status: 'success',
        message: 'Profil toko berhasil disinkronkan ke Spreadsheet!'
      });
    }

    return jsonResponse({ status: 'error', message: 'Action POST tidak dikenali: ' + action }, 400);

  } catch (err) {
    return jsonResponse({ status: 'error', message: err.toString() }, 500);
  }
}

function getOrCreateSheet(ss, sheetName, clearIfExists = false) {
  let sheet = ss.getSheetByName(sheetName);
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  } else if (clearIfExists) {
    sheet.clear();
  }

  if (sheet.getLastRow() === 0) {
    if (sheetName === 'Produk') {
      sheet.appendRow(['ID', 'Nama_Produk', 'Barcode_SKU', 'Kategori', 'Harga_Eceran', 'Harga_Grosir', 'Min_Qty_Grosir', 'Satuan', 'Stok', 'Keterangan']);
      sheet.getRange('A1:J1').setBackground('#0D9488').setFontColor('#FFFFFF').setFontWeight('bold');
    } else if (sheetName === 'Transaksi') {
      sheet.appendRow(['ID_Nota', 'Tanggal', 'Jam', 'Tipe_Transaksi', 'Nama_Pelanggan', 'Subtotal', 'Diskon', 'Total_Bayar', 'Metode_Bayar', 'Nama_Kasir', 'Detail_Barang']);
      sheet.getRange('A1:K1').setBackground('#0F172A').setFontColor('#FFFFFF').setFontWeight('bold');
    } else if (sheetName === 'Buku_Kasbon') {
      sheet.appendRow(['ID_Kasbon', 'Nama_Pelanggan', 'No_HP', 'Total_Utang', 'Tanggal_Catat', 'Jatuh_Tempo', 'Status', 'Detail_Barang']);
      sheet.getRange('A1:H1').setBackground('#D97706').setFontColor('#FFFFFF').setFontWeight('bold');
    } else if (sheetName === 'Pengguna_Kasir') {
      sheet.appendRow(['ID_User', 'Nama_Kasir', 'No_HP', 'Peran_Role', 'PIN_Akses', 'Status_Aktif']);
      sheet.getRange('A1:F1').setBackground('#F59E0B').setFontColor('#0F172A').setFontWeight('bold');
      
      // Default Akun Kasir & Owner Toko di Google Spreadsheet
      sheet.appendRow(['usr-owner', 'Pemilik Toko (Owner)', '0812-9988-7766', 'owner', '1234', 'AKTIF']);
      sheet.appendRow(['usr-01', 'Ahmad (Kasir)', '0857-1122-3344', 'staff', '1111', 'AKTIF']);
      sheet.appendRow(['usr-02', 'Hasan (Shift Malam)', '0878-5566-7788', 'staff', '2222', 'AKTIF']);
    } else if (sheetName === 'Shift_Rekap') {
      sheet.appendRow(['ID_Shift', 'Nama_Kasir', 'Nama_Shift', 'Waktu_Mulai', 'Waktu_Selesai', 'Kas_Awal', 'Total_Penjualan', 'Kas_Fisik', 'Selisih', 'Catatan', 'Kasir_Penerima']);
      sheet.getRange('A1:K1').setBackground('#1E293B').setFontColor('#38BDF8').setFontWeight('bold');
    } else if (sheetName === 'Mutasi_Stok') {
      sheet.appendRow(['ID_Mutasi', 'ID_Produk', 'Nama_Produk', 'Tipe_Mutasi', 'Jumlah', 'Stok_Awal', 'Stok_Akhir', 'Waktu', 'Keterangan', 'Nama_Kasir']);
      sheet.getRange('A1:J1').setBackground('#334155').setFontColor('#FDE047').setFontWeight('bold');
    } else if (sheetName === 'Profil_Toko') {
      sheet.appendRow(['Nama_Toko', 'Tagline', 'Modal_Kas_Awal', 'QRIS_Merchant', 'QRIS_NMID', 'Rekening_Bank_JSON']);
      sheet.getRange('A1:F1').setBackground('#047857').setFontColor('#FFFFFF').setFontWeight('bold');
    }
  }

  return sheet;
}

function updateStockFromTransaction(ss, items) {
  try {
    const sheetProd = ss.getSheetByName('Produk');
    if (!sheetProd || sheetProd.getLastRow() <= 1) return;

    const data = sheetProd.getDataRange().getValues();
    items.forEach(item => {
      for (let r = 1; r < data.length; r++) {
        if (String(data[r][0]) === String(item.id) || String(data[r][2]) === String(item.code)) {
          const currentStock = Number(data[r][8]) || 0;
          const newStock = Math.max(0, currentStock - (Number(item.qty) || 1));
          sheetProd.getRange(r + 1, 9).setValue(newStock);
          break;
        }
      }
    });
  } catch (e) {
    Logger.log('Error updating stock: ' + e);
  }
}

function initDatabaseSpreadsheet() {
  const ss = SpreadsheetApp.create('BHERUNG POS - Database Toko');
  formatDatabaseSheets();
  return ss;
}

function jsonResponse(data, statusCode = 200) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
