import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../services/apps_script_service.dart';
import '../services/inventory_storage_service.dart';
import '../services/barcode_master_lookup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/header_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/product_catalog_view.dart';
import '../widgets/cart_sidebar.dart';
import '../widgets/mobile_bottom_nav.dart';
import 'stock_control_screen.dart';
import 'shift_handover_screen.dart';
import 'quick_add_product_screen.dart';
import 'app_menu_screen.dart';
import 'settings_screen.dart';
import 'scanner_screen.dart';
import 'payment_screen.dart';
import 'role_switcher_screen.dart';
import 'restock_screen.dart';
import 'kasbon_screen.dart';
import 'held_orders_screen.dart';
import 'user_guide_screen.dart';

class PosDashboardScreen extends StatefulWidget {
  const PosDashboardScreen({super.key});

  @override
  State<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends State<PosDashboardScreen> {
  String _selectedCategoryId = 'all';
  String _searchQuery = '';
  bool _isListView = false;
  TransactionType _selectedTransactionType = TransactionType.eceran;
  String _customerName = '';
  double _discountPercent = 0;
  bool _isLoadingData = true;

  // Real-Time Persisted Products List
  List<Product> _products = [];

  // Real-Time Stock Mutations Log
  List<StockMutation> _stockMutations = [];

  // Shift Records Log
  List<ShiftRecord> _shiftRecords = [];

  // User Accounts (Owner vs Penjaga Toko)
  List<AppUser> _users = [];
  late AppUser _currentUser;

  final List<Category> _categories = List.from(sampleCategories);
  final List<CartItem> _cartItems = [];
  final List<HeldOrder> _heldOrders = [];
  List<KasbonRecord> _kasbonRecords = [];

  // Store Profile Info
  StoreProfile _storeProfile = const StoreProfile();
  String _storeName = 'Bherung';
  String _storeTagline = '24 JAM';

  final TextEditingController _searchController = TextEditingController();

  // Live Clock
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now();

  // Current Shift Sales (Starts from 0 for fresh cashier shift)
  int _completedTransactions = 0;
  double _totalSalesToday = 0;

  @override
  void initState() {
    super.initState();
    _currentUser = const AppUser(
      id: 'usr-01',
      name: 'Kasir Toko',
      phone: '',
      role: UserRoleType.staff,
      pin: '1234',
    );
    _loadPersistedStorageData();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  Future<void> _loadPersistedStorageData() async {
    final storage = InventoryStorageService();
    final loadedProducts = await storage.loadProducts();
    final loadedMutations = await storage.loadMutations();
    final loadedShifts = await storage.loadShifts();
    final loadedUsers = await storage.loadUsers();
    final loadedKasbon = await storage.loadKasbon();
    final loadedProfile = await storage.loadStoreProfile();

    if (mounted) {
      setState(() {
        _products = loadedProducts;
        _stockMutations = loadedMutations;
        _shiftRecords = loadedShifts;
        _users = loadedUsers;
        _kasbonRecords = loadedKasbon;
        _storeProfile = loadedProfile;
        _storeName = loadedProfile.name;
        _storeTagline = loadedProfile.tagline;
        if (_users.isNotEmpty) {
          _currentUser = _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
        }
        _isLoadingData = false;
      });
    }

    // Ambil seluruh data sistem terbaru dari Google Spreadsheet jika terhubung
    if (AppsScriptService().isConnected) {
      final syncResult = await AppsScriptService().syncAllDataFromSpreadsheet();
      if (syncResult.success && mounted) {
        setState(() {
          if (syncResult.products != null && syncResult.products!.isNotEmpty) {
            _products = syncResult.products!;
            storage.saveProducts(_products);
          }
          if (syncResult.users != null && syncResult.users!.isNotEmpty) {
            _users = syncResult.users!;
            storage.saveUsers(_users);
            if (!_users.any((u) => u.id == _currentUser.id)) {
              _currentUser = _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
            }
          }
          if (syncResult.kasbon != null) {
            _kasbonRecords = syncResult.kasbon!;
            storage.saveKasbon(_kasbonRecords);
          }
          if (syncResult.shifts != null && syncResult.shifts!.isNotEmpty) {
            _shiftRecords = syncResult.shifts!;
            storage.saveShifts(_shiftRecords);
          }
          if (syncResult.mutations != null && syncResult.mutations!.isNotEmpty) {
            _stockMutations = syncResult.mutations!;
            storage.saveMutations(_stockMutations);
          }
          if (syncResult.storeProfile != null) {
            _storeProfile = syncResult.storeProfile!;
            _storeName = _storeProfile.name;
            _storeTagline = _storeProfile.tagline;
            storage.saveStoreProfile(_storeProfile);
          }
          if (syncResult.todaySales != null && syncResult.todaySales! > 0) {
            _totalSalesToday = syncResult.todaySales!;
            _completedTransactions = syncResult.todayTrxCount ?? _completedTransactions;
          }
        });
      }
    }
  }

  // Pull-to-Refresh: Sinkronisasi SELURUH DATA (Katalog, Stok, Kasbon, Pengguna, Shift, Mutasi, Profil Toko, Transaksi, & Antrean Offline)
  Future<void> _handlePullToRefresh() async {
    final appsScript = AppsScriptService();
    final storage = InventoryStorageService();

    if (appsScript.isConnected) {
      final syncResult = await appsScript.syncAllDataFromSpreadsheet();

      if (mounted) {
        if (syncResult.success) {
          setState(() {
            if (syncResult.products != null && syncResult.products!.isNotEmpty) {
              _products = syncResult.products!;
              storage.saveProducts(_products);
            }
            if (syncResult.users != null && syncResult.users!.isNotEmpty) {
              _users = syncResult.users!;
              storage.saveUsers(_users);
              if (!_users.any((u) => u.id == _currentUser.id)) {
                _currentUser = _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
              }
            }
            if (syncResult.kasbon != null) {
              _kasbonRecords = syncResult.kasbon!;
              storage.saveKasbon(_kasbonRecords);
            }
            if (syncResult.shifts != null && syncResult.shifts!.isNotEmpty) {
              _shiftRecords = syncResult.shifts!;
              storage.saveShifts(_shiftRecords);
            }
            if (syncResult.mutations != null && syncResult.mutations!.isNotEmpty) {
              _stockMutations = syncResult.mutations!;
              storage.saveMutations(_stockMutations);
            }
            if (syncResult.storeProfile != null) {
              _storeProfile = syncResult.storeProfile!;
              _storeName = _storeProfile.name;
              _storeTagline = _storeProfile.tagline;
              storage.saveStoreProfile(_storeProfile);
            }
            if (syncResult.todaySales != null && syncResult.todaySales! > 0) {
              _totalSalesToday = syncResult.todaySales!;
              _completedTransactions = syncResult.todayTrxCount ?? _completedTransactions;
            }
          });

          final String summaryInfo = [
            if (syncResult.products != null) '${syncResult.products!.length} produk',
            if (syncResult.kasbon != null) '${syncResult.kasbon!.length} kasbon',
            if (syncResult.users != null) '${syncResult.users!.length} user',
            if (syncResult.syncedOfflineCount > 0) '${syncResult.syncedOfflineCount} offline terkirim',
          ].join(' • ');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Seluruh data tersinkronisasi dengan Spreadsheet! ($summaryInfo)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryTeal,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(syncResult.message),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    } else {
      // Mode offline: muat ulang seluruh cache dari local storage
      await _loadPersistedStorageData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seluruh data lokal dimuat ulang (Mode Offline). Sambungkan Google Sheets di Pengaturan untuk sync otomatis.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF475569),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Filter products by category, search query, and in-stock only (p.stock > 0)
  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesCategory = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.code.toLowerCase().contains(_searchQuery.toLowerCase());
      final hasStock = p.stock > 0;
      return matchesCategory && matchesSearch && hasStock;
    }).toList();
  }

  int _getCartQuantity(String productId) {
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    return index != -1 ? _cartItems[index].quantity : 0;
  }

  void _addToCart(Product product) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (index != -1) {
        _cartItems[index].quantity++;
      } else {
        _cartItems.add(CartItem(
          product: product,
          quantity: 1,
          forceWholesalePrice: _selectedTransactionType == TransactionType.grosir,
        ));
      }
    });
  }

  void _incrementCart(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  void _decrementCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        _cartItems.remove(item);
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      _cartItems.remove(item);
    });
  }

  void _updateItemNote(CartItem item, String? note) {
    setState(() {
      item.note = note;
    });
  }

  void _toggleWholesale(CartItem item, bool forceWholesale) {
    setState(() {
      item.forceWholesalePrice = forceWholesale;
    });
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _customerName = '';
      _discountPercent = 0;
    });
  }

  // Handle barcode quick scan / enter key in search box / mobile camera scanner
  void _handleBarcodeSubmitted(String code) {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;

    final foundProduct = _products.where((p) => p.code.toLowerCase() == cleanCode.toLowerCase()).firstOrNull;
    if (foundProduct != null) {
      _addToCart(foundProduct);
      _searchController.clear();
      setState(() => _searchQuery = '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode [$cleanCode]: "${foundProduct.name}" ditambahkan ke keranjang.'),
          duration: const Duration(milliseconds: 1200),
          backgroundColor: AppTheme.primaryTeal,
        ),
      );
    } else {
      // Periksa apakah ada di Database Master Barcode Sembako / Rokok Indonesia
      final masterItem = BarcodeMasterLookupService().lookup(cleanCode);
      if (masterItem != null) {
        final foundCat = sampleCategories.where((c) => c.id == masterItem.categoryId).firstOrNull;
        final autoProduct = Product(
          id: 'prd-${DateTime.now().millisecondsSinceEpoch}',
          name: masterItem.name,
          price: masterItem.price,
          costPrice: masterItem.costPrice,
          unit: masterItem.unit,
          categoryId: masterItem.categoryId,
          icon: foundCat?.icon ?? Icons.inventory_2_rounded,
          color: foundCat?.color ?? AppTheme.primaryTeal,
          code: cleanCode,
          stock: 36,
          minStockAlert: 5,
          isSensitiveItem: masterItem.isSensitiveItem,
        );

        setState(() {
          _products.insert(0, autoProduct);
          _addToCart(autoProduct);
          _searchController.clear();
          _searchQuery = '';
        });
        InventoryStorageService().saveProducts(_products);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Otomatis Dikenali: "${autoProduct.name}" (${AppTheme.formatRupiah(autoProduct.price)}) langsung masuk keranjang!'),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Barcode baru belum terdaftar -> Buka Tambah Cepat Produk dengan nomor barcode terisi
        _showQuickAddProductDialog(initialBarcode: cleanCode);
      }
    }
  }

  // Camera Barcode Scanner Flow (Full Screen)
  void _openCameraBarcodeScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ScannerScreen(
          onBarcodeDetected: (barcode) {
            _handleBarcodeSubmitted(barcode);
          },
          onOpenQuickAdd: () {
            Navigator.pop(context);
            _showQuickAddProductDialog();
          },
        ),
      ),
    );
  }

  // Quick Add Product Screen (Full Screen)
  void _showQuickAddProductDialog({String? initialBarcode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => QuickAddProductScreen(
          barcode: initialBarcode ?? '',
          categories: _categories,
          onProductCreated: (newProduct) {
            setState(() {
              if (!_categories.any((c) => c.id == newProduct.categoryId)) {
                _categories.add(Category(
                  id: newProduct.categoryId,
                  name: newProduct.categoryId.replaceAll('_', ' ').toUpperCase(),
                  icon: newProduct.icon,
                  color: newProduct.color,
                ));
              }
              _products.insert(0, newProduct);
              _addToCart(newProduct); // Langsung masuk keranjang agar kasir kilat
            });

            // Catat mutasi stok awal
            final mutation = StockMutation(
              id: 'MUT-${DateTime.now().millisecondsSinceEpoch}',
              productId: newProduct.id,
              productName: newProduct.name,
              type: StockMutationType.restock,
              qtyChange: newProduct.stock,
              previousStock: 0,
              newStock: newProduct.stock,
              timestamp: DateTime.now(),
              note: 'Pendaftaran Cepat Barcode Baru',
              cashierName: _currentUser.name,
              costPrice: newProduct.costPrice,
            );
            _stockMutations.insert(0, mutation);

            // Simpan ke local storage secara permanen
            InventoryStorageService().saveProducts(_products);
            InventoryStorageService().saveMutations(_stockMutations);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Produk "${newProduct.name}" berhasil didaftarkan dan tersimpan permanen.'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
        ),
      ),
    );
  }

  // Restock / Kulakan Screen (Full Screen)
  void _showRestockDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RestockScreen(
          products: _products,
          onRestockCompleted: (updatedProduct, mutation) {
            setState(() {
              final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
              if (idx != -1) {
                _products[idx] = updatedProduct;
              }
              _stockMutations.insert(0, mutation);
            });

            // Simpan ke storage lokal permanen
            InventoryStorageService().saveProducts(_products);
            InventoryStorageService().saveMutations(_stockMutations);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stok "${updatedProduct.name}" bertambah menjadi ${updatedProduct.stock} ${updatedProduct.unit}.'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
        ),
      ),
    );
  }

  // Kontrol Stok, Slow-Moving & Expired Screen (Full Screen)
  void _showStockControlDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StockControlScreen(
          products: _products,
          mutations: _stockMutations,
          onOpenRestock: _showRestockDialog,
        ),
      ),
    );
  }

  // Serah Terima Shift Penjaga & Rekonsiliasi Kas (Full Screen Terintegrasi)
  void _showShiftHandoverDialog([AppUser? initialIncomingUser]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ShiftHandoverScreen(
          currentCashier: _currentUser.name,
          currentShiftSales: _totalSalesToday,
          currentShiftTransactions: _completedTransactions,
          products: _products,
          users: _users,
          initialIncomingUser: initialIncomingUser,
          defaultStartingCash: _storeProfile.defaultStartingCash,
          storeName: _storeProfile.name,
          onShiftHandoverCompleted: (shiftRecord, nextUser) {
            setState(() {
              _shiftRecords.insert(0, shiftRecord);
              // Reset shift counter untuk penjaga shift berikutnya
              _completedTransactions = 0;
              _totalSalesToday = 0;
              if (nextUser != null) {
                _currentUser = nextUser;
              }
            });

            // Simpan rekap shift ke storage lokal
            InventoryStorageService().saveShifts(_shiftRecords);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Serah terima shift berhasil! Shift beralih ke: ${_currentUser.name} (Selisih: ${AppTheme.formatRupiah(shiftRecord.cashDifference)})',
                ),
                backgroundColor: shiftRecord.cashDifference == 0 ? AppTheme.successGreen : AppTheme.warningOrange,
                duration: const Duration(seconds: 4),
              ),
            );
          },
        ),
      ),
    );
  }

  // Role & User Account Switcher (Full Screen Terintegrasi Oper Shift & GAS Cloud)
  void _showRoleSwitcherDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => RoleSwitcherScreen(
          currentUser: _currentUser,
          users: _users,
          currentShiftSales: _totalSalesToday,
          currentShiftTransactions: _completedTransactions,
          onStartShiftHandover: (targetUser) {
            _showShiftHandoverDialog(targetUser);
          },
          onUserSelected: (user) {
            setState(() => _currentUser = user);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Beralih ke akun: ${user.name} (${user.isOwner ? "Owner" : "Kasir"})'),
                backgroundColor: AppTheme.primaryGold,
              ),
            );
          },
          onUserAdded: (newUser) {
            setState(() => _users.add(newUser));
            InventoryStorageService().saveUsers(_users);
            if (AppsScriptService().isConnected) {
              AppsScriptService().syncAllUsers(_users);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akun penjaga baru "${newUser.name}" berhasil ditambahkan & tersimpan.'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
          onUserUpdated: (updatedUser) {
            setState(() {
              final idx = _users.indexWhere((u) => u.id == updatedUser.id);
              if (idx != -1) {
                _users[idx] = updatedUser;
              }
              if (_currentUser.id == updatedUser.id) {
                _currentUser = updatedUser;
              }
            });
            InventoryStorageService().saveUsers(_users);
            if (AppsScriptService().isConnected) {
              AppsScriptService().syncAllUsers(_users);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Data akun "${updatedUser.name}" berhasil diperbarui.'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
          onUserDeleted: (deletedUser) {
            setState(() {
              _users.removeWhere((u) => u.id == deletedUser.id);
            });
            InventoryStorageService().saveUsers(_users);
            if (AppsScriptService().isConnected) {
              AppsScriptService().syncAllUsers(_users);
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Akun "${deletedUser.name}" telah dihapus.'),
                backgroundColor: AppTheme.warningOrange,
              ),
            );
          },
          onUsersSynced: (syncedUsers) {
            setState(() {
              _users = syncedUsers;
              if (!_users.any((u) => u.id == _currentUser.id)) {
                _currentUser = _users.first;
              }
            });
            InventoryStorageService().saveUsers(_users);
          },
        ),
      ),
    );
  }

  // Hold Order Feature
  void _holdCurrentOrder() {
    if (_cartItems.isEmpty) return;

    final String name = _customerName.trim().isEmpty ? 'Pelanggan #${_heldOrders.length + 1}' : _customerName.trim();
    final newHeld = HeldOrder(
      id: 'HOLD-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      customerName: name,
      transactionType: _selectedTransactionType,
      items: List<CartItem>.from(_cartItems.map((e) => e.copyWith())),
      createdAt: DateTime.now(),
    );

    setState(() {
      _heldOrders.add(newHeld);
      _cartItems.clear();
      _customerName = '';
      _discountPercent = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nota "$name" berhasil disimpan/ditahan.'),
        backgroundColor: AppTheme.warningOrange,
        action: SnackBarAction(
          label: 'Buka',
          textColor: Colors.white,
          onPressed: _showHeldOrdersDialog,
        ),
      ),
    );
  }

  void _restoreHeldOrder(HeldOrder order) {
    setState(() {
      _cartItems.clear();
      _cartItems.addAll(order.items.map((e) => e.copyWith()));
      _customerName = order.customerName;
      _selectedTransactionType = order.transactionType;
      _heldOrders.remove(order);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nota "${order.customerName}" dimuat kembali ke keranjang.'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
  }

  // Daftar Nota Ditahan (Full Screen)
  void _showHeldOrdersDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => HeldOrdersScreen(
          heldOrders: _heldOrders,
          onRestoreOrder: (order) => _restoreHeldOrder(order),
          onDeleteOrder: (order) {
            setState(() => _heldOrders.remove(order));
          },
        ),
      ),
    );
  }

  // Buku Kasbon Pelanggan (Full Screen)
  void _showBukuKasbonDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => KasbonScreen(
          kasbonRecords: _kasbonRecords,
          onKasbonPaid: (kasbon) {
            setState(() {
              _totalSalesToday += kasbon.amount;
            });
            InventoryStorageService().saveKasbon(_kasbonRecords);
          },
        ),
      ),
    );
  }

  // Pengaturan & Cloud Sync Screen (Full Screen)
  void _showSettingsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => SettingsScreen(
          products: _products,
          storeName: _storeName,
          storeProfile: _storeProfile,
          onStoreNameChanged: (newName) {
            setState(() => _storeName = newName);
          },
          onStoreProfileChanged: (newProfile) {
            setState(() {
              _storeProfile = newProfile;
              _storeName = newProfile.name;
              _storeTagline = newProfile.tagline;
            });
          },
          onDataChanged: () => setState(() {}),
        ),
      ),
    );
  }

  // Buku Panduan Kasir & Toko (Full Screen)
  void _showUserGuideDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const UserGuideScreen(),
      ),
    );
  }

  // Kasir Pembayaran & Kasbon (Full Screen)
  void _openCheckoutDialog() {
    final double subtotal = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    final double discount = subtotal * (_discountPercent / 100);
    final double total = subtotal - discount;
    final String trxId = 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: total,
          subtotal: subtotal,
          discountAmount: discount,
          cartItems: _cartItems,
          transactionType: _selectedTransactionType,
          customerName: _customerName,
          storeProfile: _storeProfile,
          onSuccess: ({required bool isKasbon, String? customerName, String? customerPhone, DateTime? dueDate}) {
            final itemsCopy = List<CartItem>.from(_cartItems.map((e) => e.copyWith()));
          final finalCustName = customerName ?? (_customerName.isNotEmpty ? _customerName : 'Umum');

          setState(() {
            _completedTransactions++;

            // 1. Pengurangan Stok Otomatis & Catat Mutasi Penjualan
            for (final cartItem in itemsCopy) {
              final pIdx = _products.indexWhere((p) => p.id == cartItem.product.id);
              if (pIdx != -1) {
                final currentProd = _products[pIdx];
                final newStock = (currentProd.stock - cartItem.quantity).clamp(0, 99999);
                _products[pIdx] = currentProd.copyWith(
                  stock: newStock,
                  lastSoldDate: DateTime.now(),
                );

                _stockMutations.insert(
                  0,
                  StockMutation(
                    id: 'MUT-${DateTime.now().millisecondsSinceEpoch}-${cartItem.product.id}',
                    productId: currentProd.id,
                    productName: currentProd.name,
                    type: StockMutationType.sale,
                    qtyChange: -cartItem.quantity,
                    previousStock: currentProd.stock,
                    newStock: newStock,
                    timestamp: DateTime.now(),
                    note: 'Transaksi Kasir $trxId ($finalCustName)',
                    cashierName: _currentUser.name,
                  ),
                );
              }
            }

            // 2. Catat Rekap Penjualan
            if (!isKasbon) {
              _totalSalesToday += total;
              // Kirim transaksi ke Spreadsheet di background
              AppsScriptService().sendTransaction(
                id: trxId,
                type: _selectedTransactionType,
                customerName: finalCustName,
                subtotal: subtotal,
                discountAmount: discount,
                totalAmount: total,
                paymentMethod: 'Tunai / QRIS',
                cashierName: _currentUser.name,
                items: itemsCopy,
              );
            } else {
              final kasbonId = 'KSB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
              _kasbonRecords.insert(
                0,
                KasbonRecord(
                  id: kasbonId,
                  customerName: finalCustName,
                  customerPhone: customerPhone ?? '',
                  amount: total,
                  items: itemsCopy,
                  createdAt: DateTime.now(),
                  dueDate: dueDate,
                  isPaid: false,
                ),
              );

              // Kirim Kasbon ke Spreadsheet di background
              AppsScriptService().sendKasbon(
                id: kasbonId,
                customerName: finalCustName,
                customerPhone: customerPhone ?? '',
                amount: total,
                dueDate: dueDate,
                items: itemsCopy,
              );
            }

            // 3. Simpan mutasi stok, produk dan kasbon ke penyimpanan lokal
            InventoryStorageService().saveProducts(_products);
            InventoryStorageService().saveMutations(_stockMutations);
            if (isKasbon) {
              InventoryStorageService().saveKasbon(_kasbonRecords);
            }
          });
          _clearCart();
        },
      ),
    ),
  );
}

  // Full-Screen Menu Toko & Pengaturan
  void _openAppMenuScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AppMenuScreen(
          storeName: _storeName,
          storeTagline: _storeTagline,
          currentTime: _currentTime,
          completedTransactions: _completedTransactions,
          totalSalesToday: _totalSalesToday,
          activeKasbonCount: _kasbonRecords.where((k) => !k.isPaid).length,
          heldOrdersCount: _heldOrders.length,
          currentUser: _currentUser,
          onOpenKasbon: _showBukuKasbonDialog,
          onOpenHeldOrders: _showHeldOrdersDialog,
          onOpenSettings: _showSettingsDialog,
          onOpenGuide: _showUserGuideDialog,
          onOpenShiftHandover: _showShiftHandoverDialog,
          onOpenStockControl: _showStockControlDashboard,
          onOpenRestock: _showRestockDialog,
          onOpenRoleSwitcher: _showRoleSwitcherDialog,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth >= 900;
    final int totalCartCount = _cartItems.fold(0, (sum, item) => sum + item.quantity);
    final double subtotal = _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    final double discount = subtotal * (_discountPercent / 100);
    final double total = subtotal - discount;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header Bar (Modular Component with Role, Shift & Stock Control)
            PosHeaderBar(
              storeName: _storeName,
              storeTagline: _storeTagline,
              currentTime: _currentTime,
              completedTransactions: _completedTransactions,
              totalSalesToday: _totalSalesToday,
              activeKasbonCount: _kasbonRecords.where((k) => !k.isPaid).length,
              heldOrdersCount: _heldOrders.length,
              currentUser: _currentUser,
              onOpenKasbon: _showBukuKasbonDialog,
              onOpenHeldOrders: _showHeldOrdersDialog,
              onOpenSettings: _showSettingsDialog,
              onOpenGuide: _showUserGuideDialog,
              onOpenShiftHandover: _showShiftHandoverDialog,
              onOpenStockControl: _showStockControlDashboard,
              onOpenRestock: _showRestockDialog,
              onOpenRoleSwitcher: _showRoleSwitcherDialog,
              onOpenDrawer: _openAppMenuScreen,
            ),

            // 2. Main Content Area (Catalog + Cart Sidebar)
            Expanded(
              child: Row(
                children: [
                  // Left Side: Search, Scan HP, Categories & Sembako Catalog
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search, Scan Barcode HP & Filter Bar (Modular Component)
                        SearchFilterBar(
                          searchController: _searchController,
                          searchQuery: _searchQuery,
                          selectedCategoryId: _selectedCategoryId,
                          isListView: _isListView,
                          categories: _categories,
                          allProducts: _products,
                          onSearchChanged: (val) => setState(() => _searchQuery = val),
                          onBarcodeSubmitted: _handleBarcodeSubmitted,
                          onCategorySelected: (catId) => setState(() => _selectedCategoryId = catId),
                          onViewModeChanged: (isList) => setState(() => _isListView = isList),
                          onOpenScanner: _openCameraBarcodeScanner,
                          onOpenQuickAdd: () => _showQuickAddProductDialog(),
                        ),

                        // Catalog Products (Modular Component)
                        Expanded(
                          child: _isLoadingData
                              ? const Center(
                                  child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                                )
                              : ProductCatalogView(
                                  filteredProducts: _filteredProducts,
                                  totalStoreProducts: _products.length,
                                  isListView: _isListView,
                                  getCartQuantity: _getCartQuantity,
                                  onAddToCart: _addToCart,
                                  onIncrement: (p) {
                                    final item = _cartItems.firstWhere((i) => i.product.id == p.id);
                                    _incrementCart(item);
                                  },
                                  onDecrement: (p) {
                                    final item = _cartItems.firstWhere((i) => i.product.id == p.id);
                                    _decrementCart(item);
                                  },
                                  onResetSearch: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _selectedCategoryId = 'all';
                                    });
                                  },
                                  onRefresh: _handlePullToRefresh,
                                  onOpenSettings: _showSettingsDialog,
                                  onQuickAdd: () => _showQuickAddProductDialog(),
                                ),
                        ),
                        // Quick Cart Bar on mobile inside body (Above Bottom Bar, not pushing FAB)
                        if (!isWideScreen && _cartItems.isNotEmpty)
                          Material(
                            color: AppTheme.primaryTeal,
                            elevation: 4,
                            child: InkWell(
                              onTap: () => _showMobileCartBottomSheet(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$totalCartCount',
                                        style: const TextStyle(
                                          color: AppTheme.primaryDark,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Lihat Keranjang',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    const Spacer(),
                                    Text(
                                      AppTheme.formatRupiah(total),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0F172A),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'BAYAR',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 10.5,
                                            ),
                                          ),
                                          SizedBox(width: 2),
                                          Icon(Icons.arrow_forward_rounded, size: 11, color: Colors.white),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Right Side: Permanent Cart Panel for Desktop/Tablet
                  if (isWideScreen)
                    SizedBox(
                      width: 345,
                      child: CartSidebar(
                        cartItems: _cartItems,
                        onIncrement: _incrementCart,
                        onDecrement: _decrementCart,
                        onRemove: _removeFromCart,
                        onUpdateNote: _updateItemNote,
                        onToggleWholesale: _toggleWholesale,
                        onClearCart: _clearCart,
                        onHoldOrder: _holdCurrentOrder,
                        onCheckout: _openCheckoutDialog,
                        transactionType: _selectedTransactionType,
                        onTransactionTypeChanged: (type) => setState(() => _selectedTransactionType = type),
                        customerName: _customerName,
                        onCustomerNameChanged: (val) => setState(() => _customerName = val),
                        discountPercent: _discountPercent,
                        onDiscountChanged: (val) => setState(() => _discountPercent = val),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Curved Notch Floating Center Scan Button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: !isWideScreen
          ? NotchedCenterFloatingButton(onPressed: _openCameraBarcodeScanner)
          : null,

      // Mobile / Tablet Curved Notched Bottom Navigation Bar
      bottomNavigationBar: !isWideScreen
          ? CurvedNotchedBottomBar(
              activeKasbonCount: _kasbonRecords.where((k) => !k.isPaid).length,
              heldOrdersCount: _heldOrders.length,
              currentUser: _currentUser,
              onOpenScanner: _openCameraBarcodeScanner,
              onOpenStockControl: _showStockControlDashboard,
              onOpenShiftHandover: _showShiftHandoverDialog,
              onOpenKasbon: _showBukuKasbonDialog,
              onOpenRoleSwitcher: _showRoleSwitcherDialog,
              onOpenSettings: _showSettingsDialog,
            )
          : null,
    );
  }

  void _showMobileCartBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: CartSidebar(
              cartItems: _cartItems,
              onIncrement: (item) {
                _incrementCart(item);
                setSheetState(() {});
              },
              onDecrement: (item) {
                _decrementCart(item);
                setSheetState(() {});
              },
              onRemove: (item) {
                _removeFromCart(item);
                setSheetState(() {});
              },
              onUpdateNote: (item, note) {
                _updateItemNote(item, note);
                setSheetState(() {});
              },
              onToggleWholesale: (item, forceWholesale) {
                _toggleWholesale(item, forceWholesale);
                setSheetState(() {});
              },
              onClearCart: () {
                _clearCart();
                setSheetState(() {});
              },
              onHoldOrder: () {
                Navigator.pop(context);
                _holdCurrentOrder();
              },
              onCheckout: () {
                Navigator.pop(context);
                _openCheckoutDialog();
              },
              transactionType: _selectedTransactionType,
              onTransactionTypeChanged: (type) {
                setState(() => _selectedTransactionType = type);
                setSheetState(() {});
              },
              customerName: _customerName,
              onCustomerNameChanged: (val) {
                setState(() => _customerName = val);
                setSheetState(() {});
              },
              discountPercent: _discountPercent,
              onDiscountChanged: (val) {
                setState(() => _discountPercent = val);
                setSheetState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
