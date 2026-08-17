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

        for (final row in rows) {
          if (row is List && row.length >= 4) {
            final id = row.isNotEmpty ? row[0].toString() : 'prd-${DateTime.now().millisecondsSinceEpoch}';
            final code = row.length > 1 ? row[1].toString() : '';
            final name = row.length > 2 ? row[2].toString() : 'Produk';
            final price = row.length > 3 ? (double.tryParse(row[3].toString()) ?? 0.0) : 0.0;
            final costPrice = row.length > 4 ? (double.tryParse(row[4].toString()) ?? 0.0) : 0.0;
            final unit = row.length > 5 ? row[5].toString() : 'pcs';
            final category = row.length > 6 ? row[6].toString() : 'Sembako';
            final stock = row.length > 7 ? (int.tryParse(row[7].toString()) ?? 0) : 0;

            products.add(
              Product(
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
              ),
            );
          }
        }
        return products;
      }
    } catch (e) {
      debugPrint('Service Account fetchProducts error: $e');
    }
    return null;
  }
}
