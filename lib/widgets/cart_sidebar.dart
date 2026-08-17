import 'package:flutter/material.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';

class CartSidebar extends StatefulWidget {
  final List<CartItem> cartItems;
  final Function(CartItem) onIncrement;
  final Function(CartItem) onDecrement;
  final Function(CartItem) onRemove;
  final Function(CartItem, String?) onUpdateNote;
  final Function(CartItem, bool) onToggleWholesale;
  final VoidCallback onClearCart;
  final VoidCallback onHoldOrder;
  final VoidCallback onCheckout;
  final TransactionType transactionType;
  final Function(TransactionType) onTransactionTypeChanged;
  final String customerName;
  final Function(String) onCustomerNameChanged;
  final double discountPercent;
  final Function(double) onDiscountChanged;

  const CartSidebar({
    super.key,
    required this.cartItems,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onUpdateNote,
    required this.onToggleWholesale,
    required this.onClearCart,
    required this.onHoldOrder,
    required this.onCheckout,
    required this.transactionType,
    required this.onTransactionTypeChanged,
    required this.customerName,
    required this.onCustomerNameChanged,
    required this.discountPercent,
    required this.onDiscountChanged,
  });

  @override
  State<CartSidebar> createState() => _CartSidebarState();
}

class _CartSidebarState extends State<CartSidebar> {
  late TextEditingController _customerController;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController(text: widget.customerName);
  }

  @override
  void didUpdateWidget(covariant CartSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerName != widget.customerName &&
        _customerController.text != widget.customerName) {
      _customerController.text = widget.customerName;
    }
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get discountAmount => subtotal * (widget.discountPercent / 100);
  double get grandTotal => subtotal - discountAmount;
  int get totalItemCount => widget.cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _showNoteDialog(CartItem item) {
    final TextEditingController noteCtrl = TextEditingController(text: item.note ?? '');
    final List<String> presetNotes = [
      'Bungkus Plastik Dobel',
      'Pisah Kantong',
      'Dus Masih Segel',
      'Titip Tetangga',
      'Kembalian Permen',
      'Minta Kardus Bekas',
      'Giling / Halus',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actionsPadding: const EdgeInsets.all(12),
          title: Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: AppTheme.primaryTeal, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Catatan: ${item.product.name}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: noteCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan khusus sembako/barang...',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pilihan Cepat:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: presetNotes.map((preset) {
                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          noteCtrl.text = preset;
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          preset,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            if (item.note != null && item.note!.isNotEmpty)
              TextButton(
                onPressed: () {
                  widget.onUpdateNote(item, null);
                  Navigator.pop(ctx);
                },
                child: const Text('Hapus Catatan', style: TextStyle(color: AppTheme.dangerRed, fontSize: 12)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                final text = noteCtrl.text.trim();
                widget.onUpdateNote(item, text.isEmpty ? null : text);
                Navigator.pop(ctx);
              },
              child: const Text('Simpan', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actionsPadding: const EdgeInsets.all(12),
        title: const Row(
          children: [
            Icon(Icons.discount_rounded, color: AppTheme.primaryTeal, size: 20),
            SizedBox(width: 8),
            Text('Diskon / Potongan Harga', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih persentase potongan harga nota:',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [0, 2, 5, 10, 15, 20].map((percent) {
                  final isSelected = widget.discountPercent == percent.toDouble();
                  return ChoiceChip(
                    label: Text(percent == 0 ? 'Tanpa Diskon' : '$percent%'),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryTeal,
                    backgroundColor: AppTheme.bgSubtle,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.textDark,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryTeal : AppTheme.borderColor,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        widget.onDiscountChanged(percent.toDouble());
                        Navigator.pop(ctx);
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (var item in widget.cartItems) {
      item.transactionType = widget.transactionType;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // 1. Transaction Type (Eceran / Grosir / Titip) & Pelanggan Input
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
            ),
            child: Column(
              children: [
                // Segmented Transaction Switcher
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: TransactionType.values.map((type) {
                      final isSelected = widget.transactionType == type;
                      return Expanded(
                        child: InkWell(
                          onTap: () => widget.onTransactionTypeChanged(type),
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected ? AppTheme.softShadow : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  type.icon,
                                  size: 13,
                                  color: isSelected ? type.color : AppTheme.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(
                                    type.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                      color: isSelected ? AppTheme.textDark : AppTheme.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),

                // Fast Customer / Bon Name Input with Clear Identity Label
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline_rounded, size: 14, color: AppTheme.primaryTeal),
                            SizedBox(width: 4),
                            Text(
                              'Pembeli:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _customerController,
                          onChanged: widget.onCustomerNameChanged,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Umum (Ketik jika Kasbon/Titip)',
                            hintStyle: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            isDense: true,
                            suffixIcon: _customerController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 13),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      _customerController.clear();
                                      widget.onCustomerNameChanged('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Daftar Belanja Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryTeal, size: 15),
                const SizedBox(width: 5),
                const Text(
                  'Belanjaan',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$totalItemCount Item',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryTeal),
                  ),
                ),
                const Spacer(),

                // Clear / Reset
                if (widget.cartItems.isNotEmpty)
                  InkWell(
                    onTap: widget.onClearCart,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, size: 13, color: AppTheme.dangerRed),
                          SizedBox(width: 2),
                          Text(
                            'Reset',
                            style: TextStyle(fontSize: 10.5, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 3. Cart Items List
          Expanded(
            child: widget.cartItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.bgSubtle,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.storefront_outlined,
                              size: 28,
                              color: AppTheme.textSubtle,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Belum Ada Barang',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Pilih sembako atau scan barcode untuk transaksi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: widget.cartItems.length,
                    separatorBuilder: (context, index) => const Divider(height: 8, color: AppTheme.borderColor),
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Mini Icon
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: item.product.color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(item.product.icon, size: 13, color: item.product.color),
                              ),
                              const SizedBox(width: 6),

                              // Name, Unit & Price
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${AppTheme.formatRupiah(item.unitPrice)}/${item.product.unit}',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                        ),
                                        if (item.isWholesaleApplied) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryTealLight,
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                            child: const Text(
                                              'Grosir',
                                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Stepper (- qty +)
                              Container(
                                height: 22,
                                decoration: BoxDecoration(
                                  color: AppTheme.bgSubtle,
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                child: Row(
                                  children: [
                                    InkWell(
                                      onTap: () => widget.onDecrement(item),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(
                                          item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove,
                                          size: 12,
                                          color: item.quantity == 1 ? AppTheme.dangerRed : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      constraints: const BoxConstraints(minWidth: 16),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${item.quantity}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => widget.onIncrement(item),
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 4),
                                        child: Icon(Icons.add, size: 12, color: AppTheme.primaryTeal),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),

                              // Line Total
                              SizedBox(
                                width: 62,
                                child: Text(
                                  AppTheme.formatRupiah(item.totalPrice),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Note & Grosir Toggle row
                          Padding(
                            padding: const EdgeInsets.only(left: 32, top: 2),
                            child: Row(
                              children: [
                                if (item.note != null && item.note!.isNotEmpty)
                                  Flexible(
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 5),
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningOrangeLight,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: Text(
                                        'Catatan: ${item.note}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          color: Color(0xFF92400E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                InkWell(
                                  onTap: () => _showNoteDialog(item),
                                  borderRadius: BorderRadius.circular(3),
                                  child: Text(
                                    item.note == null || item.note!.isEmpty ? '+ Catatan' : 'Ubah',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // 4. Cart Quick Toolbar (Discount, Hold Order)
          if (widget.cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: const BoxDecoration(
                color: AppTheme.bgSubtle,
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Diskon Button
                  Expanded(
                    child: InkWell(
                      onTap: _showDiscountDialog,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        decoration: BoxDecoration(
                          color: widget.discountPercent > 0 ? AppTheme.primaryTealLight : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: widget.discountPercent > 0 ? AppTheme.primaryTeal : AppTheme.borderColor,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.discount_outlined,
                              size: 12,
                              color: widget.discountPercent > 0 ? AppTheme.primaryTeal : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                widget.discountPercent > 0 ? 'Diskon ${widget.discountPercent.toInt()}%' : 'Diskon',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: widget.discountPercent > 0 ? AppTheme.primaryTeal : AppTheme.textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Hold Order Button
                  Expanded(
                    child: InkWell(
                      onTap: widget.onHoldOrder,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pause_circle_outline_rounded, size: 12, color: AppTheme.warningOrange),
                            SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Tahan Nota',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textDark),
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

          // 5. Total & Bayar Button (Luxury Black & Gold style)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppTheme.borderColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.discountPercent > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                      Text(
                        AppTheme.formatRupiah(subtotal),
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diskon (${widget.discountPercent.toInt()}%)',
                        style: const TextStyle(fontSize: 11.5, color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '- ${AppTheme.formatRupiah(discountAmount)}',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppTheme.dangerRed),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Divider(height: 1, color: AppTheme.borderColor),
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL BAYAR',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: 0.2),
                    ),
                    Text(
                      AppTheme.formatRupiah(grandTotal),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.goldMuted,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: widget.cartItems.isEmpty ? null : widget.onCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.cartItems.isEmpty ? AppTheme.bgSubtle : AppTheme.primaryGold,
                      foregroundColor: widget.cartItems.isEmpty ? AppTheme.textSubtle : AppTheme.primaryDark,
                      elevation: widget.cartItems.isEmpty ? 0 : 3,
                      shadowColor: AppTheme.primaryGold.withValues(alpha: 0.4),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 18,
                          color: widget.cartItems.isEmpty ? AppTheme.textSubtle : AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.cartItems.isEmpty
                              ? 'BELANJAAN KOSONG'
                              : 'BAYAR  •  ${AppTheme.formatRupiah(grandTotal)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: widget.cartItems.isEmpty ? AppTheme.textSubtle : AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
