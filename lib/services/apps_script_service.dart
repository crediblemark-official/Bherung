import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class AppsScriptService {
  static final AppsScriptService _instance = AppsScriptService._internal();
  factory AppsScriptService() => _instance;
  AppsScriptService._internal();

  // Master Router Endpoint Backend Bherung POS
  static const String masterBackendUrl =
      'https://script.google.com/macros/s/AKfycbyEU2-yYkYFPhWxQxuBte_I7ENLQWkqinu_Cvt1Xk28A2R01O-HjtN510S2U7_mAsCe/exec';

  String _webAppUrl = masterBackendUrl;
  String _spreadsheetId = ''; // Default KOSONG (tidak ada hardcode toko orang lain)
  String _rawInput = '';
  bool _isConnected = false;
  String _spreadsheetName = 'Mode Offline (Belum Terhubung)';
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _isInitialized = false;

  String get webAppUrl => _webAppUrl;
  String get spreadsheetId => _spreadsheetId;
  String get rawInput => _rawInput;
  bool get isConnected => _isConnected;
  String get spreadsheetName => _spreadsheetName;
  int get offlineQueueCount => _offlineQueue.length;

  // Inisialisasi & Muat data simpanan dari storage lokal
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _rawInput = prefs.getString('bherung_spreadsheet_input') ?? '';
      _spreadsheetId = prefs.getString('bherung_spreadsheet_id') ?? '';
      _webAppUrl = prefs.getString('bherung_web_app_url') ?? masterBackendUrl;
      _spreadsheetName = prefs.getString('bherung_spreadsheet_name') ?? 'Mode Offline (Belum Terhubung)';
      _isConnected = prefs.getBool('bherung_is_connected') ?? false;
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error loading saved settings: $e');
    }
  }

  // Helper untuk mengekstrak ID dari URL spreadsheet atau ID mentah
  String extractSpreadsheetId(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return '';

    // Jika format URL: https://docs.google.com/spreadsheets/d/ID_DISINI/edit...
    final match = RegExp(r'/spreadsheets/d/([a-zA-Z0-9-_]+)').firstMatch(clean);
    if (match != null && match.groupCount >= 1) {
      return match.group(1)!;
    }

    // Jika user memasukkan Web App URL kustom
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return clean;
    }

    return clean;
  }

  Future<void> setSpreadsheetInput(String input) async {
    _rawInput = input.trim();
    final extracted = extractSpreadsheetId(_rawInput);
    if (extracted.startsWith('http')) {
      _webAppUrl = extracted;
      _spreadsheetId = '';
    } else {
      _webAppUrl = masterBackendUrl;
      _spreadsheetId = extracted;
    }

    // Simpan ke local storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bherung_spreadsheet_input', _rawInput);
      await prefs.setString('bherung_spreadsheet_id', _spreadsheetId);
      await prefs.setString('bherung_web_app_url', _webAppUrl);
    } catch (e) {
      debugPrint('Error saving settings to storage: $e');
    }
  }

  Future<void> clearSettings() async {
    _rawInput = '';
    _spreadsheetId = '';
    _webAppUrl = masterBackendUrl;
    _isConnected = false;
    _spreadsheetName = 'Mode Offline (Belum Terhubung)';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('bherung_spreadsheet_input');
      await prefs.remove('bherung_spreadsheet_id');
      await prefs.remove('bherung_web_app_url');
      await prefs.remove('bherung_spreadsheet_name');
      await prefs.setBool('bherung_is_connected', false);
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  // 1. Test Koneksi ke Spreadsheet & Simpan Status Permanen
  Future<Map<String, dynamic>> testConnection([String? input]) async {
    if (input != null && input.trim().isNotEmpty) {
      await setSpreadsheetInput(input);
    }

    if (_spreadsheetId.isEmpty && !_webAppUrl.startsWith('http')) {
      return {
        'success': false,
        'message': 'Harap masukkan Link atau ID Spreadsheet toko Anda.',
      };
    }

    try {
      final queryParam = _spreadsheetId.isNotEmpty ? '&spreadsheetId=$_spreadsheetId' : '';
      final uri = Uri.parse('$_webAppUrl?action=ping$queryParam');
      final response = await _sendWithRedirect(uri, method: 'GET');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _isConnected = true;
          _spreadsheetName = data['spreadsheetName'] ?? 'Spreadsheet Toko';

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('bherung_is_connected', true);
            await prefs.setString('bherung_spreadsheet_name', _spreadsheetName);
          } catch (_) {}

          return {
            'success': true,
            'message': data['message'] ?? 'Berhasil terhubung ke Spreadsheet Toko!',
            'spreadsheetName': _spreadsheetName,
          };
        }
      }
      return {'success': false, 'message': 'Gagal merespons: ${response.statusCode} - ${response.body}'};
    } catch (e) {
      return {'success': false, 'message': 'Error koneksi: $e'};
    }
  }

  // 2. Kirim Transaksi Penjualan ke Spreadsheet
  Future<bool> sendTransaction({
    required String id,
    required TransactionType type,
    required String customerName,
    required double subtotal,
    required double discountAmount,
    required double totalAmount,
    required String paymentMethod,
    required String cashierName,
    required List<CartItem> items,
  }) async {
    final payload = {
      'action': 'addTransaction',
      'spreadsheetId': _spreadsheetId,
      'data': {
        'id': id,
        'transactionType': type.label,
        'customerName': customerName.isEmpty ? 'Umum' : customerName,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'cashierName': cashierName,
        'items': items.map((i) => {
          'id': i.product.id,
          'code': i.product.code,
          'name': i.product.name,
          'unit': i.product.unit,
          'qty': i.quantity,
          'unitPrice': i.unitPrice,
          'totalPrice': i.totalPrice,
        }).toList(),
      },
    };

    if (!isConnected) {
      _offlineQueue.add(payload);
      return false;
    }

    try {
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      } else {
        _offlineQueue.add(payload);
        return false;
      }
    } catch (e) {
      debugPrint('Error sending transaction: $e');
      _offlineQueue.add(payload);
      return false;
    }
  }

  // 3. Catat Kasbon Baru ke Spreadsheet
  Future<bool> sendKasbon({
    required String id,
    required String customerName,
    required String customerPhone,
    required double amount,
    required DateTime? dueDate,
    required List<CartItem> items,
  }) async {
    final payload = {
      'action': 'addKasbon',
      'spreadsheetId': _spreadsheetId,
      'data': {
        'id': id,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'amount': amount,
        'dueDate': dueDate?.toIso8601String(),
        'items': items.map((i) => {
          'id': i.product.id,
          'name': i.product.name,
          'unit': i.product.unit,
          'qty': i.quantity,
        }).toList(),
      },
    };

    if (!isConnected) {
      _offlineQueue.add(payload);
      return false;
    }

    try {
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      } else {
        _offlineQueue.add(payload);
        return false;
      }
    } catch (e) {
      _offlineQueue.add(payload);
      return false;
    }
  }

  // 4. Update Status Pelunasan Kasbon
  Future<bool> payKasbon(String kasbonId) async {
    if (!isConnected) return false;

    try {
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode({
          'action': 'payKasbon',
          'spreadsheetId': _spreadsheetId,
          'kasbonId': kasbonId,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // 5. Batch Sync Seluruh Produk Sembako ke Spreadsheet
  Future<Map<String, dynamic>> syncAllProducts(List<Product> products) async {
    if (!isConnected) {
      return {'success': false, 'message': 'Belum terhubung ke Google Spreadsheet.'};
    }

    try {
      final uri = Uri.parse(_webAppUrl);
      final payload = {
        'action': 'syncProducts',
        'spreadsheetId': _spreadsheetId,
        'products': products.map((p) => {
          'id': p.id,
          'name': p.name,
          'code': p.code,
          'categoryId': p.categoryId,
          'price': p.price,
          'wholesalePrice': p.wholesalePrice,
          'wholesaleMinQty': p.wholesaleMinQty,
          'unit': p.unit,
          'stock': p.stock,
          'description': p.description,
        }).toList(),
      };

      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': data['status'] == 'success', 'message': data['message']};
      }
      return {'success': false, 'message': 'Gagal sync produk (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Error sync produk: $e'};
    }
  }

  // 6. Sinkronkan Antrean Offline saat Terhubung Kembali
  Future<int> flushOfflineQueue() async {
    if (!isConnected || _offlineQueue.isEmpty) return 0;

    int syncedCount = 0;
    final List<Map<String, dynamic>> failedItems = [];

    for (final item in _offlineQueue) {
      try {
        final uri = Uri.parse(_webAppUrl);
        final response = await _sendWithRedirect(
          uri,
          method: 'POST',
          body: jsonEncode(item),
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          syncedCount++;
        } else {
          failedItems.add(item);
        }
      } catch (e) {
        failedItems.add(item);
      }
    }

    _offlineQueue.clear();
    _offlineQueue.addAll(failedItems);
    return syncedCount;
  }

  // 7. Ambil Seluruh Data Master Katalog Produk dari Google Spreadsheet Toko
  Future<List<Product>?> fetchProductsFromSpreadsheet() async {
    if (!isConnected) return null;

    try {
      final queryParam = _spreadsheetId.isNotEmpty ? '&spreadsheetId=$_spreadsheetId' : '';
      final uri = Uri.parse('$_webAppUrl?action=getProducts$queryParam');
      final response = await _sendWithRedirect(uri, method: 'GET');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['products'] is List) {
          final List rawList = data['products'];
          final List<Product> fetchedProducts = [];

          for (final item in rawList) {
            if (item is Map) {
              final catId = item['categoryId']?.toString() ?? 'sembako';
              fetchedProducts.add(
                Product(
                  id: item['id']?.toString() ?? 'prd-${DateTime.now().millisecondsSinceEpoch}',
                  name: item['name']?.toString() ?? 'Produk Tanpa Nama',
                  price: (item['price'] is num) ? (item['price'] as num).toDouble() : double.tryParse(item['price']?.toString() ?? '0') ?? 0,
                  costPrice: (item['costPrice'] is num) ? (item['costPrice'] as num).toDouble() : double.tryParse(item['costPrice']?.toString() ?? ''),
                  wholesalePrice: (item['wholesalePrice'] is num) ? (item['wholesalePrice'] as num).toDouble() : double.tryParse(item['wholesalePrice']?.toString() ?? ''),
                  wholesaleMinQty: (item['wholesaleMinQty'] is num) ? (item['wholesaleMinQty'] as num).toInt() : int.tryParse(item['wholesaleMinQty']?.toString() ?? ''),
                  unit: item['unit']?.toString() ?? 'pcs',
                  categoryId: catId,
                  icon: AppTheme.getCategoryIcon(catId),
                  color: AppTheme.getCategoryColor(catId),
                  code: item['code']?.toString() ?? '',
                  stock: (item['stock'] is num) ? (item['stock'] as num).toInt() : int.tryParse(item['stock']?.toString() ?? '0') ?? 0,
                  minStockAlert: (item['minStockAlert'] is num) ? (item['minStockAlert'] as num).toInt() : int.tryParse(item['minStockAlert']?.toString() ?? '5') ?? 5,
                  description: item['description']?.toString(),
                  isSensitiveItem: item['isSensitiveItem'] == true || item['isSensitiveItem']?.toString() == 'true',
                ),
              );
            }
          }
          return fetchedProducts;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching products from spreadsheet: $e');
      return null;
    }
  }

  // Helper untuk menangani W3C Simple CORS Request & 302 Redirect
  Future<http.Response> _sendWithRedirect(
    Uri uri, {
    String method = 'GET',
    String? body,
    int maxRedirects = 5,
  }) async {
    var client = http.Client();
    var currentUri = uri;

    try {
      for (int i = 0; i < maxRedirects; i++) {
        http.Response response;
        if (method == 'POST') {
          response = await client.post(
            currentUri,
            headers: {'Content-Type': 'text/plain;charset=utf-8'},
            body: body,
          );
        } else {
          response = await client.get(currentUri);
        }

        if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) {
          final location = response.headers['location'];
          if (location != null && location.isNotEmpty) {
            currentUri = Uri.parse(location);
            method = 'GET';
            continue;
          }
        }

        return response;
      }

      throw Exception('Terlalu banyak redirect dari Google Apps Script.');
    } finally {
      client.close();
    }
  }
}
