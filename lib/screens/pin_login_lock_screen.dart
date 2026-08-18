import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

class PinLoginLockScreen extends StatefulWidget {
  final List<AppUser> users;
  final AppUser? scheduledUser;
  final String storeName;
  final bool isMultiBranchEnabled;
  final String? activeBranchId;
  final String? activeBranchName;
  final Function(AppUser authenticatedUser) onAuthenticated;

  const PinLoginLockScreen({
    super.key,
    required this.users,
    this.scheduledUser,
    this.storeName = 'Bherung POS',
    this.isMultiBranchEnabled = false,
    this.activeBranchId,
    this.activeBranchName,
    required this.onAuthenticated,
  });

  @override
  State<PinLoginLockScreen> createState() => _PinLoginLockScreenState();
}

class _PinLoginLockScreenState extends State<PinLoginLockScreen> with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _errorMessage;
  late AppUser? _currentScheduledUser;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _currentScheduledUser = widget.scheduledUser ??
        widget.users.where((u) {
          if (!u.isActive || u.isOwner) return false;
          if (widget.isMultiBranchEnabled && widget.activeBranchId != null && u.branchId != null) {
            return u.branchId == widget.activeBranchId;
          }
          return true;
        }).firstOrNull ??
        widget.users.where((u) => !u.isOwner && u.isActive).firstOrNull ??
        widget.users.firstOrNull;

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin += val;
        _errorMessage = null;
      });

      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _validatePin() async {
    final cleanPin = _pin.trim();
    AppUser? matchedUser;

    for (final u in widget.users) {
      if (u.isActive) {
        if (u.isOwner) {
          final effectiveOwnerPin = u.pin.trim().isEmpty ? '1234' : u.pin.trim();
          if (effectiveOwnerPin == cleanPin) {
            matchedUser = u;
            break;
          }
        } else {
          // Kasir / Staff: Wajib cocok dengan PIN terdaftar (TIDAK ADA default PIN)
          if (u.pin.trim().isNotEmpty && u.pin.trim() == cleanPin) {
            matchedUser = u;
            break;
          }
        }
      }
    }

    // Master Owner PIN Fallback: Hanya Owner yang memiliki fallback PIN (1234)
    if (matchedUser == null && cleanPin == '1234') {
      matchedUser = widget.users.where((u) => u.isOwner).firstOrNull ??
          const AppUser(
            id: 'usr-owner',
            name: 'Pemilik Toko (Owner)',
            phone: '',
            role: UserRoleType.owner,
            pin: '1234',
            isActive: true,
          );
    }

    if (matchedUser != null) {
      // 1 Cabang 1 Penjaga Enforcement
      if (widget.isMultiBranchEnabled && !matchedUser.isOwner) {
        if (matchedUser.branchId != null &&
            widget.activeBranchId != null &&
            matchedUser.branchId != widget.activeBranchId) {
          HapticFeedback.vibrate();
          _shakeController.forward(from: 0.0);
          setState(() {
            _errorMessage = 'Akses Ditolak: ${matchedUser!.name} hanya ditugaskan di ${matchedUser.branchName ?? "cabang lain"}.\nHP ini khusus bertugas untuk ${widget.activeBranchName ?? "cabang ini"}.';
            _pin = '';
          });
          return;
        }
      }

      HapticFeedback.heavyImpact();
      // Simpan user aktif sebagai user yang baru saja login
      await InventoryStorageService().saveScheduledNextUser(matchedUser);

      if (mounted) {
        widget.onAuthenticated(matchedUser);
      }
    } else {
      HapticFeedback.vibrate();
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'PIN Salah! Silakan periksa kembali PIN Anda.';
        _pin = '';
      });
    }
  }

  void _showSwitchUserModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Penjaga Toko / Jaga',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              itemCount: widget.users.length,
              separatorBuilder: (c, i) => const Divider(color: Colors.white12),
              itemBuilder: (c, i) {
                final u = widget.users[i];
                final isSelected = _currentScheduledUser?.id == u.id;
                final isCurrentBranch = !widget.isMultiBranchEnabled || u.isOwner || (widget.activeBranchId != null && u.branchId == widget.activeBranchId);

                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: u.isOwner ? AppTheme.primaryGold : (isCurrentBranch ? AppTheme.primaryTeal : const Color(0xFF64748B)),
                      child: Icon(
                        u.isOwner ? Icons.workspace_premium_rounded : Icons.person_rounded,
                        color: AppTheme.primaryDark,
                        size: 20,
                      ),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            u.name,
                            style: TextStyle(
                              color: isCurrentBranch ? Colors.white : Colors.white60,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isMultiBranchEnabled && u.branchName != null && !u.isOwner) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: isCurrentBranch ? const Color(0xFF0F766E) : const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              u.branchName!,
                              style: TextStyle(
                                color: isCurrentBranch ? const Color(0xFF5EEAD4) : Colors.white60,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      u.isOwner
                          ? '👑 Pemilik Toko (Akses Semua Cabang)'
                          : (isCurrentBranch
                              ? '💼 Penjaga Cabang Ini'
                              : '⚠️ Ditugaskan di ${u.branchName ?? "cabang lain"}'),
                      style: TextStyle(
                        color: u.isOwner
                            ? AppTheme.primaryGold
                            : (isCurrentBranch ? Colors.white70 : const Color(0xFFF87171)),
                        fontSize: 11,
                      ),
                    ),
                    trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold) : null,
                    onTap: () {
                      setState(() {
                        _currentScheduledUser = u;
                        _pin = '';
                        _errorMessage = null;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final targetName = _currentScheduledUser?.name ?? 'Tretan Kasir';

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Header & Greeting
                  const SizedBox(height: 4),
                  // App Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.surfaceDark,
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGold.withValues(alpha: 0.25),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/bherung_logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.storefront_rounded,
                          color: AppTheme.primaryGold,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.storeName.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.goldAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (widget.isMultiBranchEnabled && widget.activeBranchName != null) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.6)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_rounded, size: 12, color: Color(0xFF5EEAD4)),
                          const SizedBox(width: 4),
                          Text(
                            widget.activeBranchName!,
                            style: const TextStyle(
                              color: Color(0xFF5EEAD4),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // Welcoming Madura Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surfaceDark,
                          AppTheme.primaryTeal.withValues(alpha: 0.25),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4), width: 1.2),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          '🏪 SISTEM KASIR SIAP DIGUNAKAN',
                          style: TextStyle(color: Colors.white60, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Silahkan masuk Tretan $targetName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currentScheduledUser?.isOwner == true
                              ? '👑 Akun Pemilik Toko (Akses Penuh)'
                              : '💼 Jadwal Jaga Berikutnya',
                          style: TextStyle(
                            color: _currentScheduledUser?.isOwner == true ? AppTheme.primaryGold : const Color(0xFF5EEAD4),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 2. PIN Dots Display & Error
                  const Text(
                    'Masukkan 4-Digit PIN Anda',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),

                  // Animated PIN Dots
                  AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = _shakeController.value == 0
                          ? 0.0
                          : (10.0 * (1 - _shakeController.value) * ((_shakeController.value * 6).round() % 2 == 0 ? 1 : -1));
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: child,
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final isFilled = index < _pin.length;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFilled ? AppTheme.primaryGold : Colors.transparent,
                            border: Border.all(
                              color: isFilled ? AppTheme.primaryGold : Colors.white38,
                              width: 2,
                            ),
                            boxShadow: isFilled
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primaryGold.withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 3. Custom Numpad
                  _buildNumpadRow(['1', '2', '3']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['4', '5', '6']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['7', '8', '9']),
                  const SizedBox(height: 8),
                  _buildNumpadRow(['C', '0', '⌫']),

                  const SizedBox(height: 10),

                  // 4. Footer Switch User Button
                  TextButton.icon(
                    onPressed: _showSwitchUserModal,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 15, color: AppTheme.primaryGold),
                    label: const Text(
                      'Bukan Anda? Ganti Penjaga Lain / Masuk Owner',
                      style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        if (key == 'C') {
          return _buildNumpadButton(
            child: const Text('C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white54)),
            onTap: _onClear,
          );
        } else if (key == '⌫') {
          return _buildNumpadButton(
            child: const Icon(Icons.backspace_outlined, size: 18, color: Colors.white70),
            onTap: _onBackspace,
          );
        } else {
          return _buildNumpadButton(
            child: Text(
              key,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
            ),
            onTap: () => _onKeyPress(key),
          );
        }
      }).toList(),
    );
  }

  Widget _buildNumpadButton({required Widget child, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceDark.withValues(alpha: 0.9),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
