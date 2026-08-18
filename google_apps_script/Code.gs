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
    .addItem('🔄 2. Rapikan Format Seluruh Tabel', 'formatDatabaseSheets')
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

  // 1. Otomatis kunci General Access: Siapa saja yang memiliki link -> EDITOR
  try {
    const file = DriveApp.getFileById(ss.getId());
    file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.EDIT);
  } catch (e) {
    Logger.log('Auto set sharing Anyone with link Editor notice: ' + e);
  }

  // 2. Otomatis berikan izin akses Editor ke Service Account Backend Bherung POS
  try {
    ss.addEditor('bherung-pos@app-script-505503.iam.gserviceaccount.com');
  } catch (e) {
    Logger.log('Auto add service account editor notice: ' + e);
  }

  const id = ss.getId();

  SpreadsheetApp.getUi().alert(
    '✅ OTORISASI BERHASIL!\n\n' +
    'Database Toko Bherung POS Anda sudah aktif & siap digunakan.\n\n' +
    'ID Spreadsheet Anda:\n' + id + '\n\n' +
    '👉 Silakan salin ID di atas dan tempelkan ke menu Pengaturan di Aplikasi Kasir Bherung POS!'
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

    // 4. GET Rekap Laporan Jaga
    if (action === 'getShifts') {
      const sheet = getOrCreateSheet(ss, 'Shift_Rekap');
      const data = sheet.getDataRange().getValues();
      const rows = data.slice(1);

      const shifts = rows.map(r => ({
        id: String(r[0]),
        cashierName: String(r[1]),
        shiftName: String(r[2] || 'Laporan Jaga'),
        startTime: r[3] instanceof Date ? r[3].toISOString() : String(r[3]),
        endTime: r[4] instanceof Date ? r[4].toISOString() : String(r[4]),
        startingCashDrawer: 0,
        totalSystemSales: Number(r[5]) || 0,
        physicalCashCounted: 0,
        cashDifference: 0,
        handoverNotes: String(r[7] || ''),
        nextCashierName: String(r[8] || '')
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

    const action = body.action || (e && e.parameter && e.parameter.action);

    // Delegasikan action pembacaan (GET actions) ke doGet untuk kompatibilitas Web & Android
    const readActions = ['ping', 'getProducts', 'getKasbon', 'getUsers', 'getShifts', 'getMutations', 'getStoreProfile', 'getTransactions'];
    if (readActions.includes(action)) {
      if (!e) e = {};
      e.parameter = Object.assign({}, e.parameter || {}, body);
      return doGet(e);
    }

    const ss = getTargetSpreadsheet(e, body);

    // 1. Simpan Transaksi Penjualan
    if (action === 'addTransaction') {
      const trx = body.data;
      const sheetTrx = getOrCreateSheet(ss, 'Transaksi');
      const dateNow = new Date();

      let itemsSummary = (trx.items || []).map(i => `${i.name} (${i.qty} ${i.unit || 'pcs'} @ ${i.unitPrice})`).join('; ');
      if (Number(trx.deliveryFee) > 0) {
        itemsSummary += ` [Ongkir: Rp ${trx.deliveryFee}]`;
      }

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

    // 6. Simpan Rekap Laporan Jaga ke Spreadsheet
    if (action === 'addShift') {
      const shift = body.data;
      const sheetShifts = getOrCreateSheet(ss, 'Shift_Rekap');
      const dateNow = new Date();

      // Ringkasan audit stok (Stok Lama -> Sistem -> Fisik Riil)
      const stockAuditSummary = (shift.stockAudits || []).map(a =>
        `${a.productName} (Lama: ${a.initialStock != null ? a.initialStock : a.systemStock}, Sistem: ${a.systemStock}, Fisik: ${a.physicalStock}${a.difference !== 0 ? ', Selisih: ' + (a.difference > 0 ? '+' : '') + a.difference : ''})`
      ).join('; ');

      sheetShifts.appendRow([
        shift.id || ('LAPORAN-' + dateNow.getTime()),
        shift.cashierName || 'Penjaga',
        Utilities.formatDate(dateNow, Session.getScriptTimeZone(), 'yyyy-MM-dd'),
        Utilities.formatDate(dateNow, Session.getScriptTimeZone(), 'HH:mm:ss'),
        Number(shift.totalSystemSales) || 0,
        Number(shift.currentShiftTransactions) || 0,
        stockAuditSummary,
        shift.handoverNotes || '',
        shift.nextCashierName || shift.cashierName || 'Penjaga Tetap'
      ]);

      return jsonResponse({
        status: 'success',
        message: 'Laporan serah terima jaga berhasil dikirim ke Spreadsheet!'
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

      // Isi 17 Produk Sembako & Rokok Madura Standar Awal
      const defaultProducts = [
        ['prd-01', 'Beras Ramos Setra Pulen 5kg', '8999999195001', 'Sembako', 72000, 68000, 5, 'sak', 30, 'Beras Ramos Super'],
        ['prd-02', 'Minyak Goreng Bimoli Spesial 2L', '8998866102002', 'Sembako', 38500, 37000, 6, 'pouch', 45, 'Minyak Goreng Sawit'],
        ['prd-03', 'Gula Pasir Gulaku Tebu Murni 1kg', '8991002103003', 'Sembako', 18000, 17200, 10, 'bks', 50, 'Gula Pasir Tebu'],
        ['prd-04', 'Tepung Terigu Segitiga Biru 1kg', '8998866200011', 'Sembako', 13500, 12500, 10, 'bks', 40, 'Tepung Protein Sedang'],
        ['prd-05', 'Telur Ayam Ras Fresh Negeri (1kg)', '8998866200022', 'Sembako', 29000, 27500, 10, 'kg', 25, 'Telur Negeri Segar'],
        ['prd-06', 'Indomie Goreng Original 85g', '8998866300033', 'Mie & Instan', 3500, 3200, 40, 'bks', 120, '1 Dus isi 40 bks'],
        ['prd-07', 'Indomie Kuah Ayam Bawang 75g', '8998866300044', 'Mie & Instan', 3500, 3200, 40, 'bks', 80, '1 Dus isi 40 bks'],
        ['prd-08', 'Kopi Kapal Api Spesial Mix 10s', '8998866400055', 'Minuman', 15000, 14000, 10, 'renceng', 35, 'Kopi Bubuk Gula'],
        ['prd-09', 'Susu Kental Manis Frisian Flag 370g', '8998866400066', 'Minuman', 12500, 11800, 12, 'kaleng', 30, 'Susu Bendera'],
        ['prd-10', 'Teh Pucuk Harum Melati 350ml', '8998866400077', 'Minuman', 4000, 3500, 24, 'botol', 60, '1 Dus isi 24 botol'],
        ['prd-11', 'Le Minerale Air Mineral 600ml', '8998866400088', 'Minuman', 3500, 3000, 24, 'botol', 72, '1 Dus isi 24 botol'],
        ['prd-12', 'Rokok Sampoerna A Mild 16', '8998866500099', 'Rokok', 36000, 34500, 10, 'bks', 50, '1 Slop isi 10 bks'],
        ['prd-13', 'Rokok Djarum Super 12', '8998866500100', 'Rokok', 25000, 24000, 10, 'bks', 40, '1 Slop isi 10 bks'],
        ['prd-14', 'Rokok Gudang Garam Surya 16', '8998866500111', 'Rokok', 34500, 33000, 10, 'bks', 45, '1 Slop isi 10 bks'],
        ['prd-15', 'Sabun Cuci Piring Sunlight Jeruk Nipis 750ml', '8998866600122', 'Kebutuhan Rumah', 16000, 15000, 6, 'pouch', 25, 'Sunlight Jeruk Nipis'],
        ['prd-16', 'Deterjen Bubuk Rinso Anti Noda 770g', '8998866600133', 'Kebutuhan Rumah', 22000, 20500, 6, 'bks', 20, 'Deterjen Rinso'],
        ['prd-17', 'Gas Elpiji Melon 3kg (Refill)', '8998866700144', 'Gas & Galon', 22000, 21000, 5, 'tabung', 15, 'Tabung Gas 3kg'],
      ];

      defaultProducts.forEach(p => sheet.appendRow(p));
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
      sheet.appendRow(['ID_Serah_Terima', 'Penjaga_Lama', 'Tanggal', 'Jam', 'Total_Omzet', 'Jumlah_Transaksi', 'Cekan_Stok_Lama_vs_Fisik', 'Catatan', 'Penjaga_Penerima']);
      sheet.getRange('A1:I1').setBackground('#1E293B').setFontColor('#38BDF8').setFontWeight('bold');
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
