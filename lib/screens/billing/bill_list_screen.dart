import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bill_filter_model.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../services/receipt_service.dart';
import '../../theme/app_colors.dart';
import 'bill_details_screen.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BillProvider>();
      _searchController.text = bp.searchQuery;
      bp.fetchBills(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<BillProvider>().loadMoreBills();
    }
  }

  Future<void> _pickCustomDateRange() async {
    final bp = context.read<BillProvider>();
    final initialRange = bp.customDateRange ??
        DateTimeRange(
          start: DateTime.now().subtract(const Duration(days: 7)),
          end: DateTime.now(),
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      bp.setDateFilter(BillDateFilterOption.custom, customRange: picked);
    }
  }

  void _navigateToBillDetails(Bill bill) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BillDetailsScreen(bill: bill),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bp = context.watch<BillProvider>();
    final bills = bp.billsHistory;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Bills & Invoices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Bills',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => bp.fetchBills(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => bp.fetchBills(refresh: true),
        color: AppColors.primary,
        child: Column(
          children: [
            // Top Search & Filter Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search Input Box
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by bill number, customer name, mobile...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      bp.setSearchQuery('');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onSubmitted: (val) => bp.setSearchQuery(val),
                          onChanged: (val) {
                            if (val.isEmpty) {
                              bp.setSearchQuery('');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => bp.setSearchQuery(_searchController.text),
                        child: const Text('Search', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Date Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ...BillDateFilterOption.values.map((option) {
                          final isSelected = bp.activeDateFilter == option;
                          String label = option.label;

                          if (option == BillDateFilterOption.custom &&
                              isSelected &&
                              bp.customDateRange != null) {
                            final startStr = DateFormat('dd MMM').format(bp.customDateRange!.start);
                            final endStr = DateFormat('dd MMM').format(bp.customDateRange!.end);
                            label = '$startStr - $endStr';
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                              ),
                              backgroundColor:
                                  isDark ? AppColors.cardDark : Colors.grey.shade100,
                              onSelected: (_) {
                                if (option == BillDateFilterOption.custom) {
                                  _pickCustomDateRange();
                                } else {
                                  bp.setDateFilter(option);
                                }
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                  // Payment Method Filter Row
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Payment Method: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['All', 'Cash', 'UPI', 'Card', 'Other'].map((method) {
                              final isSelected = bp.paymentFilter.toLowerCase() == method.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                  label: Text(method),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary.withAlpha(30),
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                  ),
                                  backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade100,
                                  onSelected: (_) => bp.setPaymentFilter(method),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Summary Header (Showing Count & Active Filter Information)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: isDark ? AppColors.backgroundDark : Colors.grey.shade200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bp.isHistoryLoading
                        ? 'Loading bills...'
                        : 'Found ${bp.totalCount > 0 ? bp.totalCount : bills.length} ${bills.length == 1 ? "bill" : "bills"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (bp.searchQuery.isNotEmpty ||
                      bp.activeDateFilter != BillDateFilterOption.all ||
                      bp.paymentFilter != 'All')
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        bp.resetFilters();
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.filter_alt_off_rounded, size: 14, color: AppColors.error),
                          SizedBox(width: 4),
                          Text(
                            'Reset Filters',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Main Bills List / Grid
            Expanded(
              child: bp.isHistoryLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Searching bills on server...'),
                        ],
                      ),
                    )
                  : bills.isEmpty
                      ? _buildEmptyState(bp, isDark)
                      : ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: bills.length + (bp.hasMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index == bills.length) {
                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                alignment: Alignment.center,
                                child: bp.isLoadingMore
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : TextButton.icon(
                                        icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                                        label: const Text('Load More Bills'),
                                        onPressed: () => bp.loadMoreBills(),
                                      ),
                              );
                            }

                            final bill = bills[index];
                            return _buildBillCard(bill, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BillProvider bp, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Bills Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              bp.searchQuery.isNotEmpty
                  ? 'No invoices match "${bp.searchQuery}". Try changing search keywords or date range.'
                  : 'No invoices found for the selected filters.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                _searchController.clear();
                bp.resetFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillCard(Bill bill, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    return InkWell(
      onTap: () => _navigateToBillDetails(bill),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Bill Number Badge + Payment Method + Date
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    bill.billNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildPaymentBadge(bill.paymentMethod, isDark),
                const Spacer(),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 2: Customer Name & Mobile
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${bill.displayCustomerName}${bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty ? " • ${bill.customerMobileSnapshot}" : ""}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            // Row 3: Items description preview if items are present
            if (bill.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                bill.items.map((i) => '${i.quantity}x ${i.productNameSnapshot} (${i.sizeSnapshot})').join(', '),
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const Divider(height: 18),

            // Row 4: Financial Breakdown & Quick Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Subtotal: ${AppConstants.currencySymbol}${bill.subtotal.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                        if (bill.discount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• Disc: -${AppConstants.currencySymbol}${bill.discount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${AppConstants.currencySymbol}${bill.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),

                // Quick Action Buttons
                Row(
                  children: [
                    IconButton(
                      tooltip: 'WhatsApp Receipt',
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 20),
                      onPressed: () => ReceiptService.shareOnWhatsApp(context, bill),
                    ),
                    IconButton(
                      tooltip: 'Print Thermal Receipt',
                      icon: const Icon(Icons.print_outlined, color: AppColors.primary, size: 20),
                      onPressed: () => ReceiptService.showThermalReceipt(context, bill),
                    ),
                    IconButton(
                      tooltip: 'View Full Invoice',
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed: () => _navigateToBillDetails(bill),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String method, bool isDark) {
    Color color;
    switch (method.toLowerCase()) {
      case 'cash':
        color = const Color(0xFF10B981);
        break;
      case 'upi':
        color = const Color(0xFF6366F1);
        break;
      case 'card':
        color = const Color(0xFF0EA5E9);
        break;
      default:
        color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
