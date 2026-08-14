enum UserRoleType {
  owner, // Pemilik Toko: Akses penuh (Laba/rugi, kulakan, audit, manajemen akun)
  staff, // Penjaga Toko / Kasir: Kasir kilat, quick add barang, serah terima shift
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final UserRoleType role;
  final String pin; // 4-digit PIN for quick cashier auth
  final bool isActive;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.pin,
    this.isActive = true,
  });

  bool get isOwner => role == UserRoleType.owner;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role.name,
      'pin': pin,
      'isActive': isActive,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    UserRoleType r = UserRoleType.staff;
    if (json['role']?.toString() == 'owner') {
      r = UserRoleType.owner;
    }

    return AppUser(
      id: json['id']?.toString() ?? 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Kasir',
      phone: json['phone']?.toString() ?? '',
      role: r,
      pin: json['pin']?.toString() ?? '1234',
      isActive: json['isActive'] != false,
    );
  }
}
