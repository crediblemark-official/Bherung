import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:googleapis_auth/auth_io.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class ServiceAccountSheetsService {
  static final ServiceAccountSheetsService _instance = ServiceAccountSheetsService._internal();
  factory ServiceAccountSheetsService() => _instance;
  ServiceAccountSheetsService._internal();

  static const String _encodedCredentials =
      'eyJ0eXBlIjogInNlcnZpY2VfYWNjb3VudCIsICJwcm9qZWN0X2lkIjogImFwcC1zY3JpcHQtNTA1NTAzIiwgInByaXZhdGVfa2V5X2lkIjogIjAwZTM2ZmUzOTM2ZGI2Mzc0NDVlYjI5MWM3MTQ0NmI2MTEwNDNhMzAiLCAicHJpdmF0ZV9rZXkiOiAiLS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tXG5NSUlFdmdJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLZ3dnZ1NrQWdFQUFvSUJBUURHUHkxRHF4Y3AzYlpvXG45dkIySC9YcDk3VFhaNmRGOE83UktaT2VodVJXTC8zMEV5MXBGa2VMb0pNUitOT2RpSzhRQjlqeW1zbnJGdzlxXG5lc1NaRGZwMkY2d3ZYSVlFWlBZb3B3c2NJL1EwTi9lbzk4TzFTeEh3Qmw1K0toVXo0VWpWdGtDUlg2REQvcHlXXG5ZZ3FvWnVrU1AxbnZJWVYwS1FDbWhDdjlxK3FybHlxOURZMmdFcWdCK214bWZaelk2RHBBTjZZbk4xQldsMWhKXG5NZFp3ajVSRldyWWxsR3NsZExlUlU0RXlWNHdwMGF0YUY4Ly9XY2RFOGhwRGpVNFNrY0JKY0g3U0JZZmMwZXN1XG5ISXJGbGtYeWEwcS9BRFVxMWRuZDR5V01sZUVRaW0xZVU1V3NvSE5ITHRQZGxaeTFneHRiL2lXaEZJZCtRNEovXG53bHByZU0vYkFnTUJBQUVDZ2dFQUVpY2N6UEp3cDR1K3RUUFBadkdjUWZWRm9PZkQ0RnFrYzVDY0RNc0xRMzBYXG5ndTd5bkluR3VWbFZ2aktMcGdRckM0dThhTktWcEtveTVpd2hybVlpUmdmNjQwZFVtamhvZGVaOTFQRFIzcW8xXG5Ta3FOcUI4Y29GN2s3aWFLVkhyUGdZb3p0VndOUzRVWDc0bEFzcFRoeUtMMmFEZ29rUzlqK050bmI4MzdLZ1QvXG5NZStPNTRvNmtLNmJ5MDR4cFI4bDM2clEvTFVCeXowRGZLRmNUT2ovdi9FcjA0RTdqMUNIcmEwd29LVXpqbGh3XG5pNzBjamhJN3VzREM0aHYxZVdGRWVpL2VKbXNXSFF6QmpPajhHNjlOeWh5K2wyME8wLzloLzgyVlRVYzF5dmxnXG5DNHVCN1BoSGg2S1BYdkt0L2NhaFJUc0lqZEptQ2J0SXpzUzdyY1hhNlFLQmdRRHhDYVFoeVI4MElIZ0gzY1RVXG5lUUdaT0lrMXptMDQrQUExVG45enlQKzZXWkJVZG5UaDRzREl3L0lXNTZrWkpWWlVCeEE0QWJCQ1NSU2lxVHFnXG5PTnZpNHVNUittQ1V5TlVaMzhBTjZPeU1jdHp1WmlRTG1lK0RHMjd4ZmZRN0FzN1ZmVURSNWlISzZwaWdyR0JwXG5Od1JLUlI5azdaNldmL3Jsa3c3V21mc3FIUUtCZ1FEU2pZcG5aaHhiMHlBcmkyanRGMDJjQVFvcjhQVFFsam9GXG54YzR6ellRaVp2TzZnOTBudDZ2cHduY2RycVBjY3RlZVRWN2MxZW1hUllSbzJSL2pyQjVOTVNEQncrenZxTlVUXG5jVkc4bkFRa2cycFRkM1k4NDIvZm1uL3VKT0M5TmIyREczNUtGd2I1N2k0UlYyMjZSMlU0RTFFQkZKazZFRVd3XG5hdk5RaFJ1QVZ3S0JnUURLMmFSSjBxcnlBWWxDaFg2S21iT2dzUlc0Tkp0eTRETzhxTzFXRWdnMVdmNi9ObG16XG5hRk42SW4xd2pWR2dHZTRIRlZLdTc2ellmQXhqd0N2WWYwRitOaGVISDhGOE5YQXlNRDIrOXhGc09aWjVBM2krXG5VclJoRUF0VUxQNEhVNXVoeTZGcmhGTllKQXFDM2M3ZGZUR2RGNE1PTzNQRmtMc2p6WmtsUGIxRWVRS0JnUUZjXG5IcktxUi9OWlBvdEY0M1IxMzJtbUNQcEsralFsN2kwTWtrNFNaZ29uMjFEeXpod2VNQWVJam1Gd2JQMXB5UFVqXG5IMmQrSDkzNzVuYUZzQmlFdllOSTFOcFJiNk9WelU4VHhrTytTcXJyQUg2WWZ1TzMxbXFiRTB0aHQwSUZCS2RHXG5TWlhHUUN3bGU3ZDJaR0dHK0N6SUVrVTdsN1VtaC91VHQ2UXZMYkpSQW9HQkFPT3RzTStpTTRsNDZNWU54ODlUXG5mdWhheS83dFNpcGlTTTlodFcxQUU2Q2Z1d3FhRFVGNjJackYvUGN5K2hsdi9FQjdnTlFYTjVwbnBzL3REOW9vXG5qakoyQjhFbFZQNitxTTJZcTNsTHN3S2hGZmwyU0xscjdRZ2FKWENiQy9WRDZhNlBzY0xlTW11YzhoOXJ3cUl3XG5SMHJaMXVxT2h0WE91bDdBOTFjeFNMNzVcbi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS1cbiIsICJjbGllbnRfZW1haWwiOiAiYmhlcnVuZy1wb3NAYXBwLXNjcmlwdC01MDU1MDMuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCAiY2xpZW50X2lkIjogIjEwNDg5NzkyMDk5NjkzMDE2MDUzMSIsICJhdXRoX3VyaSI6ICJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20vby9vYXV0aDIvYXV0aCIsICJ0b2tlbl91cmkiOiAiaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5jb20vdG9rZW4ifQ==';

  AutoRefreshingAuthClient? _authClient;

  /// Dapatkan atau segarkan HTTP Auth Client terautentikasi Service Account
  Future<AutoRefreshingAuthClient?> _getClient() async {
    if (_authClient != null) return _authClient;
    try {
      final decodedJson = jsonDecode(utf8.decode(base64.decode(_encodedCredentials)));
      final accountCredentials = ServiceAccountCredentials.fromJson(decodedJson);
      final scopes = [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.file',
      ];
      _authClient = await clientViaServiceAccount(accountCredentials, scopes);
      return _authClient;
    } catch (e) {
      debugPrint('Service Account Auth Error: $e');
      return null;
    }
  }

  /// 1. Test Koneksi ke Spreadsheet ID yang dibagikan
  Future<Map<String, dynamic>> testConnection(String spreadsheetId) async {
    final client = await _getClient();
    if (client == null) {
      return {'success': false, 'message': 'Gagal autentikasi Service Account Google.'};
    }

    try {
      final url = Uri.parse('https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId');
      final res = await client.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final title = data['properties']?['title'] ?? 'Google Spreadsheet Toko';
        return {'success': true, 'name': title, 'message': 'Koneksi Service Account Berhasil!'};
      } else if (res.statusCode == 403 || res.statusCode == 404) {
        return {
          'success': false,
          'message': 'Akses ditolak (403/404). Pastikan spreadsheet telah di-Share ke bherung-pos@app-script-505503.iam.gserviceaccount.com sebagai Editor!',
        };
      } else {
        return {'success': false, 'message': 'HTTP ${res.statusCode}: ${res.body}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// 2. Simpan Transaksi Baru via Service Account
  Future<bool> appendTransaction(
    String spreadsheetId, {
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
    final client = await _getClient();
    if (client == null) return false;

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    final appendUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Transaksi!A1:append?valueInputOption=USER_ENTERED',
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
      final res = await client.post(
        appendUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'values': [row]
        }),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Service Account appendTransaction error: $e');
      return false;
    }
  }

  /// 3. Muat Produk via Service Account
  Future<List<Product>?> fetchProducts(String spreadsheetId) async {
    final client = await _getClient();
    if (client == null) return null;

    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Produk!A2:H?valueRenderOption=UNFORMATTED_VALUE',
    );

    try {
      final res = await client.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['values'] ?? [];
        final List<Product> products = [];

        // Jika sheet kosong, isi otomatis 17 produk sembako awal
        if (rows.isEmpty) {
          await seedInitialData(spreadsheetId);
          final secondRes = await client.get(url);
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
      debugPrint('Service Account fetchProducts error: $e');
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

  /// 4. Isi Data Awal Jika Sheet Masih Kosong
  Future<void> seedInitialData(String spreadsheetId) async {
    final client = await _getClient();
    if (client == null) return;

    final batchUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values:batchUpdate',
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
          'range': 'Pengguna_Kasir!A1:E3',
          'values': [
            ['ID_User', 'Nama_Kasir', 'Role', 'PIN', 'Status_Aktif'],
            ['usr-owner', 'Pemilik Toko (Owner)', 'owner', '1234', 'Aktif'],
            ['usr-staff', 'Penjaga Toko (Kasir)', 'staff', '5678', 'Aktif'],
          ]
        },
      ]
    };

    try {
      await client.post(
        batchUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(batchData),
      );
    } catch (_) {}
  }

  /// 5. Sync & Muat Daftar Pengguna Kasir & PIN via Service Account
  Future<List<AppUser>?> fetchUsers(String spreadsheetId) async {
    final client = await _getClient();
    if (client == null) return null;

    final url = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Pengguna_Kasir!A2:E?valueRenderOption=UNFORMATTED_VALUE',
    );

    try {
      final res = await client.get(url);
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
      debugPrint('Service Account fetchUsers error: $e');
    }
    return null;
  }

  /// 6. Update PIN Pengguna di Tab "Pengguna_Kasir" via Service Account
  Future<bool> updateUserPin(String spreadsheetId, String userId, String newPin) async {
    final client = await _getClient();
    if (client == null) return false;

    final getUrl = Uri.parse(
      'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Pengguna_Kasir!A2:E',
    );

    try {
      final res = await client.get(getUrl);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List rows = data['values'] ?? [];
        int rowIndex = -1;

        for (int i = 0; i < rows.length; i++) {
          if (rows[i] is List && (rows[i] as List).isNotEmpty && rows[i][0].toString() == userId) {
            rowIndex = i + 2;
            break;
          }
        }

        if (rowIndex != -1) {
          final updateUrl = Uri.parse(
            'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/Pengguna_Kasir!D$rowIndex?valueInputOption=USER_ENTERED',
          );
          final updateRes = await client.put(
            updateUrl,
            headers: {'Content-Type': 'application/json'},
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
      debugPrint('Service Account updateUserPin error: $e');
    }
    return false;
  }
}
