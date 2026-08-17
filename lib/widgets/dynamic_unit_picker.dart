import 'package:flutter/material.dart';
import '../services/inventory_storage_service.dart';
import '../theme/app_theme.dart';

class DynamicUnitPicker extends StatefulWidget {
  final String selectedUnit;
  final ValueChanged<String> onUnitSelected;
  final List<String>? initialUnits;

  const DynamicUnitPicker({
    super.key,
    required this.selectedUnit,
    required this.onUnitSelected,
    this.initialUnits,
  });

  @override
  State<DynamicUnitPicker> createState() => _DynamicUnitPickerState();
}

class _DynamicUnitPickerState extends State<DynamicUnitPicker> {
  List<String> _units = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final loaded = await InventoryStorageService().loadUnits();
    if (widget.initialUnits != null) {
      for (final u in widget.initialUnits!) {
        if (!loaded.contains(u.toLowerCase())) {
          loaded.add(u.toLowerCase());
        }
      }
    }
    if (mounted) {
      setState(() {
        _units = loaded;
        _isLoading = false;
      });
    }
  }

  void _openUnitPickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _UnitPickerSheet(
        units: _units,
        selectedUnit: widget.selectedUnit,
        onUnitSelected: (unit) {
          widget.onUnitSelected(unit);
          Navigator.pop(ctx);
        },
        onUnitCreated: (newUnit) async {
          final clean = newUnit.trim().toLowerCase();
          await InventoryStorageService().saveCustomUnit(clean);
          setState(() {
            if (!_units.contains(clean)) {
              _units.add(clean);
            }
          });
          widget.onUnitSelected(clean);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.selectedUnit,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );
    }

    return InkWell(
      onTap: () => _openUnitPickerModal(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(Icons.straighten_rounded, size: 14, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.selectedUnit.isEmpty ? 'pcs' : widget.selectedUnit,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 20, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _UnitPickerSheet extends StatefulWidget {
  final List<String> units;
  final String selectedUnit;
  final ValueChanged<String> onUnitSelected;
  final ValueChanged<String> onUnitCreated;

  const _UnitPickerSheet({
    required this.units,
    required this.selectedUnit,
    required this.onUnitSelected,
    required this.onUnitCreated,
  });

  @override
  State<_UnitPickerSheet> createState() => _UnitPickerSheetState();
}

class _UnitPickerSheetState extends State<_UnitPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleAddNew() {
    final clean = _query.trim().toLowerCase();
    if (clean.isNotEmpty) {
      widget.onUnitCreated(clean);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final cleanQuery = _query.trim().toLowerCase();

    final filteredUnits = widget.units.where((u) {
      if (cleanQuery.isEmpty) return true;
      return u.toLowerCase().contains(cleanQuery);
    }).toList();

    final bool isExactMatch = widget.units.any((u) => u.toLowerCase() == cleanQuery);
    final bool canAddNew = cleanQuery.isNotEmpty && !isExactMatch;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 16,
        right: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (isKeyboardOpen ? 0.85 : 0.65),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: AppTheme.primaryDark, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pilih / Cari Satuan Produk',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            autofocus: false,
            onChanged: (val) => setState(() => _query = val),
            onSubmitted: (_) {
              if (canAddNew) {
                _handleAddNew();
              } else if (filteredUnits.isNotEmpty) {
                widget.onUnitSelected(filteredUnits.first);
              }
            },
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Cari atau ketik satuan baru (cth: sachet, karton, ikat)...',
              hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppTheme.textMuted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryDark, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol Tambah Satuan Baru jika belum ada
          if (canAddNew) ...[
            InkWell(
              onTap: _handleAddNew,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: 'Simpan satuan baru: ',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                          children: [
                            TextSpan(
                              text: '"$cleanQuery"',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF16A34A)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // List / Wrap Satuan
          Expanded(
            child: filteredUnits.isEmpty && !canAddNew
                ? const Center(
                    child: Text(
                      'Satuan tidak ditemukan',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredUnits.map((unit) {
                        final isSelected = widget.selectedUnit.toLowerCase() == unit.toLowerCase();
                        return InkWell(
                          onTap: () => widget.onUnitSelected(unit),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryDark : AppTheme.bgSubtle,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryDark : AppTheme.borderColor,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.primaryGold),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  unit,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    color: isSelected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
