import 'package:flutter/material.dart';
import '../models/held_order.dart';
import '../theme/app_theme.dart';

class HeldOrdersScreen extends StatelessWidget {
  final List<HeldOrder> heldOrders;
  final ValueChanged<HeldOrder> onRestoreOrder;
  final ValueChanged<HeldOrder> onDeleteOrder;

  const HeldOrdersScreen({
    super.key,
    required this.heldOrders,
    required this.onRestoreOrder,
    required this.onDeleteOrder,
  });

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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Nota Belanja Ditahan',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              'Antrian transaksi pelanggan yang sedang ditunda',
              style: TextStyle(color: AppTheme.goldAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: heldOrders.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pause_circle_outline_rounded, size: 56, color: AppTheme.textSubtle),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada transaksi yang sedang ditahan.',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tekan tombol "Hold" di kasir saat pelanggan ingin menambah barang lain.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: heldOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final order = heldOrders[index];

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryGold.withValues(alpha: 0.15),
                              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.goldMuted, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          order.customerName,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: order.transactionType.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          order.transactionType.label,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                            color: order.transactionType.color,
                                          ),
                                        ),
                                      ),
                                      if (order.branchName != null && order.branchName!.isNotEmpty) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0F2FE),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '📍 ${order.branchName}',
                                            style: const TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0369A1),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.totalItemCount} item • Total: ${AppTheme.formatRupiah(order.total)}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.goldMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.items.map((i) => "${i.product.name} (x${i.quantity})").join(", "),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.dangerRed),
                              onPressed: () => onDeleteOrder(order),
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                onRestoreOrder(order);
                              },
                              icon: const Icon(Icons.play_arrow_rounded, size: 16),
                              label: const Text('Buka Kasir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGold,
                                foregroundColor: AppTheme.primaryDark,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
