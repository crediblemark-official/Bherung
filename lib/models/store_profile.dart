class BankAccount {
  final String bankName;
  final String accountNumber;
  final String accountHolder;

  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
  });

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'accountHolder': accountHolder,
      };

  factory BankAccount.fromJson(Map<String, dynamic> json) => BankAccount(
        bankName: json['bankName']?.toString() ?? '',
        accountNumber: json['accountNumber']?.toString() ?? '',
        accountHolder: json['accountHolder']?.toString() ?? '',
      );

  BankAccount copyWith({
    String? bankName,
    String? accountNumber,
    String? accountHolder,
  }) {
    return BankAccount(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      accountHolder: accountHolder ?? this.accountHolder,
    );
  }
}

class StoreProfile {
  final String name;
  final String tagline;
  final String qrisName;
  final String qrisNmid;
  final double defaultStartingCash;
  final List<BankAccount> bankAccounts;

  const StoreProfile({
    this.name = 'Bherung',
    this.tagline = '24 JAM',
    this.qrisName = '',
    this.qrisNmid = '',
    this.defaultStartingCash = 200000,
    this.bankAccounts = const [],
  });

  StoreProfile copyWith({
    String? name,
    String? tagline,
    String? qrisName,
    String? qrisNmid,
    double? defaultStartingCash,
    List<BankAccount>? bankAccounts,
  }) {
    return StoreProfile(
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      qrisName: qrisName ?? this.qrisName,
      qrisNmid: qrisNmid ?? this.qrisNmid,
      defaultStartingCash: defaultStartingCash ?? this.defaultStartingCash,
      bankAccounts: bankAccounts ?? this.bankAccounts,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'tagline': tagline,
        'qrisName': qrisName,
        'qrisNmid': qrisNmid,
        'defaultStartingCash': defaultStartingCash,
        'bankAccounts': bankAccounts.map((b) => b.toJson()).toList(),
      };

  factory StoreProfile.fromJson(Map<String, dynamic> json) {
    List<BankAccount> accounts = [];
    if (json['bankAccounts'] is List) {
      accounts = (json['bankAccounts'] as List)
          .map((item) => BankAccount.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    }

    return StoreProfile(
      name: json['name']?.toString() ?? 'Bherung',
      tagline: json['tagline']?.toString() ?? '24 JAM',
      qrisName: json['qrisName']?.toString() ?? '',
      qrisNmid: json['qrisNmid']?.toString() ?? '',
      defaultStartingCash: (json['defaultStartingCash'] is num)
          ? (json['defaultStartingCash'] as num).toDouble()
          : double.tryParse(json['defaultStartingCash']?.toString() ?? '200000') ?? 200000,
      bankAccounts: accounts,
    );
  }
}
