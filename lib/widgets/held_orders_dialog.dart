import 'package:flutter/material.dart';
import '../models/held_order.dart';
import '../theme/app_theme.dart';

class HeldOrdersDialog extends StatelessWidget {
  final List<HeldOrder> heldOrders;
  final ValueChanged<HeldOrder> onRestoreOrder;
  final ValueChanged<HeldOrder> onDeleteOrder;

  const HeldOrdersDialog({
    super.key,
    required this.heldOrders,
    required this.onRestoreOrder,
    required this.onDeleteOrder,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      actionsPadding: const EdgeInsets.all(10),
      title: Row(
        children: [
          const Icon(Icons.pause_circle_filled_rounded, color: AppTheme.warningOrange, size: 20),
          const SizedBox(width: 8),
          const Text('Daftar Nota Ditahan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.warningOrangeLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${heldOrders.length} Nota',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: heldOrders.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Tidak ada nota yang sedang ditahan.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: heldOrders.length,
                separatorBuilder: (context, index) => const Divider(height: 8, color: AppTheme.borderColor),
                itemBuilder: (context, index) {
                  final order = heldOrders[index];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    order.customerName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: order.transactionType.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      order.transactionType.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: order.transactionType.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${order.totalItemCount} item • ${AppTheme.formatRupiah(order.total)}',
                                style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => onDeleteOrder(order),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onRestoreOrder(order);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Buka', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(fontSize: 11.5)),
        ),
      ],
    );
  }
}
