import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_navigator.dart';
import '../../models/customer_purchase_bill_model.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_snackbar.dart';
import '../billing/bill_details_screen.dart';
import 'edit_customer_screen.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final String customerId;

  const CustomerDetailsScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomerDetails(widget.customerId);
    });
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse(
      'https://wa.me/91$cleanPhone?text=${Uri.encodeComponent("Hello $name, Greetings from Vahaal Kids Fashion!")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final customer = provider.selectedCustomer;
    final bills = provider.selectedCustomerBills;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading && customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Customer Profile')),
        body: const Center(child: Text('Customer record not found.')),
      );
    }

    final memberSince = customer.createdAt != null
        ? DateFormat('dd MMM yyyy').format(customer.createdAt!)
        : 'Registered Member';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () async {
              final updated = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditCustomerScreen(customer: customer),
                ),
              );
              if (updated == true && mounted) {
                provider.loadCustomerDetails(widget.customerId);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadCustomerDetails(widget.customerId),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          customer.initials,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '📱 ${customer.mobile}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (customer.address != null && customer.address!.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '📍 ${customer.address}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              'Member since $memberSince',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp & Call Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _openWhatsApp(customer.mobile, customer.name),
                          icon: const Icon(Icons.chat_outlined, size: 16, color: Color(0xFF25D366)),
                          label: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: Color(0xFF25D366))),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF25D366)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _callPhone(customer.mobile),
                          icon: const Icon(Icons.call_outlined, size: 16, color: AppColors.primary),
                          label: const Text('Call', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Start New Bill CTA
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<BillProvider>().setCustomer(customer);
                        AppSnackbar.showSuccess(
                          context,
                          'Selected ${customer.name} for POS checkout (Discount memory: ${customer.lastDiscount > 0 ? "₹${customer.lastDiscount.toStringAsFixed(2)}" : "None"}).',
                        );
                        AppNavigator.toPos(context: context);
                      },
                      icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                      label: const Text(
                        'Start New Bill for this Customer',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Financial Statistics Row
                  Row(
                    children: [
                      _DetailStatBox(
                        title: 'Total Spend',
                        value: '${AppConstants.currencySymbol}${customer.totalPurchase.toStringAsFixed(2)}',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _DetailStatBox(
                        title: 'Total Bills',
                        value: '${bills.length} Invoices',
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      _DetailStatBox(
                        title: 'Last Discount',
                        value: customer.lastDiscount > 0
                            ? '${AppConstants.currencySymbol}${customer.lastDiscount.toStringAsFixed(2)}'
                            : 'No Discount',
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Purchase History Invoices Header
            Text(
              'Purchase History & Invoices (${bills.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            if (bills.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No past purchase invoices recorded for this customer yet.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bills.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final bill = bills[index];
                  return _BillHistoryCard(bill: bill);
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailStatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _DetailStatBox({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BillHistoryCard extends StatelessWidget {
  final CustomerPurchaseBill bill;

  const _BillHistoryCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormatted = DateFormat('dd MMM yyyy, hh:mm a').format(bill.billDate);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillDetailsScreen(billId: bill.id),
          ),
        );
      },
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  bill.paymentMethod.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondaryLight,
                  ),
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

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${bill.itemsCount} ${bill.itemsCount == 1 ? "Item" : "Items"} Purchased',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              Row(
                children: [
                  if (bill.discount > 0) ...[
                    Text(
                      'Disc: -${AppConstants.currencySymbol}${bill.discount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    '${AppConstants.currencySymbol}${bill.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
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
}
