import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/stock_transaction_model.dart';
import '../../providers/stock_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_text_field.dart';

class StockHistoryScreen extends StatefulWidget {
  final String? preselectedVariantId;

  const StockHistoryScreen({super.key, this.preselectedVariantId});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StockProvider>().loadStockHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final provider = context.read<StockProvider>();
    final initial = DateTimeRange(
      start: provider.filterStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      end: provider.filterEndDate ?? DateTime.now(),
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initial,
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final txTypes = [
      {'label': 'All', 'value': 'All'},
      {'label': 'Stock In', 'value': 'purchase_in'},
      {'label': 'Sales', 'value': 'sale'},
      {'label': 'Returns', 'value': 'return'},
      {'label': 'Adjustments', 'value': 'adjustment'},
      {'label': 'Damage/Loss', 'value': 'damage'},
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Stock Movement Ledger',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            tooltip: 'Filter by Date Range',
            onPressed: () => _pickDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh History',
            onPressed: () => provider.loadStockHistory(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Input
                AppTextField(
                  controller: _searchController,
                  hint: 'Search by reference, product name, SKU, or notes...',
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
                const SizedBox(height: 10),

                // Transaction Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: txTypes.map((t) {
                      final isSelected = provider.selectedTxType == t['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(t['label']!),
                          selected: isSelected,
                          onSelected: (_) => provider.setTxType(t['value']!),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // Active Date Filter Indicator
                if (provider.filterStartDate != null && provider.filterEndDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Filtered: ${DateFormat('dd MMM yyyy').format(provider.filterStartDate!)} - ${DateFormat('dd MMM yyyy').format(provider.filterEndDate!)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => provider.setDateRange(null, null),
                        child: const Text('Clear Date Filter', style: TextStyle(fontSize: 11, color: AppColors.error)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Ledger List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.transactions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off_rounded, size: 56, color: AppColors.textMutedLight),
                              const SizedBox(height: 12),
                              const Text('No stock transactions found for the selected criteria.',
                                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadStockHistory(refresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final tx = provider.transactions[index];
                            return _TransactionTile(tx: tx);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final StockTransaction tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color badgeColor;
    IconData badgeIcon;
    if (tx.transactionType == 'purchase_in') {
      badgeColor = AppColors.success;
      badgeIcon = Icons.add_box_rounded;
    } else if (tx.transactionType == 'sale') {
      badgeColor = AppColors.primary;
      badgeIcon = Icons.point_of_sale_rounded;
    } else if (tx.transactionType == 'return') {
      badgeColor = AppColors.tertiary;
      badgeIcon = Icons.keyboard_return_rounded;
    } else if (tx.transactionType == 'damage') {
      badgeColor = AppColors.error;
      badgeIcon = Icons.broken_image_rounded;
    } else {
      badgeColor = AppColors.secondary;
      badgeIcon = Icons.tune_rounded;
    }

    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(tx.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Type Badge & Timestamp
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(badgeIcon, size: 12, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      tx.typeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                dateFormatted,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product details & Quantity Change
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${tx.productName ?? "Variant"} (${tx.variantSize ?? "-"} / ${tx.variantColor ?? "-"})',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'SKU: ${tx.variantSku ?? "-"} • Ref: ${tx.reference ?? "N/A"}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    if (tx.note != null && tx.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Note: ${tx.note}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tx.quantity >= 0 ? '+${tx.quantity}' : '${tx.quantity}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: tx.quantity >= 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Text(
                    '${tx.previousStock} ➔ ${tx.newStock} units',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
