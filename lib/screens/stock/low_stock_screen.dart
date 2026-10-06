import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/stock_item_model.dart';
import '../../providers/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading_state.dart';
import '../../widgets/common/app_snackbar.dart';

class LowStockScreen extends StatefulWidget {
  final bool isEmbedded;
  const LowStockScreen({super.key, this.isEmbedded = false});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadLowStockItems();
    });
  }

  void _showQuickRestockDialog(StockItem item) {
    final qtyController = TextEditingController(text: '10');
    final invoiceController = TextEditingController(text: 'RESTOCK-REORDER');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_box_rounded, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Quick Restock: ${item.size} / ${item.color}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: ${item.productName}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Current Stock: ${item.currentStock} Units (Alert at ≤ ${item.lowStockAlert})',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 16),
            TextFormField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quantity to Add *',
                prefixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: invoiceController,
              decoration: const InputDecoration(
                labelText: 'Invoice / Order Reference',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text.trim()) ?? 0;
              if (qty <= 0) return;

              Navigator.of(ctx).pop();
              final success = await context.read<StockProvider>().stockIn(
                variantId: item.variantId,
                quantity: qty,
                invoiceRef: invoiceController.text.trim(),
                note: 'Quick reorder from low stock alert screen',
              );

              if (success && mounted) {
                AppSnackbar.showSuccess(
                  context,
                  'Restocked +$qty units for ${item.variantDisplayName}!',
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Stock'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = provider.lowStockItems;

    final outOfStockCount = items.where((i) => i.status == StockStatus.outOfStock).length;
    final lowStockCount = items.where((i) => i.status == StockStatus.lowStock).length;

    final content = Column(
      children: [
        // Alert Banner Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.errorBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.remove_shopping_cart, size: 14, color: AppColors.error),
                          const SizedBox(width: 6),
                          Text(
                            '$outOfStockCount Out of Stock',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.warningBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text(
                            '$lowStockCount Low Stock',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: provider.isLoading
              ? const AppLoadingState(message: 'Checking stock thresholds...')
              : items.isEmpty
                  ? AppEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      title: 'All Stock Levels Healthy!',
                      description: 'No items are currently below their reorder thresholds.',
                      actionLabel: 'Refresh',
                      onAction: () => provider.loadLowStockItems(refresh: true),
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadLowStockItems(refresh: true),
                      child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final isOutOfStock = item.status == StockStatus.outOfStock;
                            final color = isOutOfStock ? AppColors.error : AppColors.warning;

                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: color.withAlpha(100)),
                              ),
                              child: Row(
                                children: [
                                  // Size Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: color.withAlpha(20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      item.size,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Product Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item.productName} • ${item.color}',
                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'SKU: ${item.sku} • Alert at ≤ ${item.lowStockAlert} units',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Stock Quantity
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${item.currentStock} left',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ElevatedButton(
                                        onPressed: () => _showQuickRestockDialog(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          minimumSize: const Size(70, 30),
                                          elevation: 0,
                                        ),
                                        child: const Text('Restock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Low Stock Alerts',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadLowStockItems(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: content,
    );
  }
}
