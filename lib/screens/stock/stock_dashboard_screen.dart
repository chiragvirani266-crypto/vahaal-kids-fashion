import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/stock_item_model.dart';
import '../../providers/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_text_field.dart';
import 'low_stock_screen.dart';
import 'stock_adjustment_screen.dart';
import 'stock_history_screen.dart';
import 'stock_in_screen.dart';

class StockDashboardScreen extends StatefulWidget {
  const StockDashboardScreen({super.key});

  @override
  State<StockDashboardScreen> createState() => _StockDashboardScreenState();
}

class _StockDashboardScreenState extends State<StockDashboardScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadStockDashboard();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Stock Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Inventory',
            onPressed: () => provider.loadStockDashboard(refresh: true),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Stock Movement History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StockHistoryScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Row
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = isDesktop ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isDesktop ? 2.2 : 2.6,
                  children: [
                    _StockKpiCard(
                      title: 'Total Stock Units',
                      value: '${provider.totalStockUnits} Units',
                      subtitle: '${provider.stockItems.length} active variants',
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.primary,
                    ),
                    _StockKpiCard(
                      title: 'Inventory Valuation',
                      value: '${AppConstants.currencySymbol}${provider.totalValuation.toStringAsFixed(0)}',
                      subtitle: 'At purchase cost',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.secondary,
                    ),
                    _StockKpiCard(
                      title: 'Low Stock Alert',
                      value: '${provider.lowStockCount} Variants',
                      subtitle: 'Below threshold',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LowStockScreen()),
                        );
                      },
                    ),
                    _StockKpiCard(
                      title: 'Out of Stock',
                      value: '${provider.outOfStockCount} Variants',
                      subtitle: 'Immediate reorder needed',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: AppColors.error,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LowStockScreen()),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Action Buttons Strip
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickActionButton(
                    icon: Icons.add_box_rounded,
                    label: 'Stock In (Purchase)',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StockInScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _QuickActionButton(
                    icon: Icons.tune_rounded,
                    label: 'Stock Adjustment',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StockAdjustmentScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _QuickActionButton(
                    icon: Icons.warning_amber_rounded,
                    label: 'Low Stock (${provider.lowStockCount})',
                    color: AppColors.warning,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LowStockScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  _QuickActionButton(
                    icon: Icons.history_rounded,
                    label: 'Movement Ledger',
                    color: AppColors.tertiary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const StockHistoryScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live Inventory Table Header & Filters
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Stock Inventory',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  AppTextField(
                    controller: _searchController,
                    hint: 'Search by product name, SKU, barcode, size, color...',
                    prefixIcon: Icons.search_rounded,
                    suffix: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              provider.setSearchQuery('');
                            },
                          )
                        : null,
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                  const SizedBox(height: 12),

                  // Category & Size Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Categories
                        ...provider.availableCategories.map((cat) {
                          final isSelected = provider.selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (_) => provider.setCategory(cat),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(width: 8),

                        // Size filter dropdown / chips
                        ...['All', ...AppConstants.ageGroups.take(6)].map((sz) {
                          final isSelected = provider.selectedSize == sz;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(sz),
                              selected: isSelected,
                              onSelected: (_) => provider.setSize(sz),
                              selectedColor: AppColors.secondary,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Inventory Table
                  if (provider.isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (provider.stockItems.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No inventory items match the active filters.',
                          style: TextStyle(color: AppColors.textSecondaryLight),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.stockItems.length,
                      separatorBuilder: (_, __) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final item = provider.stockItems[index];
                        return _StockItemTile(item: item);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StockKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMutedLight),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}

class _StockItemTile extends StatelessWidget {
  final StockItem item;

  const _StockItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color statusColor;
    if (item.status == StockStatus.outOfStock) {
      statusColor = AppColors.error;
    } else if (item.status == StockStatus.lowStock) {
      statusColor = AppColors.warning;
    } else {
      statusColor = AppColors.success;
    }

    return Row(
      children: [
        // Size Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.size,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Product & SKU Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.productName} • ${item.color}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                'SKU: ${item.sku} • Barcode: ${item.barcode}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ),

        // Current Stock & Status Badge
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${item.currentStock} in stock',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.statusLabel,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),

        // Action Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (action) {
            if (action == 'stock_in') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockInScreen(preselectedVariantId: item.variantId),
                ),
              );
            } else if (action == 'adjust') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockAdjustmentScreen(preselectedVariantId: item.variantId),
                ),
              );
            } else if (action == 'history') {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StockHistoryScreen(preselectedVariantId: item.variantId),
                ),
              );
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'stock_in',
              child: Row(
                children: [
                  Icon(Icons.add_box_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Stock In'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'adjust',
              child: Row(
                children: [
                  Icon(Icons.tune_outlined, size: 18, color: AppColors.secondary),
                  SizedBox(width: 8),
                  Text('Adjust / Correct'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history_rounded, size: 18, color: AppColors.tertiary),
                  SizedBox(width: 8),
                  Text('View History'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
