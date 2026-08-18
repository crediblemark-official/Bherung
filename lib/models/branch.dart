class Branch {
  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final bool isMain;
  final bool isActive;

  const Branch({
    required this.id,
    required this.name,
    this.code = '',
    this.address = '',
    this.phone = '',
    this.isMain = false,
    this.isActive = true,
  });

  Branch copyWith({
    String? id,
    String? name,
    String? code,
    String? address,
    String? phone,
    bool? isMain,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      isMain: isMain ?? this.isMain,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'address': address,
        'phone': phone,
        'isMain': isMain,
        'isActive': isActive,
      };

  factory Branch.fromJson(Map<String, dynamic> json) => Branch(
        id: json['id']?.toString() ?? 'br-${DateTime.now().millisecondsSinceEpoch}',
        name: json['name']?.toString() ?? 'Cabang Toko',
        code: json['code']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        isMain: json['isMain'] == true,
        isActive: json['isActive'] != false,
      );

  static Branch defaultMainBranch({String storeName = 'Bherung'}) {
    return Branch(
      id: 'br-main',
      name: '$storeName (Pusat)',
      code: 'CB01',
      address: 'Pusat Operasional Toko',
      phone: '',
      isMain: true,
      isActive: true,
    );
  }
}
