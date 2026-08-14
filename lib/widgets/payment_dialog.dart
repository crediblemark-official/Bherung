import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final double subtotal;
  final double discountAmount;
  final List<CartItem> cartItems;
  final TransactionType transactionType;
  final String customerName;
  final Function({required bool isKasbon, String? customerName, String? customerPhone, DateTime? dueDate}) onSuccess;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    required this.subtotal,
    required this.discountAmount,
    required this.cartItems,
    required this.transactionType,
    required this.customerName,
    required this.onSuccess,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  int _selectedMethod = 0; // 0: Tunai, 1: Kasbon / Utang, 2: QRIS, 3: Transfer
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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 520.0 : screenWidth * 0.94;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 12,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: _isSuccess ? _buildReceiptSuccessView() : _buildPaymentForm(),
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    final List<double> quickNominals = <double>{
      widget.totalAmount, // Uang Pas
      if (widget.totalAmount % 5000 != 0) (widget.totalAmount / 5000).ceil() * 5000.0,
      if (widget.totalAmount % 10000 != 0) (widget.totalAmount / 10000).ceil() * 10000.0,
      if (widget.totalAmount % 50000 != 0) (widget.totalAmount / 50000).ceil() * 50000.0,
      if (widget.totalAmount < 50000) 50000.0,
      if (widget.totalAmount < 100000) 100000.0,
      if (widget.totalAmount < 200000) 200000.0,
    }.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Modal
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.point_of_sale_rounded, color: AppTheme.primaryTeal, size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kasir Pembayaran Sembako',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                Text(
                  'Pilih metode pembayaran atau catat kasbon',
                  style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                ),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 2. Total Tagihan Banner (Dark Slate Gradient)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: widget.transactionType.color.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.transactionType.label,
                          style: TextStyle(
                            color: widget.transactionType.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.customerName.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.customerName,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text('Total Belanja', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                ],
              ),
              Text(
                AppTheme.formatRupiah(widget.totalAmount),
                style: const TextStyle(
                  color: AppTheme.secondaryTeal,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Payment Method Tabs (Khas Toko Madura: Tunai, Kasbon, QRIS, Transfer)
        const Text(
          'Metode Bayar:',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: _buildMethodTab(0, 'Tunai (Cash)', Icons.payments_outlined)),
            const SizedBox(width: 6),
            Expanded(child: _buildMethodTab(1, 'Kasbon / Utang', Icons.menu_book_rounded, isKasbon: true)),
            const SizedBox(width: 6),
            Expanded(child: _buildMethodTab(2, 'QRIS Toko', Icons.qr_code_scanner_rounded)),
            const SizedBox(width: 6),
            Expanded(child: _buildMethodTab(3, 'Transfer', Icons.account_balance_rounded)),
          ],
        ),
        const SizedBox(height: 12),

        // 4. Method Specific Form
        if (_selectedMethod == 0) ...[
          // Tunai / Cash
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Uang Diterima (Rp):',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark),
              ),
              if (_cashGiven > 0)
                InkWell(
                  onTap: () => _setCashAmount(0),
                  child: const Text('Reset', style: TextStyle(fontSize: 10.5, color: AppTheme.dangerRed)),
                ),
            ],
          ),
          const SizedBox(height: 5),

          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
            onChanged: (val) {
              setState(() {
                _cashGiven = double.tryParse(val) ?? 0;
              });
            },
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.money_rounded, color: AppTheme.primaryTeal, size: 17),
              suffixIcon: _cashGiven > 0
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 15),
                      onPressed: () {
                        _cashController.clear();
                        setState(() => _cashGiven = 0);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 6),

          // Quick Cash Nominal Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: quickNominals.map((nom) {
                final bool isExact = (nom == widget.totalAmount);
                final bool isSelected = (_cashGiven == nom);
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: ActionChip(
                    label: Text(
                      isExact ? 'Uang Pas' : AppTheme.formatRupiah(nom),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.primaryTeal,
                      ),
                    ),
                    backgroundColor: isSelected ? AppTheme.primaryTeal : AppTheme.bgSubtle,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    onPressed: () => _setCashAmount(nom),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Change Indicator Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCashValid ? AppTheme.successGreenLight : AppTheme.dangerRedLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCashValid ? AppTheme.successGreen.withValues(alpha: 0.5) : AppTheme.dangerRed.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isCashValid ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                      size: 15,
                      color: isCashValid ? AppTheme.successGreen : AppTheme.dangerRed,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isCashValid ? 'KEMBALIAN:' : 'UANG KURANG:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isCashValid ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                Text(
                  AppTheme.formatRupiah(change.abs()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isCashValid ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ] else if (_selectedMethod == 1) ...[
          // FITUR KASBON / UTANG TOKO KELONTONG & MADURA
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: Color(0xFFB45309), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Pencatatan Buku Kasbon Pelanggan',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _kasbonNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Pelanggan Kasbon (Wajib)*',
                    hintText: 'Contoh: Pak Haji Ahmad / Bu Rini',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _kasbonPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'No. HP / WhatsApp (Opsional)',
                    hintText: 'Contoh: 0812-3456-7890',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Janji Bayar (Jatuh Tempo):',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildDueChip(3, '3 Hari'),
                    const SizedBox(width: 4),
                    _buildDueChip(7, '1 Minggu'),
                    const SizedBox(width: 4),
                    _buildDueChip(14, '2 Minggu'),
                    const SizedBox(width: 4),
                    _buildDueChip(30, 'Pas Gajian (1 Bulan)'),
                  ],
                ),
              ],
            ),
          ),
        ] else if (_selectedMethod == 2) ...[
          // QRIS Tab
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_2_rounded, size: 68, color: AppTheme.primaryDark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QRIS Toko Madura 24 Jam',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppTheme.textDark),
                      ),
                      const Text(
                        'TOKO SEMBAKO BHERUNG',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryTeal),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Scan dengan GoPay, OVO, Dana, ShopeePay, BCA, Livin.',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () {
                          setState(() => _isSuccess = true);
                          widget.onSuccess(isKasbon: false);
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTealLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⚡ Konfirmasi QRIS Sukses',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Transfer Tab
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.bgSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rekening Transfer Toko:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
                SizedBox(height: 4),
                Text('BCA: 541-098-7621 (a/n H. Achmad Bherung)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                Text('BRI: 0192-01-092831-50-2', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],

        const SizedBox(height: 14),

        // 5. Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
                child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_selectedMethod == 0 && !isCashValid) || (_selectedMethod == 1 && !isKasbonValid)
                    ? null
                    : () {
                        setState(() {
                          _isSuccess = true;
                        });
                        final isKasbon = _selectedMethod == 1;
                        final dueDate = isKasbon ? DateTime.now().add(Duration(days: _kasbonDueDays)) : null;
                        widget.onSuccess(
                          isKasbon: isKasbon,
                          customerName: _kasbonNameController.text.trim().isNotEmpty ? _kasbonNameController.text.trim() : null,
                          customerPhone: _kasbonPhoneController.text.trim().isNotEmpty ? _kasbonPhoneController.text.trim() : null,
                          dueDate: dueDate,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: _selectedMethod == 1 ? const Color(0xFFD97706) : AppTheme.successGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_selectedMethod == 1 ? Icons.bookmark_add_rounded : Icons.check_circle_rounded, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      _selectedMethod == 1 ? 'CATAT KASBON' : 'KONFIRMASI LUNAS',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDueChip(int days, String label) {
    final bool isSelected = _kasbonDueDays == days;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _kasbonDueDays = days),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD97706) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFF59E0B)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF92400E),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodTab(int index, String label, IconData icon, {bool isKasbon = false}) {
    final bool isSelected = _selectedMethod == index;
    final activeColor = isKasbon ? const Color(0xFFD97706) : AppTheme.primaryTeal;

    return InkWell(
      onTap: () => setState(() => _selectedMethod = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : AppTheme.bgSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : AppTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : (isKasbon ? const Color(0xFFD97706) : AppTheme.textMuted),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Realistic Digital Receipt View for Toko Sembako / Madura
  Widget _buildReceiptSuccessView() {
    final isKasbon = _selectedMethod == 1;
    final methodName = switch (_selectedMethod) {
      0 => 'Tunai (Cash)',
      1 => 'Kasbon / Piutang Belanja',
      2 => 'QRIS Toko',
      _ => 'Transfer Bank',
    };

    final custName = _kasbonNameController.text.trim().isNotEmpty
        ? _kasbonNameController.text.trim()
        : widget.customerName;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Pill
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: isKasbon ? const Color(0xFFD97706) : AppTheme.successGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(isKasbon ? Icons.bookmark_added_rounded : Icons.check_rounded, size: 24, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Text(
          isKasbon ? 'Kasbon Berhasil Dicatat!' : 'Pembayaran Sukses!',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppTheme.textDark),
        ),
        Text(
          isKasbon ? 'Tercatat di Buku Kasbon Pelanggan Toko.' : 'Transaksi telah disimpan ke database kasir.',
          style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
        ),
        const SizedBox(height: 10),

        // Simulated Paper Receipt Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header
              const Center(
                child: Column(
                  children: [
                    Text(
                      'TOKO MADURA & SEMBAKO BHERUNG',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                    ),
                    Text(
                      'Sembako • Rokok • Gas LPG • Galon • Buka 24 Jam',
                      style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                    ),
                    Text(
                      'Pasar Anyar No. 12, Telp: 0812-9876-5432',
                      style: TextStyle(fontSize: 9.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Divider(height: 1, color: AppTheme.borderColor),
              ),

              // Transaction Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nota: $_receiptNo', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(
                    '${_transactionTime.day}/${_transactionTime.month}/${_transactionTime.year} ${_transactionTime.hour.toString().padLeft(2, '0')}:${_transactionTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tipe: ${widget.transactionType.label}', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  Text('Kasir: Ahmad (Shift Malam)', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                ],
              ),
              if (custName.isNotEmpty)
                Text('Pelanggan: $custName', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textDark)),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(height: 1, color: AppTheme.borderColor),
              ),

              // Itemized List with Units
              ...widget.cartItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.product.name} (${item.quantity} ${item.product.unit})',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        AppTheme.formatRupiah(item.totalPrice),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Divider(height: 1, color: AppTheme.borderColor),
              ),

              // Financial Breakdown
              _buildReceiptRow('Subtotal Belanja', AppTheme.formatRupiah(widget.subtotal)),
              if (widget.discountAmount > 0)
                _buildReceiptRow('Potongan Diskon', '- ${AppTheme.formatRupiah(widget.discountAmount)}', isHighlight: true),
              const SizedBox(height: 3),
              _buildReceiptRow('TOTAL TAGIHAN', AppTheme.formatRupiah(widget.totalAmount), isBold: true),
              _buildReceiptRow('Status Pembayaran', methodName),
              if (_selectedMethod == 0) ...[
                _buildReceiptRow('Uang Diterima', AppTheme.formatRupiah(_cashGiven)),
                _buildReceiptRow('Kembalian', AppTheme.formatRupiah(change), isHighlight: true, isBold: true),
              ] else if (isKasbon) ...[
                _buildReceiptRow('Jatuh Tempo', '$_kasbonDueDays Hari ke depan', isBold: true),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🖨️ Mencetak nota thermal kasir...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 15),
                label: const Text('Cetak Nota', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 15),
                label: const Text('Transaksi Baru', style: TextStyle(fontSize: 11.5)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  backgroundColor: AppTheme.primaryTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: isHighlight ? AppTheme.primaryTeal : AppTheme.textDark,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: isHighlight ? AppTheme.primaryTeal : AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
