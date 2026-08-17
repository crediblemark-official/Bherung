import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/store_profile.dart';
import '../theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final double subtotal;
  final double discountAmount;
  final double deliveryFee;
  final List<CartItem> cartItems;
  final TransactionType transactionType;
  final String customerName;
  final StoreProfile? storeProfile;
  final Function({required bool isKasbon, String? customerName, String? customerPhone, DateTime? dueDate}) onSuccess;

  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.subtotal,
    required this.discountAmount,
    this.deliveryFee = 0.0,
    required this.cartItems,
    required this.transactionType,
    required this.customerName,
    this.storeProfile,
    required this.onSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _selectedMethod = 0; // 0: Tunai, 1: Kasbon, 2: QRIS, 3: Transfer
  double _cashGiven = 0;
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _kasbonNameController = TextEditingController();
  final TextEditingController _kasbonPhoneController = TextEditingController();
  int _kasbonDueDays = 7; // Default 7 hari
  bool _isSuccess = false;
  late final String _receiptNo;
  late final DateTime _transactionTime;

  @override
  void initState() {
    super.initState();
    _transactionTime = DateTime.now();
    _receiptNo = 'TKO-${_transactionTime.millisecondsSinceEpoch.toString().substring(7)}';
    _kasbonNameController.text = widget.customerName;
    _setCashAmount(widget.totalAmount);
  }

  @override
  void dispose() {
    _cashController.dispose();
    _kasbonNameController.dispose();
    _kasbonPhoneController.dispose();
    super.dispose();
  }

  void _setCashAmount(double amount) {
    setState(() {
      _cashGiven = amount;
      _cashController.text = amount.toInt().toString();
    });
  }

  double get change => _cashGiven - widget.totalAmount;
  bool get isCashValid => _cashGiven >= widget.totalAmount;
  bool get isKasbonValid => _kasbonNameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kasir Pembayaran Sembako',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'No. Struk: $_receiptNo',
              style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Text(
              widget.transactionType.label,
              style: const TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _isSuccess ? _buildReceiptSuccessView() : _buildPaymentContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Total Tagihan Banner (Luxury Obsidian & Gold)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryDark, AppTheme.surfaceDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.45), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: AppTheme.goldAccent, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                widget.customerName.isNotEmpty ? widget.customerName : 'Pelanggan Toko',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total ${widget.cartItems.length} Item Belanja',
                            style: const TextStyle(color: AppTheme.textSubtle, fontSize: 11.5),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Tagihan', style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            AppTheme.formatRupiah(widget.totalAmount),
                            style: const TextStyle(
                              color: AppTheme.goldAccent,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Tab Pilihan Metode Pembayaran
                const Text(
                  'Pilih Metode Pembayaran:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildMethodTab(0, 'Tunai (Cash)', Icons.payments_outlined)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMethodTab(1, 'Kasbon', Icons.menu_book_rounded, isKasbon: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMethodTab(2, 'QRIS Toko', Icons.qr_code_scanner_rounded)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMethodTab(3, 'Transfer', Icons.account_balance_rounded)),
                  ],
                ),
                const SizedBox(height: 18),

                // 3. Formulir Khusus Metode
                if (_selectedMethod == 0) _buildCashSection(),
                if (_selectedMethod == 1) _buildKasbonSection(),
                if (_selectedMethod == 2) _buildQrisSection(),
                if (_selectedMethod == 3) _buildTransferSection(),

                const SizedBox(height: 18),

                // 4. Ringkasan Rincian Belanjaan (Accordion/Card)
                _buildCartItemsSummaryCard(),
              ],
            ),
          ),
        ),

        // Sticky Bottom Bar Checkout
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(top: BorderSide(color: AppTheme.borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Batal', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: ElevatedButton.icon(
                  onPressed: _canSubmit() ? _processPayment : null,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text(
                    _selectedMethod == 1
                        ? 'Catat Kasbon (${AppTheme.formatRupiah(widget.totalAmount)})'
                        : 'Selesaikan Pembayaran',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.primaryDark,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMethodTab(int index, String label, IconData icon, {bool isKasbon = false}) {
    final bool isSelected = _selectedMethod == index;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isKasbon ? const Color(0xFFFEF3C7) : AppTheme.primaryDark) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? (isKasbon ? const Color(0xFFD97706) : AppTheme.primaryGold) : AppTheme.borderColor,
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: isSelected ? AppTheme.softShadow : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? (isKasbon ? const Color(0xFFB45309) : AppTheme.goldAccent) : AppTheme.textMuted,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? (isKasbon ? const Color(0xFF92400E) : Colors.white) : AppTheme.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashSection() {
    final List<double> quickNominals = <double>{
      widget.totalAmount, // Uang Pas
      if (widget.totalAmount % 5000 != 0) (widget.totalAmount / 5000).ceil() * 5000.0,
      if (widget.totalAmount % 10000 != 0) (widget.totalAmount / 10000).ceil() * 10000.0,
      if (widget.totalAmount % 50000 != 0) (widget.totalAmount / 50000).ceil() * 50000.0,
      if (widget.totalAmount < 50000) 50000.0,
      if (widget.totalAmount < 100000) 100000.0,
      if (widget.totalAmount < 200000) 200000.0,
    }.toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Uang Diterima dari Pembeli (Rp):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textDark),
            decoration: InputDecoration(
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => _setCashAmount(0),
              ),
            ),
            onChanged: (val) {
              final parsed = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              setState(() => _cashGiven = parsed);
            },
          ),
          const SizedBox(height: 12),

          // Nominal Cepat / Uang Pas
          const Text('Pilihan Uang Pas / Pecahan Cepat:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickNominals.map((nom) {
              final isPas = nom == widget.totalAmount;
              final isCurrentSelected = _cashGiven == nom;

              return InkWell(
                onTap: () => _setCashAmount(nom),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isCurrentSelected
                        ? AppTheme.primaryDark
                        : (isPas ? AppTheme.primaryGold.withValues(alpha: 0.15) : AppTheme.bgSubtle),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentSelected
                          ? AppTheme.primaryGold
                          : (isPas ? AppTheme.primaryGold : AppTheme.borderColor),
                    ),
                  ),
                  child: Text(
                    isPas ? 'Uang Pas (${AppTheme.formatRupiah(nom)})' : AppTheme.formatRupiah(nom),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isCurrentSelected ? AppTheme.goldAccent : (isPas ? AppTheme.primaryDark : AppTheme.textDark),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Kembalian Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: change >= 0 ? AppTheme.successGreen.withValues(alpha: 0.08) : AppTheme.dangerRedLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: change >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  change >= 0 ? 'Kembalian:' : 'Uang Kurang:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: change >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                ),
                Text(
                  change >= 0 ? AppTheme.formatRupiah(change) : '- ${AppTheme.formatRupiah(change.abs())}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: change >= 0 ? AppTheme.successGreen : AppTheme.dangerRed,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKasbonSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: Color(0xFFD97706), size: 18),
              SizedBox(width: 6),
              Text(
                'Catat ke Buku Hutang / Kasbon Pelanggan',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          const Text('Nama Lengkap Pelanggan *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: _kasbonNameController,
            onChanged: (val) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'cth: Bu Hj. Maryam / Pak RT',
              prefixIcon: Icon(Icons.person_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 10),

          const Text('No. WhatsApp / HP (Opsional)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          TextFormField(
            controller: _kasbonPhoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: '081234567890 (untuk kirim WA pengingat)',
              prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
            ),
          ),
          const SizedBox(height: 12),

          const Text('Jatuh Tempo Pembayaran Kasbon:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [3, 7, 14, 30].map((days) {
              final isSel = _kasbonDueDays == days;
              return ChoiceChip(
                label: Text('$days Hari'),
                selected: isSel,
                selectedColor: AppTheme.primaryGold,
                onSelected: (val) => setState(() => _kasbonDueDays = days),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQrisSection() {
    final bool isQrisConfigured = widget.storeProfile?.qrisNmid.trim().isNotEmpty == true;
    final qrisName = widget.storeProfile?.qrisName.trim().isNotEmpty == true
        ? widget.storeProfile!.qrisName.trim()
        : 'QRIS Toko (Belum Disetting)';
    final qrisNmid = widget.storeProfile?.qrisNmid.trim().isNotEmpty == true
        ? widget.storeProfile!.qrisNmid.trim()
        : 'Belum Disetting';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isQrisConfigured ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isQrisConfigured ? AppTheme.borderColor : const Color(0xFFCBD5E1)),
              boxShadow: isQrisConfigured ? AppTheme.softShadow : null,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 130,
                  color: isQrisConfigured ? AppTheme.primaryDark : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 8),
                Text(
                  qrisName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: isQrisConfigured ? AppTheme.primaryDark : AppTheme.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  isQrisConfigured ? 'NMID: $qrisNmid • All E-Wallet & Mobile Banking' : 'NMID: Belum Disetting di Pengaturan',
                  style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isQrisConfigured
                ? 'Minta pelanggan scan QRIS sebesar ${AppTheme.formatRupiah(widget.totalAmount)} lalu tekan tombol selesai.'
                : 'QRIS belum dikonfigurasi. Anda dapat menambahkan Nama & NMID QRIS di menu Pengaturan.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSection() {
    final accounts = widget.storeProfile?.bankAccounts ?? const [];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rekening Bank Toko:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (accounts.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 36, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Rekening Bank Belum Disetting',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Silakan tambahkan nomor rekening toko di menu Pengaturan > Tab QRIS & Rekening.',
                    style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: accounts.length,
              separatorBuilder: (c, i) => const Divider(),
              itemBuilder: (context, index) {
                final acc = accounts[index];
                Color badgeColor = AppTheme.primaryDark;
                if (acc.bankName.toUpperCase().contains('BRI')) {
                  badgeColor = const Color(0xFF00529C);
                } else if (acc.bankName.toUpperCase().contains('MANDIRI')) {
                  badgeColor = const Color(0xFF003082);
                } else if (acc.bankName.toUpperCase().contains('BNI')) {
                  badgeColor = const Color(0xFFE05929);
                } else if (acc.bankName.toUpperCase().contains('DANA')) {
                  badgeColor = const Color(0xFF118EEA);
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: badgeColor,
                    child: Text(
                      acc.bankName.isNotEmpty ? acc.bankName.substring(0, acc.bankName.length > 3 ? 3 : acc.bankName.length).toUpperCase() : 'BANK',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                    ),
                  ),
                  title: Text(
                    '${acc.accountNumber} (${acc.bankName})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  subtitle: Text(
                    'a/n ${acc.accountHolder}',
                    style: const TextStyle(fontSize: 11),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCartItemsSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rincian Belanjaan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              Text('${widget.cartItems.length} Produk', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cartItems.length,
            separatorBuilder: (c, i) => const Divider(height: 10),
            itemBuilder: (c, i) {
              final item = widget.cartItems[i];
              return Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.product.name} (x${item.quantity} ${item.product.unit})',
                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    AppTheme.formatRupiah(item.totalPrice),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                ],
              );
            },
          ),
          if (widget.deliveryFee > 0) ...[
            const Divider(height: 10),
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.delivery_dining_rounded, size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('Biaya Ongkir / Antar', style: TextStyle(fontSize: 11.5, color: Color(0xFF166534), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Text(
                  '+ ${AppTheme.formatRupiah(widget.deliveryFee)}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _canSubmit() {
    if (_selectedMethod == 0) return isCashValid;
    if (_selectedMethod == 1) return isKasbonValid;
    return true; // QRIS / Transfer
  }

  void _processPayment() {
    final bool isKasbon = _selectedMethod == 1;
    final dueDate = isKasbon ? DateTime.now().add(Duration(days: _kasbonDueDays)) : null;

    widget.onSuccess(
      isKasbon: isKasbon,
      customerName: isKasbon ? _kasbonNameController.text.trim() : null,
      customerPhone: isKasbon ? _kasbonPhoneController.text.trim() : null,
      dueDate: dueDate,
    );

    setState(() => _isSuccess = true);
  }

  Widget _buildReceiptSuccessView() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                color: AppTheme.successGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transaksi Berhasil!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
            ),
            Text(
              'No. Struk: $_receiptNo',
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Pembayaran', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                      Text(AppTheme.formatRupiah(widget.totalAmount), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_selectedMethod == 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kembalian', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        Text(AppTheme.formatRupiah(change), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.successGreen)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: AppTheme.goldAccent,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Kembali ke Kasir Baru', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
