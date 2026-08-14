import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';

class InventoryStorageService {
  static final InventoryStorageService _instance = InventoryStorageService._internal();
  factory InventoryStorageService() => _instance;
  InventoryStorageService._internal();

  static const String _keyProducts = 'bherung_products_json_v1';
  static const String _keyMutations = 'bherung_mutations_json_v1';
  static const String _keyShifts = 'bherung_shifts_json_v1';
  static const String _keyUsers = 'bherung_users_json_v1';
  static const String _keyKasbon = 'bherung_kasbon_json_v1';

  // 1. Load Products (Persistent Local Storage)
  Future<List<Product>> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyProducts);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<Product> list = decoded.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (e) {
      debugPrint('Error loading products from local storage: $e');
    }

    // Default: Starter Template
    final initialList = List<Product>.from(sampleProducts);
    await saveProducts(initialList);
    return initialList;
  }

  // Save Products
  Future<void> saveProducts(List<Product> products) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = products.map((p) => p.toJson()).toList();
      await prefs.setString(_keyProducts, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving products to local storage: $e');
    }
  }

  // 2. Load & Save Mutations (Kartu Stok)
  Future<List<StockMutation>> loadMutations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyMutations);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((item) => StockMutation.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading mutations from storage: $e');
    }
    return [];
  }

  Future<void> saveMutations(List<StockMutation> mutations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = mutations.take(200).map((m) => m.toJson()).toList(); // keep latest 200
      await prefs.setString(_keyMutations, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving mutations: $e');
    }
  }

  // 3. Load & Save Shift Records
  Future<List<ShiftRecord>> loadShifts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyShifts);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((item) => ShiftRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading shifts from storage: $e');
    }
    return [];
  }

  Future<void> saveShifts(List<ShiftRecord> shifts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = shifts.map((s) => s.toJson()).toList();
      await prefs.setString(_keyShifts, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving shifts: $e');
    }
  }

  // 4. Load & Save Users
  Future<List<AppUser>> loadUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyUsers);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final list = decoded.map((item) => AppUser.fromJson(item as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }

    // Default users
    final defaultUsers = [
      const AppUser(
        id: 'usr-01',
        name: 'Pak Haji Samsul',
        phone: '0812-9988-7766',
        role: UserRoleType.owner,
        pin: '1234',
      ),
      const AppUser(
        id: 'usr-02',
        name: 'Ahmad (Kasir)',
        phone: '0857-1122-3344',
        role: UserRoleType.staff,
        pin: '1111',
      ),
      const AppUser(
        id: 'usr-03',
        name: 'Hasan (Shift Malam)',
        phone: '0878-5566-7788',
        role: UserRoleType.staff,
        pin: '2222',
      ),
    ];
    await saveUsers(defaultUsers);
    return defaultUsers;
  }

  Future<void> saveUsers(List<AppUser> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = users.map((u) => u.toJson()).toList();
      await prefs.setString(_keyUsers, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving users: $e');
    }
  }

  // 5. Load & Save Kasbon
  Future<List<KasbonRecord>> loadKasbon() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyKasbon);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((item) => KasbonRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading kasbon: $e');
    }

    return [
      KasbonRecord(
        id: 'KSB-01',
        customerName: 'Pak Haji Samsul (RT 03)',
        customerPhone: '0812-3344-5566',
        amount: 145000,
        items: [
          CartItem(product: sampleProducts[0], quantity: 1),
          CartItem(product: sampleProducts[2], quantity: 2),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        dueDate: DateTime.now().add(const Duration(days: 4)),
        isPaid: false,
      ),
      KasbonRecord(
        id: 'KSB-02',
        customerName: 'Bu Rini Warung Sebelah',
        customerPhone: '0857-9988-1122',
        amount: 85000,
        items: [
          CartItem(product: sampleProducts[4], quantity: 2),
          CartItem(product: sampleProducts[7], quantity: 8),
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        dueDate: DateTime.now().add(const Duration(days: 6)),
        isPaid: false,
      ),
    ];
  }

  Future<void> saveKasbon(List<KasbonRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = records.map((k) => k.toJson()).toList();
      await prefs.setString(_keyKasbon, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving kasbon: $e');
    }
  }

  // Reset to default sample starter template
  Future<List<Product>> resetToDefaultProducts() async {
    final defaultList = List<Product>.from(sampleProducts);
    await saveProducts(defaultList);
    return defaultList;
  }
}
