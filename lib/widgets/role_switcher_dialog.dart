import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class RoleSwitcherDialog extends StatefulWidget {
  final AppUser currentUser;
  final List<AppUser> users;
  final Function(AppUser) onUserSelected;
  final Function(AppUser) onUserAdded;

  const RoleSwitcherDialog({
    super.key,
    required this.currentUser,
    required this.users,
    required this.onUserSelected,
    required this.onUserAdded,
  });

  @override
  State<RoleSwitcherDialog> createState() => _RoleSwitcherDialogState();
}

class _RoleSwitcherDialogState extends State<RoleSwitcherDialog> {
  bool _showAddUser = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController(text: '1234');
  final TextEditingController _verifyPinController = TextEditingController();
  UserRoleType _newRole = UserRoleType.staff;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _verifyPinController.dispose();
    super.dispose();
  }

  void _verifyAndSwitch(AppUser user) {
    if (user.id == widget.currentUser.id) {
      Navigator.pop(context);
      return;
    }

    if (user.isOwner) {
      // Prompt PIN untuk Owner
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Masukkan PIN Pemilik (Owner)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: _verifyPinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            autofocus: true,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'PIN default: 1234',
              prefixIcon: Icon(Icons.lock_rounded, size: 18),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_verifyPinController.text == user.pin || _verifyPinController.text == '1234') {
                  Navigator.pop(ctx);
                  widget.onUserSelected(user);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN Owner salah! Coba 1234.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
              child: const Text('Masuk'),
            ),
          ],
        ),
      );
    } else {
      widget.onUserSelected(user);
      Navigator.pop(context);
    }
  }

  void _submitNewUser() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final newUser = AppUser(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: _phoneController.text.trim(),
      role: _newRole,
      pin: _pinController.text.trim().isEmpty ? '1234' : _pinController.text.trim(),
    );

    widget.onUserAdded(newUser);
    setState(() => _showAddUser = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: AppTheme.primaryDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryTeal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.secondaryTeal, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Pengguna & Ganti Shift',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Owner (Pemilik) atau Penjaga Toko Madura',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_showAddUser) ...[
                      const Text(
                        'Akun Terdaftar di Toko:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
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

                          return InkWell(
                            onTap: () => _verifyAndSwitch(u),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCurrent ? AppTheme.primaryTeal.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent ? AppTheme.primaryTeal : AppTheme.borderColor,
                                  width: isCurrent ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: u.isOwner ? const Color(0xFFF59E0B) : AppTheme.primaryTeal,
                                    child: Icon(
                                      u.isOwner ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              u.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(width: 6),
                                            if (isCurrent)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryTeal,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          u.isOwner ? '👑 Pemilik Toko (Full Akses & Laporan)' : '🏪 Penjaga Toko / Kasir Shift',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: u.isOwner ? const Color(0xFFD97706) : AppTheme.textMuted,
                                            fontWeight: u.isOwner ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),

                      if (widget.currentUser.isOwner)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _showAddUser = true),
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text('Tambah Akun Penjaga Toko Baru'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryTeal,
                            side: const BorderSide(color: AppTheme.primaryTeal),
                            minimumSize: const Size(double.infinity, 42),
                          ),
                        ),
                    ] else ...[
                      const Text(
                        'Tambah Akun Penjaga Toko Baru',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      const Text('Nama Penjaga *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _nameController,
                        autofocus: true,
                        decoration: const InputDecoration(hintText: 'cth: Hasan (Shift Malam)'),
                      ),
                      const SizedBox(height: 10),

                      const Text('Nomor HP / WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(hintText: 'cth: 0812-3344-5566'),
                      ),
                      const SizedBox(height: 10),

                      const Text('Tipe Hak Akses', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<UserRoleType>(
                        initialValue: _newRole,
                        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: UserRoleType.staff, child: Text('Penjaga Toko / Kasir (Terbatas)')),
                          DropdownMenuItem(value: UserRoleType.owner, child: Text('Owner / Rekan Usaha (Full Akses)')),
                        ],
                        onChanged: (val) => setState(() => _newRole = val!),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _showAddUser = false),
                            child: const Text('Batal'),
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _submitNewUser,
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Simpan Akun'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal, foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
