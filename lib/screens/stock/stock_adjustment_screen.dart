import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../providers/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

enum AdjustmentMode {
  setExactCount,
  damageWriteOff,
  manualCorrection,
}

class StockAdjustmentScreen extends StatefulWidget {
  final String? preselectedVariantId;

  const StockAdjustmentScreen({super.key, this.preselectedVariantId});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _targetCountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _referenceController = TextEditingController(text: 'AUDIT-ADJUSTMENT');

  AdjustmentMode _mode = AdjustmentMode.setExactCount;
  StockItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StockProvider>();
      if (provider.stockItems.isEmpty) {
        provider.loadStockItems().then((_) => _resolvePreselected());
      } else {
        _resolvePreselected();
      }
    });
  }

  void _resolvePreselected() {
    if (widget.preselectedVariantId != null) {
      final provider = context.read<StockProvider>();
      final match = provider.stockItems.where((i) => i.variantId == widget.preselectedVariantId).firstOrNull;
      if (match != null) {
        setState(() {
          _selectedItem = match;
          _targetCountController.text = match.currentStock.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _targetCountController.dispose();
    _reasonController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _openVariantPicker(List<StockItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String search = '';
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final filtered = items.where((i) {
              final q = search.toLowerCase();
              return i.productName.toLowerCase().contains(q) ||
                  i.sku.toLowerCase().contains(q) ||
                  i.barcode.toLowerCase().contains(q) ||
                  i.size.toLowerCase().contains(q) ||
                  i.color.toLowerCase().contains(q);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Product & Variant for Adjustment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    hint: 'Search by name, SKU, size, color...',
                    prefixIcon: Icons.search_rounded,
                    onChanged: (val) {
                      setModalState(() => search = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${item.productName} (${item.size} / ${item.color})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text('SKU: ${item.sku} • Current Stock: ${item.currentStock} units'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () {
                            setState(() {
                              _selectedItem = item;
                              _targetCountController.text = item.currentStock.toString();
                            });
                            Navigator.of(modalCtx).pop();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product variant to adjust.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final currentStock = _selectedItem!.currentStock;
    int targetStock = 0;
    int diff = 0;

    if (_mode == AdjustmentMode.setExactCount) {
      targetStock = int.tryParse(_targetCountController.text.trim()) ?? 0;
      diff = targetStock - currentStock;
    } else if (_mode == AdjustmentMode.damageWriteOff) {
      final damagedQty = int.tryParse(_targetCountController.text.trim()) ?? 0;
      if (damagedQty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Damaged quantity must be > 0')),
        );
        return;
      }
      targetStock = currentStock - damagedQty;
      diff = -damagedQty;
    } else {
      final change = int.tryParse(_targetCountController.text.trim()) ?? 0;
      targetStock = currentStock + change;
      diff = change;
    }

    if (targetStock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Target stock cannot be negative.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show Confirmation Dialog before applying
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 10),
            Text('Confirm Stock Adjustment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Variant: ${_selectedItem!.variantDisplayName}'),
            const SizedBox(height: 8),
            Text('Current Stock: $currentStock Units'),
            Text('Stock Change: ${diff >= 0 ? "+$diff" : "$diff"} Units'),
            Text('New Final Stock: $targetStock Units', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Reason: ${_reasonController.text.trim().isNotEmpty ? _reasonController.text.trim() : "Physical count verification"}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Apply Adjustment'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<StockProvider>();
      final success = await provider.stockAdjustment(
        variantId: _selectedItem!.variantId,
        targetStock: targetStock,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : 'Stock audit adjustment',
        reference: _referenceController.text.trim().isNotEmpty
            ? _referenceController.text.trim()
            : 'AUDIT-ADJUSTMENT',
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock updated to $targetStock units!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final currentStock = _selectedItem?.currentStock ?? 0;
    final enteredVal = int.tryParse(_targetCountController.text.trim()) ?? 0;
    int calculatedNewStock = currentStock;

    if (_mode == AdjustmentMode.setExactCount) {
      calculatedNewStock = enteredVal;
    } else if (_mode == AdjustmentMode.damageWriteOff) {
      calculatedNewStock = currentStock - enteredVal;
    } else {
      calculatedNewStock = currentStock + enteredVal;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Stock Adjustment / Audit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Variant Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. Target Product & Variant',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedItem == null)
                      OutlinedButton.icon(
                        onPressed: () => _openVariantPicker(provider.stockItems),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Search & Select Variant'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.secondary.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedItem!.size,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_selectedItem!.productName} (${_selectedItem!.color})',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'SKU: ${_selectedItem!.sku} • Current Stock: ${_selectedItem!.currentStock} Units',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.secondary),
                              onPressed: () => _openVariantPicker(provider.stockItems),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Adjustment Mode Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. Adjustment Type',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<AdjustmentMode>(
                      value: AdjustmentMode.setExactCount,
                      groupValue: _mode,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Physical Count Audit (Set Exact Count)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Overrides current stock to match physical shelf count', style: TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setState(() {
                          _mode = val!;
                          _targetCountController.text = currentStock.toString();
                        });
                      },
                    ),
                    RadioListTile<AdjustmentMode>(
                      value: AdjustmentMode.damageWriteOff,
                      groupValue: _mode,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Damage / Defect Write-Off', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Deducts unsellable, stained, or damaged garments', style: TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setState(() {
                          _mode = val!;
                          _targetCountController.text = '1';
                        });
                      },
                    ),
                    RadioListTile<AdjustmentMode>(
                      value: AdjustmentMode.manualCorrection,
                      groupValue: _mode,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Manual Delta (+ / -)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text('Add or subtract specific amount directly', style: TextStyle(fontSize: 12)),
                      onChanged: (val) {
                        setState(() {
                          _mode = val!;
                          _targetCountController.text = '0';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Value & Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mode == AdjustmentMode.setExactCount
                          ? '3. Enter Counted Stock'
                          : (_mode == AdjustmentMode.damageWriteOff
                              ? '3. Enter Damaged Quantity'
                              : '3. Enter Adjustment Quantity (+/-)'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _targetCountController,
                      label: _mode == AdjustmentMode.setExactCount
                          ? 'Final Stock on Shelf'
                          : 'Quantity',
                      keyboardType: const TextInputType.numberWithOptions(signed: true),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Progression Breakdown
                    if (_selectedItem != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: calculatedNewStock < 0 ? AppColors.errorBg : AppColors.infoBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Inventory Update:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: calculatedNewStock < 0 ? AppColors.error : AppColors.info,
                              ),
                            ),
                            Text(
                              '$currentStock units ➔ $calculatedNewStock units',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: calculatedNewStock < 0 ? AppColors.error : AppColors.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason & Audit Note
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4. Reason & Reference',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _reasonController,
                      label: 'Adjustment Reason / Note *',
                      hint: 'e.g. Monthly stock audit count discrepancy or Stained during trial',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please provide a reason for stock adjustment';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _referenceController,
                      label: 'Audit Reference Code',
                      hint: 'AUDIT-2026-OCT',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Confirm & Apply Adjustment',
                icon: Icons.check_circle_outline_rounded,
                backgroundColor: AppColors.secondary,
                isLoading: provider.isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
