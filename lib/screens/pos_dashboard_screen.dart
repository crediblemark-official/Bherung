import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../services/apps_script_service.dart';
import '../services/google_sheets_direct_service.dart';
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
import 'pin_login_lock_screen.dart';

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
  double _deliveryFee = 0;
  bool _isLoadingData = true;
  bool _isLocked = true; // Layar terkunci secara default dengan sambutan Tretan
  AppUser? _scheduledNextUser;

  // Real-Time Persisted Products List
  List<Product> _products = [];

  // Real-Time Stock Mutations Log
  List<StockMutation> _stockMutations = [];

  // Shift Records Log
  List<ShiftRecord> _shiftRecords = [];

  // User Accounts (Owner vs Penjaga Toko)
  List<AppUser> _users = [];
  late AppUser _currentUser;

  List<Category> get _categories => Category.buildDynamicCategories(_products);
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
    final loadedScheduled = await storage.loadScheduledNextUser();

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
        _scheduledNextUser = loadedScheduled;
        if (_users.isNotEmpty) {
          _currentUser = loadedScheduled ?? _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
        }
        _isLoadingData = false;
      });
    }

    // Direct Google Sheets OAuth Sync
    if (GoogleSheetsDirectService().isSignedIn) {
      try {
        final gProducts = await GoogleSheetsDirectService().fetchProducts();
        final gUsers = await GoogleSheetsDirectService().fetchUsers();
        if (mounted) {
          setState(() {
            if (gProducts != null && gProducts.isNotEmpty) {
              _products = gProducts;
              storage.saveProducts(_products);
            }
            if (gUsers != null && gUsers.isNotEmpty) {
              _users = gUsers;
              storage.saveUsers(_users);
            }
          });
        }
      } catch (e) {
        debugPrint('Direct Google Sheets sync error: $e');
      }
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

    if (GoogleSheetsDirectService().isSignedIn) {
      final gProducts = await GoogleSheetsDirectService().fetchProducts();
      final gUsers = await GoogleSheetsDirectService().fetchUsers();
      if (mounted) {
        setState(() {
          if (gProducts != null && gProducts.isNotEmpty) {
            _products = gProducts;
            storage.saveProducts(_products);
          }
          if (gUsers != null && gUsers.isNotEmpty) {
            _users = gUsers;
            storage.saveUsers(_users);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinkronisasi Google Drive Berhasil! (${_products.length} Produk • ${_users.length} User Kasir)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
      return;
    }

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
          transactionType: _selectedTransactionType,
        ));
      }
    });
  }

  void _onTransactionTypeChanged(TransactionType type) {
    setState(() {
      _selectedTransactionType = type;
      for (var item in _cartItems) {
        item.transactionType = type;
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
      _deliveryFee = 0;
    });
  }

  void _setCartQuantity(Product product, int quantity) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (quantity <= 0) {
        if (index != -1) {
          _cartItems.removeAt(index);
        }
      } else {
        if (index != -1) {
          _cartItems[index].quantity = quantity;
        } else {
          _cartItems.add(CartItem(
            product: product,
            quantity: quantity,
            forceWholesalePrice: _selectedTransactionType == TransactionType.grosir,
          ));
        }
      }
    });
  }

  // Dialog Cepat: Ubah Jumlah / Batal Hapus dari Keranjang / Pilih Grosir
  void _showProductQuantityDialog(Product product) {
    final cartItem = _cartItems.where((i) => i.product.id == product.id).firstOrNull;
    final int initialQty = cartItem?.quantity ?? 1;
    final TextEditingController qtyCtrl = TextEditingController(text: '$initialQty');
    bool forceWholesale = cartItem?.forceWholesalePrice ?? (_selectedTransactionType == TransactionType.grosir);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final int parsedQty = int.tryParse(qtyCtrl.text) ?? 1;
          final bool isWholesaleApplicable = forceWholesale ||
              (product.hasWholesale && parsedQty >= (product.wholesaleMinQty ?? 999999));
          final double unitPrice = isWholesaleApplicable && product.hasWholesale
              ? product.wholesalePrice!
              : product.price;
          final double subtotal = unitPrice * parsedQty;

          void updateQty(int newQty) {
            final validQty = newQty.clamp(1, product.stock > 0 ? product.stock : 9999);
            qtyCtrl.text = '$validQty';
            setDialogState(() {});
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            title: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: product.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(product.icon, color: product.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            'Stok: ${product.stock} ${product.unit}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: product.stock <= 5 ? AppTheme.dangerRed : AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ${AppTheme.formatRupiah(product.price)}/${product.unit}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.goldMuted, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 16),

                  // Stepper Jumlah Besar & Input Angka Langsung
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Minus Button
                      Material(
                        color: AppTheme.bgSubtle,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => updateQty(parsedQty - 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.remove_rounded, color: AppTheme.primaryDark, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Direct Quantity Input Field
                      SizedBox(
                        width: 90,
                        height: 44,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppTheme.primaryGold, width: 2),
                            ),
                          ),
                          onChanged: (val) => setDialogState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Plus Button
                      Material(
                        color: AppTheme.primaryGold,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => updateQty(parsedQty + 1),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded, color: AppTheme.primaryDark, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Quick Quantity Add Chips (+1, +5, +10, Max)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildQuickQtyChip('+1', () => updateQty(parsedQty + 1)),
                      _buildQuickQtyChip('+5', () => updateQty(parsedQty + 5)),
                      _buildQuickQtyChip('+10', () => updateQty(parsedQty + 10)),
                      if (product.hasWholesale)
                        _buildQuickQtyChip('Grosir (${product.wholesaleMinQty})', () => updateQty(product.wholesaleMinQty!)),
                      if (product.stock > 0)
                        _buildQuickQtyChip('Maks (${product.stock})', () => updateQty(product.stock)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Wholesale Toggle (if product supports wholesale)
                  if (product.hasWholesale)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isWholesaleApplicable ? AppTheme.goldLight : AppTheme.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isWholesaleApplicable ? AppTheme.primaryGold : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_rounded,
                            size: 15,
                            color: isWholesaleApplicable ? AppTheme.goldMuted : AppTheme.textMuted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Harga Grosir (≥${product.wholesaleMinQty}: ${AppTheme.formatRupiah(product.wholesalePrice!)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isWholesaleApplicable ? AppTheme.goldMuted : AppTheme.textDark,
                              ),
                            ),
                          ),
                          Switch(
                            value: forceWholesale,
                            onChanged: (val) {
                              setDialogState(() {
                                forceWholesale = val;
                              });
                            },
                            activeTrackColor: AppTheme.primaryGold,
                            activeThumbColor: AppTheme.primaryDark,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Calculated Subtotal Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Belanja:',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          AppTheme.formatRupiah(subtotal),
                          style: const TextStyle(
                            color: AppTheme.goldAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Row(
                children: [
                  // Hapus / Batal Button (Hanya jika produk sudah ada di keranjang)
                  if (cartItem != null)
                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _removeFromCart(cartItem);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('"${product.name}" dibatalkan/dihapus dari keranjang.'),
                              duration: const Duration(milliseconds: 1000),
                              backgroundColor: AppTheme.dangerRed,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline_rounded, size: 16),
                        label: const Text('Batal / Hapus', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerRed,
                          side: const BorderSide(color: AppTheme.dangerRed),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(color: AppTheme.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Batal', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(width: 8),

                  // Simpan / Update Button
                  Expanded(
                    flex: 6,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _setCartQuantity(product, parsedQty);
                        if (cartItem != null) {
                          _toggleWholesale(cartItem, forceWholesale);
                        }
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: Text(
                        cartItem != null ? 'Update Jumlah' : 'Tambah Keranjang',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuickQtyChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
      ),
    );
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
          categories: _categories.length > 1 ? _categories : sampleCategories,
          onProductCreated: (newProduct) {
            setState(() {
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

  void _requireOwnerAuthForAction({
    required String title,
    required String message,
    required VoidCallback onAuthorized,
  }) {
    if (_currentUser.isOwner) {
      onAuthorized();
      return;
    }

    final ownerUser = _users.where((u) => u.isOwner).firstOrNull;
    final ownerPin = ownerUser?.pin.trim().isNotEmpty == true ? ownerUser!.pin.trim() : '1234';
    final pinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primaryGold, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 4,
              autofocus: true,
              style: const TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'PIN Pemilik (1234)',
                counterText: '',
                prefixIcon: const Icon(Icons.password_rounded, color: AppTheme.primaryGold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.trim() == ownerPin) {
                Navigator.pop(ctx);
                onAuthorized();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN Pemilik Toko salah! Akses ditolak.'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: AppTheme.primaryDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Buka Akses', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Serah Terima Shift Penjaga & Rekonsiliasi Kas (Full Screen Terintegrasi - Khusus Pemilik Toko)
  void _showShiftHandoverDialog([AppUser? initialIncomingUser]) {
    _requireOwnerAuthForAction(
      title: 'Otorisasi Oper Shift',
      message: 'Hanya Pemilik Toko (Owner) yang berhak melakukan serah terima shift & tutup kas.',
      onAuthorized: () {
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
                    _scheduledNextUser = nextUser;
                    _currentUser = nextUser;
                  }
                  _isLocked = true; // Kunci layar agar penjaga berikutnya menyambut dengan PIN
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
      },
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
            AppsScriptService().syncAllUsers(_users);
          },
          onUserUpdated: (updatedUser) {
            setState(() {
              final idx = _users.indexWhere((u) => u.id == updatedUser.id);
              if (idx != -1) {
                _users[idx] = updatedUser;
                if (_currentUser.id == updatedUser.id) {
                  _currentUser = updatedUser;
                }
              }
            });
            InventoryStorageService().saveUsers(_users);
            AppsScriptService().syncAllUsers(_users);
          },
          onUserDeleted: (deletedUser) {
            setState(() {
              _users.removeWhere((u) => u.id == deletedUser.id);
              if (_currentUser.id == deletedUser.id) {
                _currentUser = _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
              }
            });
            InventoryStorageService().saveUsers(_users);
            AppsScriptService().syncAllUsers(_users);
          },
          onUsersSynced: (syncedUsers) {
            setState(() {
              _users = syncedUsers;
              if (!_users.any((u) => u.id == _currentUser.id)) {
                _currentUser = _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
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
      deliveryFee: _selectedTransactionType == TransactionType.antar ? _deliveryFee : 0,
      createdAt: DateTime.now(),
    );

    setState(() {
      _heldOrders.add(newHeld);
      _cartItems.clear();
      _customerName = '';
      _discountPercent = 0;
      _deliveryFee = 0;
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
      _deliveryFee = order.deliveryFee;
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
          currentUser: _currentUser,
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
    final double delivery = _selectedTransactionType == TransactionType.antar ? _deliveryFee : 0.0;
    final double total = subtotal - discount + delivery;
    final String trxId = 'TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          totalAmount: total,
          subtotal: subtotal,
          discountAmount: discount,
          deliveryFee: delivery,
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
                deliveryFee: delivery,
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

  void _logoutOwner() {
    setState(() {
      _isLocked = true;
      if (_users.isNotEmpty) {
        _currentUser = _scheduledNextUser ?? _users.firstWhere((u) => !u.isOwner, orElse: () => _users.first);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Akun Pemilik Toko telah keluar. Layar POS terkunci.'),
        backgroundColor: AppTheme.primaryDark,
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
          onLogoutOwner: _logoutOwner,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked && !_isLoadingData) {
      return PinLoginLockScreen(
        users: _users,
        scheduledUser: _scheduledNextUser,
        storeName: _storeName,
        onAuthenticated: (authUser) {
          setState(() {
            _currentUser = authUser;
            _isLocked = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Selamat Bertugas Tretan ${authUser.name}! (${authUser.isOwner ? "👑 Pemilik Toko" : "💼 Penjaga Toko"})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: authUser.isOwner ? AppTheme.primaryDark : AppTheme.primaryTeal,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    }

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
              onLockScreen: () => setState(() => _isLocked = true),
              onLogoutOwner: _logoutOwner,
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
                                  transactionType: _selectedTransactionType,
                                  getCartQuantity: _getCartQuantity,
                                  onAddToCart: _addToCart,
                                  onIncrement: (p) {
                                    final item = _cartItems.where((i) => i.product.id == p.id).firstOrNull;
                                    if (item != null) {
                                      _incrementCart(item);
                                    } else {
                                      _addToCart(p);
                                    }
                                  },
                                  onDecrement: (p) {
                                    final item = _cartItems.where((i) => i.product.id == p.id).firstOrNull;
                                    if (item != null) {
                                      _decrementCart(item);
                                    }
                                  },
                                  onEditQuantity: (p) => _showProductQuantityDialog(p),
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
                        onTransactionTypeChanged: _onTransactionTypeChanged,
                        customerName: _customerName,
                        onCustomerNameChanged: (val) => setState(() => _customerName = val),
                        discountPercent: _discountPercent,
                        onDiscountChanged: (val) => setState(() => _discountPercent = val),
                        deliveryFee: _deliveryFee,
                        onDeliveryFeeChanged: (val) => setState(() => _deliveryFee = val),
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
                _onTransactionTypeChanged(type);
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
              deliveryFee: _deliveryFee,
              onDeliveryFeeChanged: (val) {
                setState(() => _deliveryFee = val);
                setSheetState(() {});
              },
            ),
          ),
        ),
      ),
    );
  }
}
