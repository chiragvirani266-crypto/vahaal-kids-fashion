import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../providers/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class StockInScreen extends StatefulWidget {
  final String? preselectedVariantId;

  const StockInScreen({super.key, this.preselectedVariantId});

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '10');
  final _referenceController = TextEditingController();
  final _noteController = TextEditingController();

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
        });
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
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
                    'Select Product & Variant',
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
                          subtitle: Text('SKU: ${item.sku} • Stock: ${item.currentStock} units'),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () {
                            setState(() => _selectedItem = item);
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
          content: Text('Please select a product variant for stock in.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity must be greater than 0.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<StockProvider>();
    final success = await provider.stockIn(
      variantId: _selectedItem!.variantId,
      quantity: qty,
      invoiceRef: _referenceController.text.trim().isNotEmpty
          ? _referenceController.text.trim()
          : 'MANUAL-STOCK-IN',
      note: _noteController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added +$qty units to ${_selectedItem!.variantDisplayName}!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final qty = int.tryParse(_quantityController.text.trim()) ?? 0;
    final currentStock = _selectedItem?.currentStock ?? 0;
    final projectedStock = currentStock + qty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Stock In (New Purchase)',
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
              // Variant Selector Card
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
                          color: AppColors.primary.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
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
                              icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                              onPressed: () => _openVariantPicker(provider.stockItems),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Quantity Card
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
                      '2. Quantity to Add',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Quick Chips
                    Wrap(
                      spacing: 8,
                      children: [5, 10, 20, 50, 100].map((add) {
                        return ActionChip(
                          label: Text('+$add Units'),
                          onPressed: () {
                            setState(() {
                              _quantityController.text = add.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    AppTextField(
                      controller: _quantityController,
                      label: 'Stock In Quantity *',
                      hint: 'e.g. 20',
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),

                    // Live Progression Preview
                    if (_selectedItem != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Inventory Update Preview:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                            Text(
                              '$currentStock units ➔ $projectedStock units (+$qty)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reference & Audit Card
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
                      '3. Purchase & Audit Details',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _referenceController,
                      label: 'Invoice / Purchase Order Ref',
                      hint: 'e.g. INV-2026-0042 or Supplier Name',
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _noteController,
                      label: 'Notes / Remarks',
                      hint: 'e.g. Summer restock batch shipment',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Confirm & Add Stock',
                icon: Icons.check_circle_outline_rounded,
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
