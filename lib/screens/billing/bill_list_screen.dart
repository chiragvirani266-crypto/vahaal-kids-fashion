import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bill_filter_model.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../services/receipt_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading_state.dart';
import 'bill_details_screen.dart';

class BillListScreen extends StatefulWidget {
  final bool isEmbedded;

  const BillListScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTableView = true;

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final content = Column(
      children: [
        // Workstation Embedded Header
        if (widget.isEmbedded)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Invoices & Billing History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${bp.totalCount > 0 ? bp.totalCount : bills.length} records • Realtime Supabase Ledger',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (isDesktop) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.table_chart_rounded, size: 16),
                        label: Text('Table', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.view_agenda_rounded, size: 16),
                        label: Text('Cards', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_isTableView},
                    onSelectionChanged: (set) => setState(() => _isTableView = set.first),
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  tooltip: 'Refresh Bills',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => bp.fetchBills(refresh: true),
                ),
              ],
            ),
          ),

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

        // Main Bills List / Grid / Desktop Table
        Expanded(
          child: bp.isHistoryLoading
              ? const AppLoadingState(message: 'Searching bills on server...')
              : bills.isEmpty
                  ? AppEmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No Bills Found',
                      description: bp.searchQuery.isNotEmpty
                          ? 'No invoices match "${bp.searchQuery}". Try changing search keywords or date range.'
                          : 'No invoices found for the selected filters.',
                      actionLabel: 'Reset All Filters',
                      actionIcon: Icons.clear_all_rounded,
                      onAction: () {
                        _searchController.clear();
                        bp.resetFilters();
                      },
                    )
                  : (isDesktop && _isTableView
                      ? _buildDesktopTable(context, bills, isDark)
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
                        )),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Container(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: content,
      );
    }

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
          if (isDesktop)
            IconButton(
              icon: Icon(_isTableView ? Icons.view_agenda_rounded : Icons.table_chart_rounded),
              tooltip: _isTableView ? 'Switch to Cards View' : 'Switch to Data Table',
              onPressed: () => setState(() => _isTableView = !_isTableView),
            ),
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
        child: content,
      ),
    );
  }

  // ==========================================
  // RESPONSIVE DESKTOP INVOICES TABLE
  // ==========================================
  Widget _buildDesktopTable(BuildContext context, List<Bill> bills, bool isDark) {
    final bp = context.watch<BillProvider>();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 920),
                  child: DataTable(
                    headingRowHeight: 48,
                    dataRowMinHeight: 56,
                    dataRowMaxHeight: 64,
                    headingRowColor: WidgetStateProperty.all(
                      isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Bill No', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Items', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Discount', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: bills.map((bill) {
                      return DataRow(
                        cells: [
                          // Bill Number Badge
                          DataCell(
                            InkWell(
                              onTap: () => _navigateToBillDetails(bill),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  bill.billNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Date & Time
                          DataCell(
                            Text(
                              dateFormat.format(bill.billDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          // Customer Name & Mobile
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  bill.displayCustomerName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty)
                                  Text(
                                    bill.customerMobileSnapshot!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Items Count
                          DataCell(
                            Text(
                              '${bill.items.length} ${bill.items.length == 1 ? "item" : "items"}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          // Subtotal
                          DataCell(
                            Text(
                              '${AppConstants.currencySymbol}${bill.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          // Discount
                          DataCell(
                            bill.discount > 0
                                ? Text(
                                    '-${AppConstants.currencySymbol}${bill.discount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : const Text('-', style: TextStyle(color: Colors.grey)),
                          ),
                          // Grand Total
                          DataCell(
                            Text(
                              '${AppConstants.currencySymbol}${bill.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          // Payment Badge
                          DataCell(_buildPaymentBadge(bill.paymentMethod, isDark)),
                          // Actions
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.visibility_outlined, size: 18),
                                  tooltip: 'View Bill Details',
                                  onPressed: () => _navigateToBillDetails(bill),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.secondary),
                                  tooltip: 'Print Thermal Receipt',
                                  onPressed: () => ReceiptService.showThermalReceipt(context, bill),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                                  tooltip: 'Share via WhatsApp',
                                  onPressed: () => ReceiptService.showWhatsAppShareModal(context, bill),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          if (bp.hasMore)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: bp.isLoadingMore
                  ? const CircularProgressIndicator()
                  : TextButton.icon(
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: const Text('Load More Invoices'),
                      onPressed: () => bp.loadMoreBills(),
                    ),
            ),
        ],
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
