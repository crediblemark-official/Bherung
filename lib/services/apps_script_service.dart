import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../theme/app_theme.dart';
import 'service_account_sheets_service.dart';

class SyncAllResult {
  final bool success;
  final String message;
  final List<Product>? products;
  final List<AppUser>? users;
  final List<KasbonRecord>? kasbon;
  final List<ShiftRecord>? shifts;
  final List<StockMutation>? mutations;
  final StoreProfile? storeProfile;
  final int syncedOfflineCount;
  final double? todaySales;
  final int? todayTrxCount;

  const SyncAllResult({
    required this.success,
    required this.message,
    this.products,
    this.users,
    this.kasbon,
    this.shifts,
    this.mutations,
    this.storeProfile,
    this.syncedOfflineCount = 0,
    this.todaySales,
    this.todayTrxCount,
  });
}

class AppsScriptService {
  static final AppsScriptService _instance = AppsScriptService._internal();
  factory AppsScriptService() => _instance;
  AppsScriptService._internal();

  String _webAppUrl = '';
  String _spreadsheetId = '';
  String _rawInput = '';
  bool _isConnected = false;
  String _spreadsheetName = 'Mode Offline (Belum Terhubung)';
  final List<Map<String, dynamic>> _offlineQueue = [];
  bool _isInitialized = false;

  String get webAppUrl => _webAppUrl;
  String get spreadsheetId => _spreadsheetId;
  String get rawInput => _rawInput;
  bool get isConnected => _isConnected && (_webAppUrl.isNotEmpty || _spreadsheetId.isNotEmpty);
  String get spreadsheetName => _spreadsheetName;
  int get offlineQueueCount => _offlineQueue.length;

  // Inisialisasi & Muat data simpanan dari storage lokal
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _rawInput = prefs.getString('bherung_spreadsheet_input') ?? '';
      _spreadsheetId = prefs.getString('bherung_spreadsheet_id') ?? '';
      _webAppUrl = prefs.getString('bherung_web_app_url') ?? '';
      _spreadsheetName = prefs.getString('bherung_spreadsheet_name') ?? 'Mode Offline (Belum Terhubung)';
      _isConnected = (prefs.getBool('bherung_is_connected') ?? false) && (_webAppUrl.isNotEmpty || _spreadsheetId.isNotEmpty);
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
    if (extracted.startsWith('http') && extracted.contains('script.google.com')) {
      _webAppUrl = extracted;
      _spreadsheetId = '';
    } else {
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

  Future<void> setSpreadsheetAndWebApp({required String spreadsheetInput, String? webAppUrlInput}) async {
    _rawInput = spreadsheetInput.trim();
    _spreadsheetId = extractSpreadsheetId(_rawInput);
    if (webAppUrlInput != null && webAppUrlInput.trim().isNotEmpty) {
      _webAppUrl = webAppUrlInput.trim();
    } else if (_rawInput.startsWith('http') && _rawInput.contains('script.google.com')) {
      _webAppUrl = _rawInput;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bherung_spreadsheet_input', _rawInput);
      await prefs.setString('bherung_spreadsheet_id', _spreadsheetId);
      await prefs.setString('bherung_web_app_url', _webAppUrl);
    } catch (e) {
      debugPrint('Error saving settings to storage: $e');
    }
  }

  Future<void> setCustomWebAppUrl(String url) async {
    _webAppUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bherung_web_app_url', _webAppUrl);
    } catch (e) {
      debugPrint('Error saving web app url: $e');
    }
  }

  Future<void> clearSettings() async {
    _rawInput = '';
    _spreadsheetId = '';
    _webAppUrl = '';
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

  // Helper untuk mengirim perintah ke Google Apps Script via POST (CORS-friendly untuk Web & Android)
  Future<http.Response> _sendAction(String action, [Map<String, dynamic>? extra]) async {
    final payload = {
      'action': action,
      if (_spreadsheetId.isNotEmpty) 'spreadsheetId': _spreadsheetId,
      ...?extra,
    };
    final uri = Uri.parse(_webAppUrl);
    return await _sendWithRedirect(
      uri,
      method: 'POST',
      body: jsonEncode(payload),
    );
  }

  // 1. Test Koneksi ke Spreadsheet & Simpan Status Permanen
  Future<Map<String, dynamic>> testConnection([String? input]) async {
    if (input != null && input.trim().isNotEmpty) {
      await setSpreadsheetInput(input);
    }

    if (_webAppUrl.isEmpty && _spreadsheetId.isEmpty) {
      return {
        'success': false,
        'message': 'Harap masukkan Link/ID Google Spreadsheet toko Anda.',
      };
    }

    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('ping');

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
      }

      // Coba koneksi langsung via ID Spreadsheet (Metode 1: Otomatis 1-Klik)
      if (_spreadsheetId.isNotEmpty) {
        final saRes = await ServiceAccountSheetsService().testConnection(_spreadsheetId);
        if (saRes['success'] == true) {
          _isConnected = true;
          _spreadsheetName = saRes['name'] ?? 'Google Spreadsheet Toko';

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('bherung_is_connected', true);
            await prefs.setString('bherung_spreadsheet_name', _spreadsheetName);
          } catch (_) {}

          return {
            'success': true,
            'message': 'Berhasil terhubung ke Google Spreadsheet Toko!',
            'spreadsheetName': _spreadsheetName,
          };
        }
      }

      return {'success': false, 'message': 'Gagal merespons dari Spreadsheet. Pastikan ID benar & akses berbagi diatur "Siapa saja yang memiliki link: Editor".'};
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final saRes = await ServiceAccountSheetsService().testConnection(_spreadsheetId);
        if (saRes['success'] == true) {
          _isConnected = true;
          _spreadsheetName = saRes['name'] ?? 'Google Spreadsheet Toko';

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('bherung_is_connected', true);
            await prefs.setString('bherung_spreadsheet_name', _spreadsheetName);
          } catch (_) {}

          return {
            'success': true,
            'message': 'Berhasil terhubung ke Google Spreadsheet Toko!',
            'spreadsheetName': _spreadsheetName,
          };
        }
      }

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
    double deliveryFee = 0.0,
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
        'deliveryFee': deliveryFee,
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

  // 7. Ambil Seluruh Data Master Katalog Produk dari Google Spreadsheet
  Future<List<Product>?> fetchProductsFromSpreadsheet() async {
    if (!isConnected) return null;

    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getProducts');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final List? rawList = (data['products'] is List) ? data['products'] : (data['data'] is List ? data['data'] : null);
          if (data['status'] == 'success' && rawList != null) {
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
      }

      // Fallback: Ambil langsung dari Google Spreadsheet
      if (_spreadsheetId.isNotEmpty) {
        final directProducts = await ServiceAccountSheetsService().fetchProducts(_spreadsheetId);
        if (directProducts != null && directProducts.isNotEmpty) {
          return directProducts;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final directProducts = await ServiceAccountSheetsService().fetchProducts(_spreadsheetId);
        if (directProducts != null && directProducts.isNotEmpty) {
          return directProducts;
        }
      }
      debugPrint('Sync Info: Produk belum dapat diambil dari cloud ($e). Menggunakan database lokal.');
      return null;
    }
  }

  // 8. Sync Seluruh Data Akun Penjaga Toko / Kasir ke Google Spreadsheet Toko
  Future<Map<String, dynamic>> syncAllUsers(List<AppUser> users) async {
    if (!isConnected) {
      return {'success': false, 'message': 'Belum terhubung ke Google Spreadsheet.'};
    }

    try {
      if (_webAppUrl.isEmpty) {
        return {'success': true, 'message': 'Data pengguna tersimpan di database lokal.'};
      }
      final uri = Uri.parse(_webAppUrl);
      final payload = {
        'action': 'syncUsers',
        'spreadsheetId': _spreadsheetId,
        'users': users.map((u) => u.toJson()).toList(),
      };

      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return {'success': data['status'] == 'success', 'message': data['message'] ?? 'Berhasil sinkronisasi akun pengguna ke Spreadsheet!'};
      }
      return {'success': false, 'message': 'Gagal sync pengguna (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'message': 'Error sync pengguna: $e'};
    }
  }

  // 9. Ambil Seluruh Data Akun Penjaga Toko / Kasir dari Google Spreadsheet Toko
  Future<List<AppUser>?> fetchUsersFromSpreadsheet() async {
    if (!isConnected) return null;

    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getUsers');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final List? rawList = (data['users'] is List) ? data['users'] : (data['data'] is List ? data['data'] : null);
          if (data['status'] == 'success' && rawList != null) {
            final List<AppUser> fetchedUsers = [];

            for (final item in rawList) {
              if (item is Map) {
                fetchedUsers.add(AppUser.fromJson(Map<String, dynamic>.from(item)));
              }
            }
            if (fetchedUsers.isNotEmpty) {
              return fetchedUsers;
            }
          }
        }
      }

      // Fallback via Spreadsheet langsung
      if (_spreadsheetId.isNotEmpty) {
        final saUsers = await ServiceAccountSheetsService().fetchUsers(_spreadsheetId);
        if (saUsers != null && saUsers.isNotEmpty) {
          return saUsers;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final saUsers = await ServiceAccountSheetsService().fetchUsers(_spreadsheetId);
        if (saUsers != null && saUsers.isNotEmpty) {
          return saUsers;
        }
      }
      debugPrint('Sync Info: Data kasir belum dapat diambil dari cloud ($e). Menggunakan akun lokal.');
      return null;
    }
  }

  // 10. Ambil Seluruh Data Buku Kasbon dari Google Spreadsheet Toko
  Future<List<KasbonRecord>?> fetchKasbonFromSpreadsheet() async {
    if (!isConnected) return null;

    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getKasbon');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success' && data['data'] is List) {
            final List rawList = data['data'];
            final List<KasbonRecord> fetchedKasbon = [];

            for (final item in rawList) {
              if (item is Map) {
                DateTime createdAt = DateTime.now();
                if (item['createdAt'] != null) {
                  createdAt = DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now();
                }
                DateTime? dueDate;
                if (item['dueDate'] != null && item['dueDate'].toString() != '-') {
                  dueDate = DateTime.tryParse(item['dueDate'].toString());
                }

                fetchedKasbon.add(
                  KasbonRecord(
                    id: item['id']?.toString() ?? 'KSB-${DateTime.now().millisecondsSinceEpoch}',
                    customerName: item['customerName']?.toString() ?? 'Pelanggan',
                    customerPhone: item['customerPhone']?.toString() ?? '',
                    amount: (item['amount'] is num) ? (item['amount'] as num).toDouble() : double.tryParse(item['amount']?.toString() ?? '0') ?? 0,
                    createdAt: createdAt,
                    dueDate: dueDate,
                    isPaid: item['isPaid'] == true,
                    items: [],
                  ),
                );
              }
            }
            return fetchedKasbon;
          }
        }
      }

      // Fallback via Spreadsheet langsung
      if (_spreadsheetId.isNotEmpty) {
        final directKasbon = await ServiceAccountSheetsService().fetchKasbon(_spreadsheetId);
        if (directKasbon != null && directKasbon.isNotEmpty) {
          return directKasbon;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final directKasbon = await ServiceAccountSheetsService().fetchKasbon(_spreadsheetId);
        if (directKasbon != null && directKasbon.isNotEmpty) {
          return directKasbon;
        }
      }
      debugPrint('Sync Info: Data kasbon belum dapat diambil dari cloud ($e). Menggunakan kasbon lokal.');
      return null;
    }
  }

  // 11. Simpan & Ambil Rekap Shift ke/dari Google Spreadsheet
  Future<bool> sendShiftRecord(ShiftRecord shift) async {
    if (!isConnected) return false;
    try {
      if (_webAppUrl.isEmpty) return true;
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode({
          'action': 'addShift',
          'spreadsheetId': _spreadsheetId,
          'data': shift.toJson(),
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

  Future<List<ShiftRecord>?> fetchShiftsFromSpreadsheet() async {
    if (!isConnected) return null;
    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getShifts');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final List? rawList = (data['shifts'] is List) ? data['shifts'] : (data['data'] is List ? data['data'] : null);
          if (data['status'] == 'success' && rawList != null) {
            final List<ShiftRecord> list = [];
            for (final item in rawList) {
              if (item is Map) {
                list.add(ShiftRecord.fromJson(Map<String, dynamic>.from(item)));
              }
            }
            return list;
          }
        }
      }

      if (_spreadsheetId.isNotEmpty) {
        final directShifts = await ServiceAccountSheetsService().fetchShifts(_spreadsheetId);
        if (directShifts != null && directShifts.isNotEmpty) {
          return directShifts;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final directShifts = await ServiceAccountSheetsService().fetchShifts(_spreadsheetId);
        if (directShifts != null && directShifts.isNotEmpty) {
          return directShifts;
        }
      }
      return null;
    }
  }

  // 12. Simpan & Ambil Mutasi Stok ke/dari Google Spreadsheet
  Future<bool> sendStockMutation(StockMutation mutation) async {
    if (!isConnected) return false;
    try {
      if (_webAppUrl.isEmpty) return true;
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode({
          'action': 'addMutation',
          'spreadsheetId': _spreadsheetId,
          'data': mutation.toJson(),
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

  Future<List<StockMutation>?> fetchMutationsFromSpreadsheet() async {
    if (!isConnected) return null;
    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getMutations');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          final List? rawList = (data['mutations'] is List) ? data['mutations'] : (data['data'] is List ? data['data'] : null);
          if (data['status'] == 'success' && rawList != null) {
            final List<StockMutation> list = [];
            for (final item in rawList) {
              if (item is Map) {
                list.add(StockMutation.fromJson(Map<String, dynamic>.from(item)));
              }
            }
            return list;
          }
        }
      }

      if (_spreadsheetId.isNotEmpty) {
        final directMutations = await ServiceAccountSheetsService().fetchMutations(_spreadsheetId);
        if (directMutations != null && directMutations.isNotEmpty) {
          return directMutations;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final directMutations = await ServiceAccountSheetsService().fetchMutations(_spreadsheetId);
        if (directMutations != null && directMutations.isNotEmpty) {
          return directMutations;
        }
      }
      return null;
    }
  }

  // 13. Simpan & Ambil Profil Toko, QRIS, & Rekening ke/dari Google Spreadsheet
  Future<bool> sendStoreProfile(StoreProfile profile) async {
    if (!isConnected) return false;
    try {
      if (_webAppUrl.isEmpty) return true;
      final uri = Uri.parse(_webAppUrl);
      final response = await _sendWithRedirect(
        uri,
        method: 'POST',
        body: jsonEncode({
          'action': 'syncStoreProfile',
          'spreadsheetId': _spreadsheetId,
          'profile': profile.toJson(),
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

  Future<StoreProfile?> fetchStoreProfileFromSpreadsheet() async {
    if (!isConnected) return null;
    try {
      if (_webAppUrl.isNotEmpty) {
        final response = await _sendAction('getStoreProfile');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success' && data['profile'] is Map) {
            return StoreProfile.fromJson(Map<String, dynamic>.from(data['profile']));
          }
        }
      }

      if (_spreadsheetId.isNotEmpty) {
        final directProfile = await ServiceAccountSheetsService().fetchStoreProfile(_spreadsheetId);
        if (directProfile != null) {
          return directProfile;
        }
      }

      return null;
    } catch (e) {
      if (_spreadsheetId.isNotEmpty) {
        final directProfile = await ServiceAccountSheetsService().fetchStoreProfile(_spreadsheetId);
        if (directProfile != null) {
          return directProfile;
        }
      }
      return null;
    }
  }

  // 14. Ambil Rekap Penjualan & Transaksi Hari Ini
  Future<Map<String, dynamic>?> fetchTodaySalesFromSpreadsheet() async {
    if (!isConnected) return null;
    try {
      final response = await _sendAction('getTransactions');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return {
            'todaySales': (data['todaySales'] is num) ? (data['todaySales'] as num).toDouble() : 0.0,
            'todayTrxCount': (data['todayTrxCount'] is num) ? (data['todayTrxCount'] as num).toInt() : 0,
            'transactions': data['transactions'],
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 15. SINKRONISASI SELURUH DATA SISTEM (ALL DATA FULL SYNC)
  Future<SyncAllResult> syncAllDataFromSpreadsheet() async {
    if (!isConnected) {
      return const SyncAllResult(
        success: false,
        message: 'Aplikasi dalam Mode Offline (belum terhubung ke Google Spreadsheet).',
      );
    }

    try {
      // Jalankan seluruh pengambilan data secara paralel untuk kecepatan maksimal
      final results = await Future.wait([
        fetchProductsFromSpreadsheet(),
        fetchUsersFromSpreadsheet(),
        fetchKasbonFromSpreadsheet(),
        fetchShiftsFromSpreadsheet(),
        fetchMutationsFromSpreadsheet(),
        fetchStoreProfileFromSpreadsheet(),
        fetchTodaySalesFromSpreadsheet(),
        flushOfflineQueue(),
      ]);

      final products = results[0] as List<Product>?;
      final users = results[1] as List<AppUser>?;
      final kasbon = results[2] as List<KasbonRecord>?;
      final shifts = results[3] as List<ShiftRecord>?;
      final mutations = results[4] as List<StockMutation>?;
      final profile = results[5] as StoreProfile?;
      final salesData = results[6] as Map<String, dynamic>?;
      final offlineCount = results[7] as int;

      return SyncAllResult(
        success: true,
        message: 'Seluruh data sistem berhasil disinkronkan dengan Google Spreadsheet!',
        products: products,
        users: users,
        kasbon: kasbon,
        shifts: shifts,
        mutations: mutations,
        storeProfile: profile,
        syncedOfflineCount: offlineCount,
        todaySales: salesData?['todaySales'] as double?,
        todayTrxCount: salesData?['todayTrxCount'] as int?,
      );
    } catch (e) {
      return SyncAllResult(
        success: false,
        message: 'Gagal sinkronisasi data: $e',
      );
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
