import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/customer_model.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_text_field.dart';
import 'add_customer_screen.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Customer Directory',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadCustomers(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddCustomerScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Top Search & Sort Header
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
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        hint: 'Search by customer name, mobile number...',
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
                    ),
                    const SizedBox(width: 10),
                    // Sort Dropdown
                    PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: const Icon(Icons.sort_rounded, color: AppColors.primary, size: 20),
                      ),
                      tooltip: 'Sort Customers',
                      onSelected: (opt) => provider.setSortBy(opt),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'newest', child: Text('Newest Registered')),
                        const PopupMenuItem(value: 'nameAsc', child: Text('Name (A-Z)')),
                        const PopupMenuItem(value: 'purchasesHighLow', child: Text('Highest Spend')),
                        const PopupMenuItem(value: 'billsHighLow', child: Text('Most Visits / Bills')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Mini KPI Strip
                Row(
                  children: [
                    _MiniKpi(
                      label: 'Total Members',
                      value: '${provider.totalCustomersCount}',
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    _MiniKpi(
                      label: 'Total Sales',
                      value: '${AppConstants.currencySymbol}${provider.totalLifetimeSpend.toStringAsFixed(0)}',
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    _MiniKpi(
                      label: 'Avg Spend',
                      value: '${AppConstants.currencySymbol}${provider.averageCustomerSpend.toStringAsFixed(0)}',
                      color: AppColors.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Customer List
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.customers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_outlined, size: 56, color: AppColors.textMutedLight),
                              const SizedBox(height: 12),
                              const Text('No customers found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              const Text('Add new customer records or adjust your search filter.',
                                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondaryLight)),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadCustomers(refresh: true),
                        child: isDesktop
                            ? _buildDesktopGrid(context, provider.customers)
                            : _buildMobileList(context, provider.customers),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<Customer> customers) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(customer: customer);
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context, List<Customer> customers) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 160,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        return _CustomerCard(customer: customer);
      },
    );
  }
}

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;

  const _CustomerCard({required this.customer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CustomerDetailsScreen(customerId: customer.id!),
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
        child: Row(
          children: [
            // Initials Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withAlpha(25),
              child: Text(
                customer.initials,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name, Mobile, Address
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    customer.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.phone_iphone_rounded, size: 13, color: AppColors.textSecondaryLight),
                      const SizedBox(width: 4),
                      Text(
                        customer.mobile,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  if (customer.address != null && customer.address!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      customer.address!,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Financial & Visits Info
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${AppConstants.currencySymbol}${customer.totalPurchase.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    customer.lastDiscount > 0
                        ? 'Last Disc: ${AppConstants.currencySymbol}${customer.lastDiscount.toStringAsFixed(0)}'
                        : 'No Disc',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMutedLight),
          ],
        ),
      ),
    );
  }
}
