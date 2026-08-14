/**
 * =======================================================================
 * BHERUNG POS - GOOGLE APPS SCRIPT BACKEND (TOKO SEMBAKO & MADURA 24 JAM)
 * =======================================================================
 * 
 * Script ini mengelola database Spreadsheet untuk aplikasi POS Bherung:
 * 1. Sheet "Produk"       : Katalog produk sembako, barcode, stok, harga ecer & grosir.
 * 2. Sheet "Transaksi"    : Rekap riwayat transaksi penjualan & detail belanjaan.
 * 3. Sheet "Buku_Kasbon"  : Catatan utang kasbon pelanggan & status jatuh tempo.
 */

// Custom Menu di Bilah Atas Spreadsheet saat dibuka oleh Pemilik Toko
function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu('🏪 Bherung POS')
    .addItem('🔑 1. Otorisasi & Aktifkan Database Kasir', 'authorizeAndGetId')
    .addItem('📦 2. Isi Katalog Sembako Awal (17 Barang)', 'seedDefaultProducts')
    .addItem('🔄 3. Rapikan Format Tabel', 'formatDatabaseSheets')
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
 * Fungsi 2: Mengisi 17 Katalog Sembako Awal
 */
function seedDefaultProducts() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = getOrCreateSheet(ss, 'Produk', true);

  const initialProducts = [
    ['sbk-01', 'Beras Ramos Setra Pulen 5kg', '8991001', 'sembako', 72000, 70000, 5, 'sak', 40, 'Beras putih pulen wangi 5kg'],
    ['sbk-02', 'Beras Pandan Wangi Curah 1kg', '8991002', 'sembako', 15000, 14000, 10, 'kg', 120, 'Beras timbangan ecer'],
    ['sbk-03', 'Minyak Goreng Bimoli 2L Pouch', '8991003', 'sembako', 36000, 34500, 6, 'pouch', 50, 'Minyak sawit jernih 2L'],
    ['sbk-04', 'Minyak Goreng Kita 1L Pouch', '8991004', 'sembako', 16500, 15500, 12, 'pouch', 80, 'Minyakita 1L'],
    ['sbk-05', 'Telur Ayam Negeri Fresh (1 Kg)', '8991005', 'sembako', 28000, 26500, 10, 'kg', 65, 'Telur ayam segar ~16 butir'],
    ['sbk-06', 'Gula Pasir Gulaku Kuning 1kg', '8991006', 'sembako', 17500, 16800, 10, 'kg', 45, 'Gula tebu murni 1kg'],
    ['sbk-07', 'Tepung Terigu Segitiga Biru 1kg', '8991007', 'sembako', 12500, 11800, 10, 'kg', 35, 'Tepung terigu serbaguna'],
    ['mie-01', 'Indomie Goreng Original 85g', '8998866', 'mie_makanan', 3500, 3200, 5, 'bks', 240, 'Mie instan goreng favorit'],
    ['mie-02', 'Indomie Kuah Soto Mie 70g', '8998867', 'mie_makanan', 3500, 3200, 5, 'bks', 180, 'Mie kuah soto mie'],
    ['mie-03', 'Indomie Kuah Ayam Bawang 70g', '8998868', 'mie_makanan', 3500, 3200, 5, 'bks', 150, 'Mie kuah ayam bawang'],
    ['mnm-01', 'Le Minerale Botol Dingin 600ml', '8992770', 'minuman', 3500, 3000, 12, 'botol', 75, 'Air mineral dingin'],
    ['mnm-02', 'Aqua Botol Dingin 600ml', '8992771', 'minuman', 4000, 3500, 12, 'botol', 90, 'Air mineral Aqua 600ml'],
    ['mnm-04', 'Kopi Kapal Api Spesial Mix Renceng', '8992773', 'minuman', 15000, 14000, 5, 'renceng', 40, 'Kopi sachet 10 bungkus'],
    ['rkk-01', 'Gudang Garam Surya 16 Bungkus', '8999901', 'rokok', 36000, 350000, 10, 'bks', 120, 'Rokok GG Surya 16'],
    ['rkk-02', 'Sampoerna A Mild 16 Bungkus', '8999902', 'rokok', 35000, 340000, 10, 'bks', 100, 'Rokok Sampoerna A Mild 16'],
    ['gas-01', 'Isi Ulang Gas LPG 3 Kg (Melon)', '8997001', 'gas_galon', 22000, 21000, 5, 'tabung', 30, 'Isi ulang gas elpiji 3kg'],
    ['gas-02', 'Isi Ulang Galon Aqua 19 Liter Asli', '8997002', 'gas_galon', 20000, 19000, 5, 'galon', 25, 'Tukar galon Aqua 19L segel']
  ];

  initialProducts.forEach(p => sheet.appendRow(p));
  SpreadsheetApp.getUi().alert('✅ 17 Barang Sembako berhasil diisikan ke Sheet Produk!');
}

/**
 * Fungsi 3: Merapikan Format Seluruh Tabel
 */
function formatDatabaseSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  getOrCreateSheet(ss, 'Produk');
  getOrCreateSheet(ss, 'Transaksi');
  getOrCreateSheet(ss, 'Buku_Kasbon');
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

      return jsonResponse({ status: 'success', data: products });
    }

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

    // 4. Batch Sync Produk ke Spreadsheet
    if (action === 'syncProducts') {
      const products = body.products || [];
      const sheetProd = getOrCreateSheet(ss, 'Produk', true);

      products.forEach(p => {
        sheetProd.appendRow([
          p.id,
          p.name,
          p.code,
          p.categoryId,
          p.price,
          p.wholesalePrice || '',
          p.wholesaleMinQty || '',
          p.unit || 'pcs',
          p.stock || 0,
          p.description || ''
        ]);
      });

      return jsonResponse({
        status: 'success',
        message: `Berhasil menyinkronkan ${products.length} produk ke Spreadsheet!`
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
  getOrCreateSheet(ss, 'Produk');
  getOrCreateSheet(ss, 'Transaksi');
  getOrCreateSheet(ss, 'Buku_Kasbon');
  return ss;
}

function jsonResponse(data, statusCode = 200) {
  return ContentService
    .createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
