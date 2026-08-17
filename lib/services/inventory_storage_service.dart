import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/store_profile.dart';

class InventoryStorageService {
  static final InventoryStorageService _instance = InventoryStorageService._internal();
  factory InventoryStorageService() => _instance;
  InventoryStorageService._internal();

  static const String _keyProducts = 'bherung_products_json_v1';
  static const String _keyMutations = 'bherung_mutations_json_v1';
  static const String _keyShifts = 'bherung_shifts_json_v1';
  static const String _keyUsers = 'bherung_users_json_v1';
  static const String _keyKasbon = 'bherung_kasbon_json_v1';
  static const String _keyStoreProfile = 'bherung_store_profile_json_v1';

  // 1. Load Products (Persistent Local Storage)
  Future<List<Product>> loadProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyProducts);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final List<Product> list = decoded.map((item) => Product.fromJson(item as Map<String, dynamic>)).toList();
        return list;
      }
    } catch (e) {
      debugPrint('Error loading products from local storage: $e');
    }

    // Default keadaan awal: bersih (kosong). Master katalog resmi ditarik dari Google Spreadsheet toko.
    return [];
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

    // Fallback default: Pemilik Toko (PIN 1234) & Penjaga Toko (PIN 5678)
    final defaultUsers = [
      const AppUser(
        id: 'usr-owner',
        name: 'Pemilik Toko (Owner)',
        phone: '',
        role: UserRoleType.owner,
        pin: '1234',
        isActive: true,
      ),
      const AppUser(
        id: 'usr-staff',
        name: 'Penjaga Toko (Kasir)',
        phone: '',
        role: UserRoleType.staff,
        pin: '5678',
        isActive: true,
      ),
    ];
    await saveUsers(defaultUsers);
    return defaultUsers;
  }

  Future<AppUser?> findUserByPin(String pin) async {
    final users = await loadUsers();
    final clean = pin.trim();
    for (final u in users) {
      if (u.isActive && u.pin.trim() == clean) {
        return u;
      }
    }
    return null;
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

  // 4b. Next Scheduled Cashier for Lock Screen ("Silahkan masuk Tretan...")
  static const String _keyScheduledNextUser = 'bherung_scheduled_next_user';

  Future<void> saveScheduledNextUser(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyScheduledNextUser, jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Error saving scheduled next user: $e');
    }
  }

  Future<AppUser?> loadScheduledNextUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_keyScheduledNextUser);
      if (str != null && str.isNotEmpty) {
        return AppUser.fromJson(jsonDecode(str) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error loading scheduled next user: $e');
    }
    return null;
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

    return [];
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

  // 6. Load & Save Store Profile
  Future<StoreProfile> loadStoreProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_keyStoreProfile);

      if (jsonStr != null && jsonStr.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is Map<String, dynamic>) {
          return StoreProfile.fromJson(decoded);
        }
      }
    } catch (e) {
      debugPrint('Error loading store profile: $e');
    }

    return const StoreProfile();
  }

  Future<void> saveStoreProfile(StoreProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyStoreProfile, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Error saving store profile: $e');
    }
  }

  // Muat data produk demo / uji coba secara eksplisit
  Future<List<Product>> loadDemoProducts() async {
    final demoList = List<Product>.from(sampleProducts);
    await saveProducts(demoList);
    return demoList;
  }

  // Kosongkan seluruh produk lokal
  Future<void> clearAllProducts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
  }

  // Reset total data lokal toko (produk, mutasi, shift, kasbon)
  Future<void> resetAllStoreData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyProducts);
    await prefs.remove(_keyMutations);
    await prefs.remove(_keyShifts);
    await prefs.remove(_keyKasbon);
  }
}
