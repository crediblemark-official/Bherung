import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class GoogleSheetsDirectService {
  static final GoogleSheetsDirectService _instance = GoogleSheetsDirectService._internal();
  factory GoogleSheetsDirectService() => _instance;
  GoogleSheetsDirectService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '576140887919-b7i4e44ih2depjr8kddkmufobmndjik3.apps.googleusercontent.com',
    scopes: <String>[
      'email',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/spreadsheets',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String? _spreadsheetId;
  String? _spreadsheetName;
  bool _isInitialized = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;
  String? get spreadsheetId => _spreadsheetId;
  String? get spreadsheetName => _spreadsheetName;
  String get userEmail => _currentUser?.email ?? '';
  String get userDisplayName => _currentUser?.displayName ?? 'Pengguna Google';
  String? get userPhotoUrl => _currentUser?.photoUrl;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _spreadsheetId = prefs.getString('bherung_gcp_spreadsheet_id');
      _spreadsheetName = prefs.getString('bherung_gcp_spreadsheet_name') ?? 'Bherung POS - Database Toko';

      // Coba silent sign-in otomatis jika user pernah login sebelumnya
      _currentUser = await _googleSignIn.signInSilently();
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('GoogleSheetsDirectService init error: $e');
      }
    }
  }

  /// 1. Login dengan Akun Google
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      // Inisialisasi atau cari spreadsheet toko di Google Drive user
      await getOrCreateStoreSpreadsheet();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      return false;
    }
  }

  /// 2. Logout dari Akun Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _spreadsheetId = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bherung_gcp_spreadsheet_id');
      await prefs.remove('bherung_gcp_spreadsheet_name');
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-Out Error: $e');
      }
    }
  }

  /// 3. Dapatkan Headers Autentikasi OAuth Bearer Token
  Future<Map<String, String>?> _getAuthHeaders() async {
    if (_currentUser == null) return null;
    return await _currentUser!.authHeaders;
  }

  /// 4. Cari atau Buat Otomatis File Spreadsheet "Bherung POS - Database Toko" di Google Drive User
  Future<String?> getOrCreateStoreSpreadsheet() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return null;

    final prefs = await SharedPreferences.getInstance();

    // A. Cek apakah sudah ada spreadsheet ID tersimpan di memori lokal
    if (_spreadsheetId != null && _spreadsheetId!.isNotEmpty) {
      return _spreadsheetId;
    }

    try {
      debugPrint('Mencari spreadsheet di Google Drive user...');
      // B. Cari di Google Drive apakah file sudah ada
      final searchUrl = Uri.parse(
        "https://www.googleapis.com/drive/v3/files?q=name='Bherung POS - Database Toko' and trashed=false&fields=files(id,name)",
      );

      final searchRes = await http.get(searchUrl, headers: headers);
      debugPrint('Search Google Drive response: ${searchRes.statusCode} - ${searchRes.body}');
      if (searchRes.statusCode == 200) {
        final data = jsonDecode(searchRes.body);
        final List files = data['files'] ?? [];
        if (files.isNotEmpty) {
          _spreadsheetId = files.first['id'];
          _spreadsheetName = files.first['name'];
          await prefs.setString('bherung_gcp_spreadsheet_id', _spreadsheetId!);
          await prefs.setString('bherung_gcp_spreadsheet_name', _spreadsheetName!);
          debugPrint('Ditemukan spreadsheet yang sudah ada: $_spreadsheetId');
          return _spreadsheetId;
        }
      }

      debugPrint('Membuat file Spreadsheet baru di Google Drive user...');
      // C. Jika belum ada, buat Spreadsheet baru lengkap dengan 7 Sheet Tab
      final createUrl = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets');
      final createBody = {
        'properties': {'title': 'Bherung POS - Database Toko'},
        'sheets': [
          {'properties': {'title': 'Produk'}},
          {'properties': {'title': 'Transaksi'}},
          {'properties': {'title': 'Buku_Kasbon'}},
          {'properties': {'title': 'Pengguna_Kasir'}},
          {'properties': {'title': 'Shift_Rekap'}},
          {'properties': {'title': 'Mutasi_Stok'}},
          {'properties': {'title': 'Profil_Toko'}},
        ],
      };

      final createRes = await http.post(
        createUrl,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(createBody),
      );

      debugPrint('Create Spreadsheet response: ${createRes.statusCode} - ${createRes.body}');

      if (createRes.statusCode == 200) {
        final createData = jsonDecode(createRes.body);
        _spreadsheetId = createData['spreadsheetId'];
        _spreadsheetName = 'Bherung POS - Database Toko';

        await prefs.setString('bherung_gcp_spreadsheet_id', _spreadsheetId!);
        await prefs.setString('bherung_gcp_spreadsheet_name', _spreadsheetName!);

        // Tulis header tabel awal
        await _initializeSheetHeaders(_spreadsheetId!, headers);
        debugPrint('Spreadsheet baru berhasil dibuat dengan ID: $_spreadsheetId');
        return _spreadsheetId;
      }
    } catch (e) {
      debugPrint('Error getOrCreateStoreSpreadsheet: $e');
    }

    return null;
  }

  /// 5. Isi Header Kolom Default & Data Awal untuk 7 Tab Spreadsheet Baru
  Future<void> _initializeSheetHeaders(String ssId, Map<String, String> headers) async {
    final batchUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values:batchUpdate',
    );

    final batchData = {
      'valueInputOption': 'USER_ENTERED',
      'data': [
        {
          'range': 'Produk!A1:H18',
          'values': [
            ['ID', 'Barcode', 'Nama_Produk', 'Harga_Jual', 'Harga_Modal', 'Satuan', 'Kategori', 'Stok'],
            ['prd-01', '8999999195001', 'Beras Ramos Setra Pulen 5kg', 72000, 65000, 'sak', 'Sembako', 30],
            ['prd-02', '8998866102002', 'Minyak Goreng Bimoli Spesial 2L', 38500, 34000, 'pouch', 'Sembako', 45],
            ['prd-03', '8991002103003', 'Gula Pasir Gulaku Tebu Murni 1kg', 18000, 15500, 'bks', 'Sembako', 50],
            ['prd-04', '8998866200011', 'Tepung Terigu Segitiga Biru 1kg', 13500, 11000, 'bks', 'Sembako', 40],
            ['prd-05', '8998866200022', 'Telur Ayam Ras Fresh Negeri (1kg)', 29000, 26000, 'kg', 'Sembako', 25],
            ['prd-06', '8998866300033', 'Indomie Goreng Original 85g', 3500, 2900, 'bks', 'Mie & Instan', 120],
            ['prd-07', '8998866300044', 'Indomie Kuah Ayam Bawang 75g', 3500, 2900, 'bks', 'Mie & Instan', 80],
            ['prd-08', '8998866400055', 'Kopi Kapal Api Spesial Mix 10s', 15000, 12500, 'renceng', 'Minuman', 35],
            ['prd-09', '8998866400066', 'Susu Kental Manis Frisian Flag 370g', 12500, 10500, 'kaleng', 'Minuman', 30],
            ['prd-10', '8998866400077', 'Teh Pucuk Harum Melati 350ml', 4000, 3000, 'botol', 'Minuman', 60],
            ['prd-11', '8998866400088', 'Le Minerale Air Mineral 600ml', 3500, 2400, 'botol', 'Minuman', 72],
            ['prd-12', '8998866500099', 'Rokok Sampoerna A Mild 16', 36000, 33500, 'bks', 'Rokok', 50],
            ['prd-13', '8998866500100', 'Rokok Djarum Super 12', 25000, 22800, 'bks', 'Rokok', 40],
            ['prd-14', '8998866500111', 'Rokok Gudang Garam Surya 16', 34500, 32000, 'bks', 'Rokok', 45],
            ['prd-15', '8998866600122', 'Sabun Cuci Piring Sunlight Jeruk Nipis 750ml', 16000, 13500, 'pouch', 'Kebutuhan Rumah', 25],
            ['prd-16', '8998866600133', 'Deterjen Bubuk Rinso Anti Noda 770g', 22000, 18500, 'bks', 'Kebutuhan Rumah', 20],
            ['prd-17', '8998866700144', 'Gas Elpiji Melon 3kg (Refill)', 22000, 19000, 'tabung', 'Gas & Galon', 15],
          ]
        },
        {
          'range': 'Transaksi!A1:L1',
          'values': [
            ['ID_Nota', 'Tanggal', 'Jam', 'Tipe_Transaksi', 'Nama_Pelanggan', 'Subtotal', 'Diskon', 'Total_Bayar', 'Metode_Bayar', 'Nama_Kasir', 'Detail_Barang', 'Status']
          ]
        },
        {
          'range': 'Buku_Kasbon!A1:H1',
          'values': [
            ['ID_Kasbon', 'Nama_Pelanggan', 'No_HP', 'Total_Utang', 'Sisa_Utang', 'Status_Lunas', 'Tgl_Catat', 'Jatuh_Tempo']
          ]
        },
        {
          'range': 'Pengguna_Kasir!A1:E3',
          'values': [
            ['ID_User', 'Nama_Kasir', 'Role', 'PIN', 'Status_Aktif'],
            ['usr-owner', 'Pemilik Toko (Owner)', 'owner', '1234', 'Aktif'],
            ['usr-staff', 'Penjaga Toko (Kasir)', 'staff', '5678', 'Aktif'],
          ]
        },
        {
          'range': 'Shift_Rekap!A1:G1',
          'values': [
            ['ID_Shift', 'Nama_Kasir', 'Waktu_Buka', 'Waktu_Tutup', 'Modal_Awal', 'Total_Uang_Kas', 'Status']
          ]
        },
        {
          'range': 'Mutasi_Stok!A1:G1',
          'values': [
            ['ID_Mutasi', 'ID_Produk', 'Nama_Produk', 'Tipe_Mutasi', 'Jumlah', 'Tgl_Waktu', 'Keterangan']
          ]
        },
        {
          'range': 'Profil_Toko!A1:E1',
          'values': [
            ['Nama_Toko', 'Tagline', 'Alamat', 'No_HP', 'Kas_Awal_Default']
          ]
        },
      ]
    };

    try {
      await http.post(
        batchUrl,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode(batchData),
      );
    } catch (_) {}
  }

  /// 6. Simpan Transaksi Baru Langsung ke Tab "Transaksi" di Google Sheets
  Future<bool> appendTransaction({
    required String invoiceId,
    required String customerName,
    required String transactionType,
    required double subtotal,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
    required String cashierName,
    required String itemsSummary,
  }) async {
    final headers = await _getAuthHeaders();
    final ssId = _spreadsheetId;
    if (headers == null || ssId == null) return false;

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final appendUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values/Transaksi!A1:append?valueInputOption=USER_ENTERED',
    );

    final row = [
      invoiceId,
      dateStr,
      timeStr,
      transactionType,
      customerName.isEmpty ? 'Umum' : customerName,
      subtotal,
      discount,
      grandTotal,
      paymentMethod,
      cashierName,
      itemsSummary,
      'Selesai',
    ];

    try {
      final res = await http.post(
        appendUrl,
        headers: {...headers, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'values': [row]
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error appendTransaction: $e');
      }
      return false;
    }
  }

  /// 7. Sync & Muat Seluruh Produk dari Tab "Produk"
  Future<List<Product>?> fetchProducts() async {
    final headers = await _getAuthHeaders();
    final ssId = _spreadsheetId;
    if (headers == null || ssId == null) return null;

    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values/Produk!A2:H?valueRenderOption=UNFORMATTED_VALUE',
    );

    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['values'] ?? [];
        final List<Product> products = [];

        // Jika sheet kosong, isi otomatis dengan produk awal default
        if (rows.isEmpty) {
          await _initializeSheetHeaders(ssId, headers);
          final secondRes = await http.get(url, headers: headers);
          if (secondRes.statusCode == 200) {
            final secondData = jsonDecode(secondRes.body);
            final List secondRows = secondData['values'] ?? [];
            for (final row in secondRows) {
              if (row is List && row.length >= 4) {
                products.add(_parseProductRow(row));
              }
            }
          }
          return products;
        }

        for (final row in rows) {
          if (row is List && row.length >= 4) {
            products.add(_parseProductRow(row));
          }
        }
        return products;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetchProducts: $e');
      }
    }
    return null;
  }

  Product _parseProductRow(List row) {
    final id = row.isNotEmpty ? row[0].toString() : 'prd-${DateTime.now().millisecondsSinceEpoch}';
    final code = row.length > 1 ? row[1].toString() : '';
    final name = row.length > 2 ? row[2].toString() : 'Produk';
    final price = row.length > 3 ? (double.tryParse(row[3].toString()) ?? 0.0) : 0.0;
    final costPrice = row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0;
    final unit = row.length > 5 ? row[5].toString() : 'pcs';
    final category = row.length > 6 ? row[6].toString() : 'Sembako';
    final stock = row.length > 7 ? (int.tryParse(row[7].toString()) ?? 0) : 0;

    return Product(
      id: id,
      name: name,
      price: price,
      costPrice: costPrice,
      unit: unit,
      categoryId: category.toLowerCase().replaceAll(' ', '_'),
      icon: AppTheme.getCategoryIcon(category),
      color: AppTheme.getCategoryColor(category),
      code: code,
      stock: stock,
      minStockAlert: 5,
    );
  }

  /// 8. Sync & Muat Daftar Pengguna Kasir & PIN dari Tab "Pengguna_Kasir"
  Future<List<AppUser>?> fetchUsers() async {
    final headers = await _getAuthHeaders();
    final ssId = _spreadsheetId;
    if (headers == null || ssId == null) return null;

    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values/Pengguna_Kasir!A2:E?valueRenderOption=UNFORMATTED_VALUE',
    );

    try {
      final res = await http.get(url, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['values'] ?? [];
        final List<AppUser> users = [];

        for (final row in rows) {
          if (row is List && row.length >= 4) {
            final id = row[0].toString();
            final name = row[1].toString();
            final roleStr = row[2].toString().toLowerCase();
            final pin = row[3].toString();
            final status = row.length > 4 ? row[4].toString() : 'Aktif';

            final role = (roleStr == 'owner' || roleStr.contains('pemilik'))
                ? UserRoleType.owner
                : UserRoleType.staff;

            users.add(
              AppUser(
                id: id,
                name: name,
                phone: '',
                role: role,
                pin: pin,
                isActive: !status.toLowerCase().contains('nonaktif'),
              ),
            );
          }
        }
        return users;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetchUsers: $e');
      }
    }
    return null;
  }

  /// 9. Update PIN Pengguna di Google Sheets Tab "Pengguna_Kasir"
  Future<bool> updateUserPin(String userId, String newPin) async {
    final headers = await _getAuthHeaders();
    final ssId = _spreadsheetId;
    if (headers == null || ssId == null) return false;

    // Ambil data baris untuk temukan baris userId yang cocok
    final getUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values/Pengguna_Kasir!A2:E',
    );

    try {
      final res = await http.get(getUrl, headers: headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['values'] ?? [];
        int rowIndex = -1;

        for (int i = 0; i < rows.length; i++) {
          if (rows[i] is List && (rows[i] as List).isNotEmpty && rows[i][0].toString() == userId) {
            rowIndex = i + 2; // 1-based index including header
            break;
          }
        }

        if (rowIndex != -1) {
          final updateUrl = Uri.parse(
            'https://sheets.googleapis.com/v4/spreadsheets/$ssId/values/Pengguna_Kasir!D$rowIndex?valueInputOption=USER_ENTERED',
          );
          final updateRes = await http.put(
            updateUrl,
            headers: {...headers, 'Content-Type': 'application/json'},
            body: jsonEncode({
              'values': [
                [newPin]
              ]
            }),
          );
          return updateRes.statusCode == 200;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updateUserPin: $e');
      }
    }
    return false;
  }
}

