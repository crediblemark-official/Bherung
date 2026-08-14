import 'package:flutter/material.dart';
import '../models/kasbon_record.dart';
import '../services/apps_script_service.dart';
import '../theme/app_theme.dart';

class BukuKasbonDialog extends StatefulWidget {
  final List<KasbonRecord> kasbonRecords;
  final ValueChanged<KasbonRecord> onKasbonPaid;

  const BukuKasbonDialog({
    super.key,
    required this.kasbonRecords,
    required this.onKasbonPaid,
  });

  @override
  State<BukuKasbonDialog> createState() => _BukuKasbonDialogState();
}

class _BukuKasbonDialogState extends State<BukuKasbonDialog> {
  double get _totalKasbonActive => widget.kasbonRecords
      .where((k) => !k.isPaid)
      .fold(0, (sum, k) => sum + k.amount);

  @override
  Widget build(BuildContext context) {
    final activeKasbonList = widget.kasbonRecords.where((k) => !k.isPaid).toList();
    final paidKasbonList = widget.kasbonRecords.where((k) => k.isPaid).toList();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      titlePadding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      actionsPadding: const EdgeInsets.all(10),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.menu_book_rounded, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Buku Kasbon Pelanggan',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Catatan utang & jatuh tempo',
                  style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.3)),
            ),
            child: Text(
              AppTheme.formatRupiah(_totalKasbonActive),
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 380,
        child: activeKasbonList.isEmpty && paidKasbonList.isEmpty
            ? const Center(child: Text('Belum ada catatan kasbon pelanggan.', style: TextStyle(fontSize: 12)))
            : ListView(
                children: [
                  if (activeKasbonList.isNotEmpty) ...[
                    const Text(
                      'KASBON BELUM LUNAS:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF92400E)),
                    ),
                    const SizedBox(height: 6),
                    ...activeKasbonList.map((kasbon) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kasbon.customerName,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                                  ),
                                  if (kasbon.customerPhone.isNotEmpty)
                                    Text(
                                      'HP: ${kasbon.customerPhone}',
                                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Belanja: ${kasbon.items.map((i) => "${i.product.name} (${i.quantity})").join(", ")}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 2),
                                  if (kasbon.dueDate != null)
                                    Text(
                                      'Jatuh Tempo: ${kasbon.dueDate!.day}/${kasbon.dueDate!.month}/${kasbon.dueDate!.year}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB45309)),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppTheme.formatRupiah(kasbon.amount),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.dangerRed),
                                ),
                                const SizedBox(height: 4),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      kasbon.isPaid = true;
                                    });
                                    widget.onKasbonPaid(kasbon);
                                    AppsScriptService().payKasbon(kasbon.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Kasbon "${kasbon.customerName}" telah DILUNASI.'),
                                        backgroundColor: AppTheme.successGreen,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successGreen,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    minimumSize: Size.zero,
                                  ),
                                  child: const Text('Lunasi', style: TextStyle(fontSize: 10.5)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  if (paidKasbonList.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'RIWAYAT KASBON LUNAS:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 6),
                    ...paidKasbonList.map((kasbon) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSubtle,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                kasbon.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppTheme.formatRupiah(kasbon.amount),
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '[LUNAS]',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.successGreen),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
