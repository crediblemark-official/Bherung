import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/apps_script_service.dart';
import '../services/google_sheets_direct_service.dart';
import '../theme/app_theme.dart';

class RoleSwitcherScreen extends StatefulWidget {
  final AppUser currentUser;
  final List<AppUser> users;
  final double currentShiftSales;
  final int currentShiftTransactions;
  final Function(AppUser) onUserSelected;
  final Function(AppUser targetUser) onStartShiftHandover;
  final Function(AppUser) onUserAdded;
  final Function(AppUser) onUserUpdated;
  final Function(AppUser) onUserDeleted;
  final Function(List<AppUser>) onUsersSynced;

  const RoleSwitcherScreen({
    super.key,
    required this.currentUser,
    required this.users,
    this.currentShiftSales = 0,
    this.currentShiftTransactions = 0,
    required this.onUserSelected,
    required this.onStartShiftHandover,
    required this.onUserAdded,
    required this.onUserUpdated,
    required this.onUserDeleted,
    required this.onUsersSynced,
  });

  @override
  State<RoleSwitcherScreen> createState() => _RoleSwitcherScreenState();
}

class _RoleSwitcherScreenState extends State<RoleSwitcherScreen> {
  bool _showForm = false;
  AppUser? _editingUser; // Null jika tambah baru, ada isinya jika edit
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(text: '1234');
  final TextEditingController _verifyPinController = TextEditingController();
  final TextEditingController _quickPinController = TextEditingController();
  UserRoleType _role = UserRoleType.staff;
  bool _isSyncing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _verifyPinController.dispose();
    _quickPinController.dispose();
    super.dispose();
  }

  void _openAddUserForm() {
    _requireOwnerAuth(
      title: 'Otorisasi Kelola Pengguna',
      message: 'Hanya Pemilik Toko (Owner) yang berhak menambah akun kasir baru.',
      onAuthorized: () {
        setState(() {
          _editingUser = null;
          _nameController.clear();
          _phoneController.clear();
          _pinController.text = '5678';
          _role = UserRoleType.staff;
          _showForm = true;
        });
      },
    );
  }

  void _openEditUserForm(AppUser user) {
    _requireOwnerAuth(
      title: 'Otorisasi Kelola Pengguna',
      message: 'Hanya Pemilik Toko (Owner) yang berhak mengubah data & PIN kasir.',
      onAuthorized: () {
        setState(() {
          _editingUser = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone;
          _pinController.text = user.pin;
          _role = user.role;
          _showForm = true;
        });
      },
    );
  }

  void _requireOwnerAuth({
    required String title,
    required String message,
    required VoidCallback onAuthorized,
  }) {
    if (widget.currentUser.isOwner) {
      onAuthorized();
      return;
    }

    final ownerUser = widget.users.where((u) => u.isOwner).firstOrNull;
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

  void _verifyAndSwitch(AppUser user) {
    if (user.id == widget.currentUser.id) {
      Navigator.pop(context);
      return;
    }

    _verifyPinController.clear();
    final requiredPin = user.pin.trim().isEmpty ? (user.isOwner ? '1234' : '5678') : user.pin.trim();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(user.isOwner ? Icons.workspace_premium_rounded : Icons.lock_rounded,
                color: user.isOwner ? AppTheme.primaryGold : AppTheme.primaryTeal, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Masukkan PIN ${user.name}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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
              user.isOwner
                  ? 'Masukkan PIN Pemilik Toko untuk beralih ke hak akses penuh.'
                  : 'Masukkan PIN Penjaga Toko untuk beralih ke sesi kasir ${user.name}.',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _verifyPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              autofocus: true,
              maxLength: 4,
              style: const TextStyle(fontSize: 18, letterSpacing: 6, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'PIN 4-Digit',
                counterText: '',
                prefixIcon: const Icon(Icons.password_rounded, size: 18),
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
              if (_verifyPinController.text.trim() == requiredPin) {
                Navigator.pop(ctx);
                widget.onUserSelected(user);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN Salah! Akses ditolak.'),
                    backgroundColor: AppTheme.dangerRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: user.isOwner ? AppTheme.primaryGold : AppTheme.primaryTeal,
              foregroundColor: user.isOwner ? AppTheme.primaryDark : Colors.white,
            ),
            child: const Text('Beralih Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleShiftHandover(AppUser targetUser) {
    _requireOwnerAuth(
      title: 'Otorisasi Oper Shift',
      message: 'Hanya Pemilik Toko (Owner) yang berhak melakukan serah terima shift & tutup kas.',
      onAuthorized: () {
        Navigator.pop(context);
        widget.onStartShiftHandover(targetUser);
      },
    );
  }

  void _submitUserForm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama kasir/penjaga wajib diisi')),
      );
      return;
    }

    if (_editingUser == null) {
      // Tambah User Baru
      final newUser = AppUser(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        phone: _phoneController.text.trim(),
        role: _role,
        pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text.trim(),
      );
      widget.onUserAdded(newUser);
    } else {
      // Edit User Yang Sudah Ada
      final updatedUser = _editingUser!.copyWith(
        name: name,
        phone: _phoneController.text.trim(),
        role: _role,
        pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text.trim(),
      );
      widget.onUserUpdated(updatedUser);
    }

    setState(() => _showForm = false);
  }

  void _confirmDeleteUser(AppUser user) {
    if (user.id == widget.currentUser.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menghapus akun yang sedang aktif digunakan.')),
      );
      return;
    }

    final ownerCount = widget.users.where((u) => u.isOwner).length;
    if (user.isOwner && ownerCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menghapus satu-satunya akun Pemilik (Owner).')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Hapus Akun Penjaga?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus akun "${user.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUserDeleted(user);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerRed, foregroundColor: Colors.white),
            child: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _handleQuickPinAuth(String pin) {
    if (pin.trim().length < 4) return;
    final cleanPin = pin.trim();
    AppUser? matchedUser;

    for (final u in widget.users) {
      if (u.isActive && u.pin.trim() == cleanPin) {
        matchedUser = u;
        break;
      }
    }

    if (matchedUser != null) {
      _quickPinController.clear();
      widget.onUserSelected(matchedUser);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                matchedUser.isOwner ? Icons.workspace_premium_rounded : Icons.badge_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PIN Cocok! Masuk sebagai: ${matchedUser.name} (${matchedUser.isOwner ? "👑 Pemilik Toko" : "💼 Penjaga Toko"})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          backgroundColor: matchedUser.isOwner ? AppTheme.primaryDark : AppTheme.primaryTeal,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN tidak cocok dengan akun mana pun. Periksa kembali PIN Anda.'),
          backgroundColor: AppTheme.dangerRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Sinkronisasi 2 Arah Data Pengguna ke Google Sheets
  Future<void> _syncUsersToCloud() async {
    setState(() => _isSyncing = true);

    // 1. Coba sync via Direct Google Sheets OAuth
    if (GoogleSheetsDirectService().isSignedIn) {
      final directUsers = await GoogleSheetsDirectService().fetchUsers();
      setState(() => _isSyncing = false);
      if (mounted) {
        if (directUsers != null && directUsers.isNotEmpty) {
          widget.onUsersSynced(directUsers);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil sinkron ${directUsers.length} akun & PIN dari Google Sheets!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menarik akun dari Google Sheets.'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
      return;
    }

    // 2. Coba sync via Apps Script / Service Account
    if (AppsScriptService().isConnected) {
      final result = await AppsScriptService().syncAllUsers(widget.users);
      setState(() => _isSyncing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? (result['success'] ? 'Berhasil sinkron ke Cloud' : 'Gagal sinkron')),
            backgroundColor: result['success'] ? AppTheme.successGreen : AppTheme.dangerRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Belum terhubung ke Google Spreadsheet Toko. Atur di menu Pengaturan.'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  // Tarik Data Pengguna & PIN Terbaru dari Google Sheets
  Future<void> _fetchUsersFromCloud() async {
    setState(() => _isSyncing = true);

    if (GoogleSheetsDirectService().isSignedIn) {
      final directUsers = await GoogleSheetsDirectService().fetchUsers();
      setState(() => _isSyncing = false);
      if (mounted && directUsers != null && directUsers.isNotEmpty) {
        widget.onUsersSynced(directUsers);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil memuat ${directUsers.length} akun & PIN dari Google Drive!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        return;
      }
    }

    if (AppsScriptService().isConnected) {
      final cloudUsers = await AppsScriptService().fetchUsersFromSpreadsheet();
      setState(() => _isSyncing = false);

      if (mounted) {
        if (cloudUsers != null && cloudUsers.isNotEmpty) {
          widget.onUsersSynced(cloudUsers);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil memuat ${cloudUsers.length} akun & PIN dari Google Spreadsheet.'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada data akun baru di Google Spreadsheet.'),
              backgroundColor: AppTheme.warningOrange,
            ),
          );
        }
      }
      return;
    }

    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum terhubung ke Google Spreadsheet Toko. Atur di menu Pengaturan.'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCloudConnected = AppsScriptService().isConnected;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kelola Pengguna & Oper Shift Kasir',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              'Sinkronisasi Google Apps Script & Shift Kasir',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldAccent)),
              ),
            )
          else
            IconButton(
              tooltip: 'Sinkronkan Akun ke Cloud (GAS)',
              icon: const Icon(Icons.cloud_sync_rounded, color: AppTheme.goldAccent),
              onPressed: _syncUsersToCloud,
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_showForm) ...[
                    // Active Shift Status Card (Obsidian & Gold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryDark, AppTheme.surfaceDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Kasir Berjalan: ', style: TextStyle(fontSize: 11.5, color: Colors.white70)),
                                    Flexible(
                                      child: Text(
                                        widget.currentUser.name,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.goldAccent),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${widget.currentShiftTransactions} Transaksi  •  Omzet: ${AppTheme.formatRupiah(widget.currentShiftSales)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (widget.currentUser.isOwner)
                            InkWell(
                              onTap: () => _handleShiftHandover(
                                widget.users.firstWhere((u) => u.id != widget.currentUser.id, orElse: () => widget.currentUser),
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.goldGradient,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: AppTheme.softShadow,
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync_alt_rounded, size: 14, color: AppTheme.primaryDark),
                                    SizedBox(width: 5),
                                    Text(
                                      'Serah Terima Shift',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded, size: 13, color: AppTheme.primaryTeal),
                                  SizedBox(width: 4),
                                  Text(
                                    'Kasir Bertugas',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick PIN Input Card (Auto Identify Role & User)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3), width: 1.5),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.pin_rounded, color: AppTheme.primaryTeal, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Masuk Cepat via PIN (Deteksi Role Otomatis)',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Ketik 4-digit PIN untuk login langsung tanpa memilih nama. Sistem otomatis mengenali apakah Anda Pemilik Toko (PIN: 1234) atau Penjaga Toko (PIN: 5678).',
                            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.3),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _quickPinController,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  maxLength: 4,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 8),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '• • • •',
                                    hintStyle: const TextStyle(letterSpacing: 8, color: Colors.black26),
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryTeal, size: 20),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    if (val.length == 4) {
                                      _handleQuickPinAuth(val);
                                    }
                                  },
                                  onSubmitted: (val) => _handleQuickPinAuth(val),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleQuickPinAuth(_quickPinController.text),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryTeal,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Masuk', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Cloud Sync Banner (GAS Integration)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCloudConnected ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCloudConnected ? const Color(0xFF86EFAC) : const Color(0xFFFECACA),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCloudConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            size: 18,
                            color: isCloudConnected ? AppTheme.successGreen : AppTheme.dangerRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCloudConnected
                                  ? 'Sinkronisasi Cloud GAS Aktif (${AppsScriptService().spreadsheetName})'
                                  : 'Mode Offline (Hubungkan Spreadsheet di Pengaturan)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isCloudConnected ? const Color(0xFF166534) : const Color(0xFF991B1B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCloudConnected) ...[
                            TextButton.icon(
                              onPressed: _fetchUsersFromCloud,
                              icon: const Icon(Icons.download_rounded, size: 14),
                              label: const Text('Tarik Cloud', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF166534),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Akun Penjaga Toko:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                        ),
                        Text(
                          '${widget.users.length} Akun Terdaftar',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.users.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final u = widget.users[i];
                        final isCurrent = u.id == widget.currentUser.id;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrent ? AppTheme.primaryGold.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent ? AppTheme.primaryGold : AppTheme.borderColor,
                              width: isCurrent ? 1.6 : 1,
                            ),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: u.isOwner ? const Color(0xFFF59E0B) : AppTheme.primaryDark,
                                child: Icon(
                                  u.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                  color: u.isOwner ? Colors.white : AppTheme.goldAccent,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            u.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryGold,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Sedang Aktif',
                                              style: TextStyle(
                                                color: AppTheme.primaryDark,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      u.isOwner
                                          ? 'Pemilik Toko (Full Akses) • PIN: ${u.pin}'
                                          : 'Kasir Shift • ${u.phone.isNotEmpty ? u.phone : "PIN: ${u.pin}"}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: u.isOwner ? const Color(0xFFD97706) : AppTheme.textMuted,
                                        fontWeight: u.isOwner ? FontWeight.bold : FontWeight.normal,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Edit & Delete Menu (Hanya Pemilik yang boleh mengelola)
                              if (widget.currentUser.isOwner) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.goldMuted),
                                  tooltip: 'Edit Akun',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _openEditUserForm(u),
                                ),
                                const SizedBox(width: 6),
                                if (!isCurrent)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.dangerRed),
                                    tooltip: 'Hapus Akun',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () => _confirmDeleteUser(u),
                                  ),
                                const SizedBox(width: 6),
                              ],

                              // Action buttons
                              if (!isCurrent) ...[
                                // 1. Oper Shift button (Khusus Pemilik Toko)
                                if (widget.currentUser.isOwner) ...[
                                  InkWell(
                                    onTap: () => _handleShiftHandover(u),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      height: 30,
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.goldGradient,
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryGold.withValues(alpha: 0.25),
                                            blurRadius: 3,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.sync_alt_rounded, size: 13, color: AppTheme.primaryDark),
                                          SizedBox(width: 4),
                                          Text(
                                            'Oper Shift',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTheme.primaryDark),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                ],

                                // 2. Fast switch button
                                InkWell(
                                  onTap: () => _verifyAndSwitch(u),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 30,
                                    padding: const EdgeInsets.symmetric(horizontal: 7),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bgSubtle,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.borderColor),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Ganti Cepat',
                                        style: TextStyle(fontSize: 10, color: AppTheme.textDark, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    if (widget.currentUser.isOwner)
                      InkWell(
                        onTap: _openAddUserForm,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.7)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_rounded, size: 16, color: AppTheme.primaryDark),
                              SizedBox(width: 8),
                              Text(
                                'Tambah Akun Penjaga Toko Baru',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    // Add / Edit User Form
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderColor),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _editingUser == null ? 'Tambah Akun Penjaga Toko Baru' : 'Edit Akun: ${_editingUser!.name}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setState(() => _showForm = false),
                              ),
                            ],
                          ),
                          const Divider(),
                          const SizedBox(height: 8),

                          const Text('Nama Lengkap Kasir / Penjaga *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              hintText: 'cth: Hasan / Siti / Pak RT',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text('Nomor HP / WhatsApp (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              hintText: '081234567890',
                              prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 12),

                          const Text('Peran Akun *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Kasir Shift')),
                                  selected: _role == UserRoleType.staff,
                                  selectedColor: AppTheme.primaryGold,
                                  onSelected: (val) => setState(() => _role = UserRoleType.staff),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Center(child: Text('Pemilik (Owner)')),
                                  selected: _role == UserRoleType.owner,
                                  selectedColor: AppTheme.primaryGold,
                                  onSelected: (val) => setState(() => _role = UserRoleType.owner),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          const Text('PIN Akses Kasir (4 Digit) *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              hintText: 'Default 1234',
                              prefixIcon: Icon(Icons.lock_outline_rounded, size: 18),
                            ),
                          ),
                          const SizedBox(height: 14),

                          ElevatedButton.icon(
                            onPressed: _submitUserForm,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: Text(_editingUser == null ? 'Simpan & Sinkronkan Akun' : 'Simpan Perubahan Akun'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryDark,
                              foregroundColor: AppTheme.goldAccent,
                              minimumSize: const Size(double.infinity, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
