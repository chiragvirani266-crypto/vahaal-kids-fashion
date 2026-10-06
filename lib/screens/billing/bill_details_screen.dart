import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../services/receipt_service.dart';
import '../../theme/app_colors.dart';

class BillDetailsScreen extends StatefulWidget {
  final Bill? bill;
  final String? billId;

  const BillDetailsScreen({
    super.key,
    this.bill,
    this.billId,
  }) : assert(bill != null || billId != null, 'Either bill or billId must be provided');

  @override
  State<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends State<BillDetailsScreen> {
  Bill? _currentBill;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentBill = widget.bill;
    if (_currentBill == null || _currentBill!.items.isEmpty) {
      _loadBillData();
    }
  }

  Future<void> _loadBillData() async {
    final targetId = widget.billId ?? widget.bill?.id;
    if (targetId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final billProvider = context.read<BillProvider>();
    final fetched = await billProvider.fetchBillDetails(targetId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (fetched != null) {
          _currentBill = fetched;
        } else {
          _errorMessage = 'Could not load bill details from server.';
        }
      });
    }
  }

  Future<void> _callPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Bill Details')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Fetching invoice details...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _currentBill == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(title: const Text('Bill Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Bill not found.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                  onPressed: _loadBillData,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bill = _currentBill!;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          bill.billNumber,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy Bill Text',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: () => ReceiptService.copyToClipboard(context, bill),
          ),
          IconButton(
            tooltip: 'Share on WhatsApp',
            icon: const Icon(Icons.share_rounded, size: 20),
            onPressed: () => ReceiptService.shareOnWhatsApp(context, bill),
          ),
          IconButton(
            tooltip: 'Print Thermal Receipt',
            icon: const Icon(Icons.print_rounded, size: 20),
            onPressed: () => ReceiptService.showThermalReceipt(context, bill),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Info Card
            _buildInvoiceHeaderCard(bill, formattedDate, isDark),
            const SizedBox(height: 16),

            // Customer Details Card
            _buildCustomerCard(bill, isDark),
            const SizedBox(height: 16),

            // Purchased Items Table / List
            _buildItemsCard(bill, isDark),
            const SizedBox(height: 16),

            // Financial Summary Card
            _buildFinancialSummaryCard(bill, isDark),
            const SizedBox(height: 16),

            // Cashier and Notes Card (if present)
            if ((bill.cashierName != null && bill.cashierName!.isNotEmpty) ||
                (bill.notes != null && bill.notes!.isNotEmpty)) ...[
              _buildNotesAndCashierCard(bill, isDark),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActionBar(bill, isDark),
    );
  }

  Widget _buildInvoiceHeaderCard(Bill bill, String formattedDate, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      bill.billNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPaymentBadge(bill.paymentMethod, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
              const SizedBox(width: 6),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const Spacer(),
              Text(
                '${bill.totalItemsCount} ${bill.totalItemsCount == 1 ? "Item" : "Items"} (${bill.totalUnitsCount} Units)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String method, bool isDark) {
    Color bg;
    Color fg;
    IconData icon;

    switch (method.toLowerCase()) {
      case 'cash':
        bg = const Color(0xFF10B981).withAlpha(25);
        fg = const Color(0xFF10B981);
        icon = Icons.payments_rounded;
        break;
      case 'upi':
        bg = const Color(0xFF6366F1).withAlpha(25);
        fg = const Color(0xFF6366F1);
        icon = Icons.qr_code_rounded;
        break;
      case 'card':
        bg = const Color(0xFF0EA5E9).withAlpha(25);
        fg = const Color(0xFF0EA5E9);
        icon = Icons.credit_card_rounded;
        break;
      default:
        bg = AppColors.secondary.withAlpha(25);
        fg = AppColors.secondary;
        icon = Icons.account_balance_wallet_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 14),
          const SizedBox(width: 5),
          Text(
            method.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(Bill bill, bool isDark) {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Customer Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withAlpha(30),
                child: Text(
                  bill.displayCustomerName.isNotEmpty
                      ? bill.displayCustomerName.substring(0, 1).toUpperCase()
                      : 'W',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bill.displayCustomerName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty
                          ? bill.customerMobileSnapshot!
                          : 'Walk-in Customer (No phone attached)',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty) ...[
                IconButton(
                  tooltip: 'Call Customer',
                  icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                  onPressed: () => _callPhone(bill.customerMobileSnapshot!),
                ),
                IconButton(
                  tooltip: 'Share on WhatsApp',
                  icon: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF25D366), size: 20),
                  onPressed: () => ReceiptService.shareOnWhatsApp(context, bill),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Bill bill, bool isDark) {
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Purchased Items',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${bill.items.length} ${bill.items.length == 1 ? "Product" : "Products"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: bill.items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = bill.items[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productNameSnapshot,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Size: ${item.sizeSnapshot}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Color: ${item.colorSnapshot}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                            if (item.skuSnapshot.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'SKU: ${item.skuSnapshot}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${item.quantity} x ${AppConstants.currencySymbol}${item.unitPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(Bill bill, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 20),
          _summaryRow('Subtotal', '${AppConstants.currencySymbol}${bill.subtotal.toStringAsFixed(2)}', isDark),
          if (bill.discount > 0) ...[
            const SizedBox(height: 8),
            _summaryRow(
              'Discount Applied',
              '-${AppConstants.currencySymbol}${bill.discount.toStringAsFixed(2)}',
              isDark,
              color: AppColors.secondary,
              isBold: true,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withAlpha(50)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Grand Total Paid',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${bill.grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesAndCashierCard(Bill bill, bool isDark) {
    return Container(
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
          if (bill.cashierName != null && bill.cashierName!.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Billed by: ${bill.cashierName}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
          if (bill.notes != null && bill.notes!.isNotEmpty) ...[
            if (bill.cashierName != null && bill.cashierName!.isNotEmpty)
              const Divider(height: 16),
            Text(
              'Remarks / Notes:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              bill.notes!,
              style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Bill bill, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // WhatsApp Share
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                label: const Text('WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ReceiptService.shareOnWhatsApp(context, bill),
              ),
            ),
            const SizedBox(width: 8),

            // Print Receipt
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print_rounded, size: 18),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ReceiptService.showThermalReceipt(context, bill),
              ),
            ),
            const SizedBox(width: 8),

            // Reprint Duplicate Copy
            Expanded(
              flex: 3,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Reprint'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : AppColors.textPrimaryLight,
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ReceiptService.showThermalReceipt(context, bill, isReprint: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
