import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/branch.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../theme/app_theme.dart';

class ServiceAccountSheetsService {
  static final ServiceAccountSheetsService _instance = ServiceAccountSheetsService._internal();
  factory ServiceAccountSheetsService() => _instance;
  ServiceAccountSheetsService._internal();

  /// Helper untuk membaca data tabel Google Sheets via Google Visualization API (GVIZ)
  /// Sangat cepat, stabil, bebas limit, dan didukung 100% di Web Browser & Android
  Future<List<List<dynamic>>?> _fetchSheetRowsGviz(String spreadsheetId, String sheetName) async {
    try {
      final url = Uri.parse(
        'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:json&sheet=${Uri.encodeComponent(sheetName)}',
      );
      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.contains('google.visualization.Query.setResponse')) {
        final jsonStr = res.body.substring(
          res.body.indexOf('{'),
          res.body.lastIndexOf('}') + 1,
        );
        final data = jsonDecode(jsonStr);
        final rowsRaw = data['table']?['rows'] as List?;
        if (rowsRaw == null) return [];

        final List<List<dynamic>> result = [];
        for (final row in rowsRaw) {
          final cList = row['c'] as List?;
          if (cList != null) {
            final rowValues = cList.map((cell) => cell != null ? cell['v'] : null).toList();
            result.add(rowValues);
          }
        }
        return result;
      }
    } catch (e) {
      debugPrint('GVIZ fetch error ($sheetName): $e');
    }
    return null;
  }

  /// 1. Test Koneksi ke Spreadsheet ID
  Future<Map<String, dynamic>> testConnection(String spreadsheetId) async {
    try {
      final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Produk');
      if (rows != null) {
        return {
          'success': true,
          'name': 'Database Toko Bherung POS',
          'message': 'Berhasil terhubung ke Google Spreadsheet Toko!',
        };
      }
    } catch (e) {
      debugPrint('testConnection error: $e');
    }

    return {
      'success': false,
      'message': 'Gagal mengakses Spreadsheet. Pastikan ID benar dan akses berbagi diatur "Siapa saja yang memiliki link: Editor".',
    };
  }

  /// 2. Muat Seluruh Produk dari Google Spreadsheet
  Future<List<Product>?> fetchProducts(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Produk');
    if (rows == null || rows.isEmpty) return null;

    final List<Product> products = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0]?.toString() ?? 'prd-${DateTime.now().millisecondsSinceEpoch}';
        final name = (row.length > 1 ? row[1]?.toString() : null) ?? 'Produk';
        final code = (row.length > 2 ? row[2]?.toString() : null) ?? '';
        final category = (row.length > 3 ? row[3]?.toString() : null) ?? 'sembako';
        final price = (row.length > 4 && row[4] is num)
            ? (row[4] as num).toDouble()
            : (double.tryParse(row.length > 4 ? row[4]?.toString() ?? '0' : '0') ?? 0.0);
        final wholesalePrice = (row.length > 5 && row[5] is num)
            ? (row[5] as num).toDouble()
            : double.tryParse(row.length > 5 ? row[5]?.toString() ?? '' : '');
        final wholesaleMinQty = (row.length > 6 && row[6] is num)
            ? (row[6] as num).toInt()
            : int.tryParse(row.length > 6 ? row[6]?.toString() ?? '' : '');
        final unit = (row.length > 7 ? row[7]?.toString() : null) ?? 'pcs';
        final stock = (row.length > 8 && row[8] is num)
            ? (row[8] as num).toInt()
            : (int.tryParse(row.length > 8 ? row[8]?.toString() ?? '0' : '0') ?? 0);
        final description = row.length > 9 ? row[9]?.toString() : null;

        final catId = category.toLowerCase().replaceAll(' ', '_');
        products.add(
          Product(
            id: id,
            name: name,
            price: price,
            wholesalePrice: wholesalePrice,
            wholesaleMinQty: wholesaleMinQty,
            unit: unit,
            categoryId: catId,
            icon: AppTheme.getCategoryIcon(catId),
            color: AppTheme.getCategoryColor(catId),
            code: code,
            stock: stock,
            minStockAlert: 5,
            description: description,
          ),
        );
      }
    }
    return products.isNotEmpty ? products : null;
  }

  /// 3. Muat Pengguna Kasir dari Google Spreadsheet
  Future<List<AppUser>?> fetchUsers(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Pengguna_Kasir');
    if (rows == null || rows.isEmpty) return null;

    final List<AppUser> users = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0].toString();
        final name = (row.length > 1 ? row[1]?.toString() : null) ?? 'Kasir';
        final phone = (row.length > 2 ? row[2]?.toString() : null) ?? '';
        final roleStr = (row.length > 3 ? row[3]?.toString() : 'staff') ?? 'staff';
        final pin = (row.length > 4 ? row[4]?.toString() : '1234') ?? '1234';
        final status = (row.length > 5 ? row[5]?.toString() : 'AKTIF') ?? 'AKTIF';
        final branchId = row.length > 6 ? row[6]?.toString() : null;
        final branchName = row.length > 7 ? row[7]?.toString() : null;

        final cleanStatus = status.trim().toLowerCase();
        final isActive = cleanStatus == 'aktif' ||
            cleanStatus == 'true' ||
            cleanStatus == '1' ||
            (cleanStatus != 'nonaktif' && cleanStatus != 'false' && cleanStatus != '0' && cleanStatus.isNotEmpty);

        final role = (roleStr.toLowerCase() == 'owner' || roleStr.toLowerCase().contains('pemilik'))
            ? UserRoleType.owner
            : UserRoleType.staff;

        users.add(
          AppUser(
            id: id,
            name: name,
            phone: phone,
            role: role,
            pin: pin,
            isActive: isActive,
            branchId: role == UserRoleType.staff ? (branchId?.isNotEmpty == true ? branchId : null) : null,
            branchName: role == UserRoleType.staff ? (branchName?.isNotEmpty == true ? branchName : null) : null,
          ),
        );
      }
    }
    return users.isNotEmpty ? users : null;
  }

  /// 4. Muat Buku Kasbon dari Google Spreadsheet
  Future<List<KasbonRecord>?> fetchKasbon(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Buku_Kasbon');
    if (rows == null || rows.isEmpty) return null;

    final List<KasbonRecord> kasbonList = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0].toString();
        final customerName = (row.length > 1 ? row[1]?.toString() : null) ?? 'Pelanggan';
        final customerPhone = (row.length > 2 ? row[2]?.toString() : null) ?? '';
        final amount = (row.length > 3 && row[3] is num)
            ? (row[3] as num).toDouble()
            : (double.tryParse(row.length > 3 ? row[3]?.toString() ?? '0' : '0') ?? 0.0);
        DateTime createdAt = DateTime.now();
        if (row.length > 4 && row[4] != null) {
          createdAt = DateTime.tryParse(row[4].toString()) ?? DateTime.now();
        }
        DateTime? dueDate;
        if (row.length > 5 && row[5] != null && row[5].toString() != '-' && row[5].toString().isNotEmpty) {
          dueDate = DateTime.tryParse(row[5].toString());
        }
        final status = (row.length > 6 ? row[6]?.toString() : '') ?? '';
        final branch = row.length > 8 ? row[8]?.toString() : null;

        kasbonList.add(
          KasbonRecord(
            id: id,
            customerName: customerName,
            customerPhone: customerPhone,
            amount: amount,
            createdAt: createdAt,
            dueDate: dueDate,
            isPaid: status.toLowerCase().contains('lunas'),
            items: [],
            branchName: branch,
          ),
        );
      }
    }
    return kasbonList;
  }

  /// 5. Muat Shift Rekap dari Google Spreadsheet
  Future<List<ShiftRecord>?> fetchShifts(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Shift_Rekap');
    if (rows == null || rows.isEmpty) return null;

    final List<ShiftRecord> shifts = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0].toString();
        final cashierName = (row.length > 1 ? row[1]?.toString() : null) ?? 'Kasir';
        final dateStr = (row.length > 2 ? row[2]?.toString() : '') ?? '';
        final timeStr = (row.length > 3 ? row[3]?.toString() : '') ?? '';
        final totalSales = (row.length > 4 && row[4] is num)
            ? (row[4] as num).toDouble()
            : (double.tryParse(row.length > 4 ? row[4]?.toString() ?? '0' : '0') ?? 0.0);
        final txCount = (row.length > 5 && row[5] is num)
            ? (row[5] as num).toInt()
            : (int.tryParse(row.length > 5 ? row[5]?.toString() ?? '0' : '0') ?? 0);
        final notes = row.length > 7 ? row[7]?.toString() : null;
        final nextCashier = (row.length > 8 ? row[8]?.toString() : null) ?? '';
        final branchName = row.length > 9 ? row[9]?.toString() : null;

        DateTime recordTime = DateTime.now();
        if (dateStr.isNotEmpty) {
          final isoStr = timeStr.isNotEmpty ? '${dateStr}T$timeStr' : dateStr;
          recordTime = DateTime.tryParse(isoStr) ?? DateTime.now();
        }

        shifts.add(
          ShiftRecord(
            id: id,
            cashierName: cashierName,
            shiftName: 'Laporan Jaga',
            startTime: recordTime,
            endTime: recordTime,
            startingCashDrawer: 0.0,
            systemCashSales: totalSales,
            systemQrisSales: 0.0,
            systemKasbonSales: 0.0,
            totalSystemSales: totalSales,
            physicalCashCounted: 0.0,
            cashDifference: 0.0,
            stockAudits: [],
            handoverNotes: notes,
            nextCashierName: nextCashier,
            transactionCount: txCount,
            branchName: branchName,
          ),
        );
      }
    }
    return shifts;
  }

  /// 6. Muat Mutasi Stok dari Google Spreadsheet
  Future<List<StockMutation>?> fetchMutations(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Mutasi_Stok');
    if (rows == null || rows.isEmpty) return null;

    final List<StockMutation> mutations = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0].toString();
        final productId = (row.length > 1 ? row[1]?.toString() : null) ?? '';
        final productName = (row.length > 2 ? row[2]?.toString() : null) ?? 'Produk';
        final typeStr = (row.length > 3 ? row[3]?.toString() : 'restock') ?? 'restock';
        final qty = (row.length > 4 && row[4] is num)
            ? (row[4] as num).toInt()
            : (int.tryParse(row.length > 4 ? row[4]?.toString() ?? '0' : '0') ?? 0);
        final prevStock = (row.length > 5 && row[5] is num)
            ? (row[5] as num).toInt()
            : (int.tryParse(row.length > 5 ? row[5]?.toString() ?? '0' : '0') ?? 0);
        final newStock = (row.length > 6 && row[6] is num)
            ? (row[6] as num).toInt()
            : (int.tryParse(row.length > 6 ? row[6]?.toString() ?? '0' : '0') ?? 0);
        DateTime timestamp = DateTime.now();
        if (row.length > 7 && row[7] != null) {
          timestamp = DateTime.tryParse(row[7].toString()) ?? DateTime.now();
        }
        final notes = row.length > 8 ? row[8]?.toString() : null;
        final cashier = (row.length > 9 ? row[9]?.toString() : null) ?? 'Admin';

        StockMutationType type = StockMutationType.restock;
        if (typeStr.toLowerCase().contains('out') || typeStr.toLowerCase().contains('jual')) {
          type = StockMutationType.sale;
        } else if (typeStr.toLowerCase().contains('rusak')) {
          type = StockMutationType.damaged;
        } else if (typeStr.toLowerCase().contains('koreksi')) {
          type = StockMutationType.auditCorrection;
        }

        mutations.add(
          StockMutation(
            id: id,
            productId: productId,
            productName: productName,
            type: type,
            qtyChange: qty,
            previousStock: prevStock,
            newStock: newStock,
            timestamp: timestamp,
            note: notes,
            cashierName: cashier,
          ),
        );
      }
    }
    return mutations;
  }

  /// 7. Muat Profil Toko dari Google Spreadsheet
  Future<StoreProfile?> fetchStoreProfile(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Profil_Toko');
    if (rows == null || rows.isEmpty) return null;

    final row = rows.first;
    if (row.isNotEmpty) {
      final name = row[0]?.toString() ?? 'Bherung';
      final tagline = (row.length > 1 ? row[1]?.toString() : null) ?? '24 JAM';
      final defaultCash = (row.length > 2 && row[2] is num)
          ? (row[2] as num).toDouble()
          : (double.tryParse(row.length > 2 ? row[2]?.toString() ?? '200000' : '200000') ?? 200000.0);
      final qrisName = row.length > 3 ? row[3]?.toString() : null;
      final qrisNmid = row.length > 4 ? row[4]?.toString() : null;

      final List<BankAccount> banks = [];
      if (row.length > 5 && row[5] != null) {
        try {
          final decoded = jsonDecode(row[5].toString());
          if (decoded is List) {
            for (final b in decoded) {
              if (b is Map<String, dynamic>) {
                banks.add(BankAccount.fromJson(b));
              }
            }
          }
        } catch (_) {}
      }

      return StoreProfile(
        name: name,
        tagline: tagline,
        defaultStartingCash: defaultCash,
        qrisName: qrisName ?? '',
        qrisNmid: qrisNmid ?? '',
        bankAccounts: banks,
      );
    }
    return null;
  }

  /// 8. Muat Daftar Cabang Toko dari Google Spreadsheet
  Future<List<Branch>?> fetchBranches(String spreadsheetId) async {
    final rows = await _fetchSheetRowsGviz(spreadsheetId, 'Daftar_Cabang');
    if (rows == null || rows.isEmpty) return null;

    final List<Branch> branches = [];
    for (final row in rows) {
      if (row.isNotEmpty && row[0] != null) {
        final id = row[0].toString();
        final name = (row.length > 1 ? row[1]?.toString() : null) ?? 'Cabang';
        final code = (row.length > 2 ? row[2]?.toString() : null) ?? '';
        final address = (row.length > 3 ? row[3]?.toString() : null) ?? '';
        final phone = (row.length > 4 ? row[4]?.toString() : null) ?? '';
        final isMainStr = (row.length > 5 ? row[5]?.toString() : '') ?? '';
        final statusStr = (row.length > 6 ? row[6]?.toString() : '') ?? '';

        final isMain = isMainStr.toLowerCase() == 'true' || isMainStr == '1';
        final isActive = !statusStr.toLowerCase().contains('nonaktif') && statusStr.toLowerCase() != 'false';

        branches.add(
          Branch(
            id: id,
            name: name,
            code: code,
            address: address,
            phone: phone,
            isMain: isMain,
            isActive: isActive,
          ),
        );
      }
    }
    return branches.isNotEmpty ? branches : null;
  }
}
