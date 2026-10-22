import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_colors.dart';
import '../customers/customer_list_screen.dart';
import '../inventory/product_list_screen.dart';
import '../stock/low_stock_screen.dart';
import 'widgets/sales_line_chart_card.dart';
import 'widgets/top_customers_card.dart';
import 'widgets/top_selling_products_card.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  final bool isEmbedded;

  const SalesAnalyticsScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();
    final overview = provider.overview;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    final avgBillValue =
        overview.totalBillsCount > 0 ? (overview.totalSales / overview.totalBillsCount) : 0.0;

    final body = SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Executive Store & Sales Performance KPI Grid (Same Design as Dashboard)
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 3 : 2),
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: isDesktop ? 1.7 : (size.width > 600 ? 1.55 : 1.3),
              children: [
                // 1. This Month Sales
                _AnalyticsKpiCard(
                  title: 'This Month Sales',
                  value: '₹${overview.monthSales.toStringAsFixed(2)}',
                  subtitle: '${overview.monthBillsCount} bills this month',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.secondary,
                ),
                // 2. This Year Sales
                _AnalyticsKpiCard(
                  title: 'This Year Sales',
                  value: '₹${overview.yearSales.toStringAsFixed(2)}',
                  subtitle: '${overview.yearBillsCount} bills in ${DateTime.now().year}',
                  icon: Icons.auto_graph_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
                // 3. Lifetime Sales
                _AnalyticsKpiCard(
                  title: 'Lifetime Sales',
                  value: '₹${overview.totalSales.toStringAsFixed(2)}',
                  subtitle: '${overview.totalBillsCount} total bills',
                  icon: Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF10B981),
                ),
                // 4. Average Ticket
                _AnalyticsKpiCard(
                  title: 'Average Ticket',
                  value: '₹${avgBillValue.toStringAsFixed(2)}',
                  subtitle: 'Avg spend per invoice',
                  icon: Icons.payments_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
                // 5. Products Catalog
                _AnalyticsKpiCard(
                  title: 'Products Catalog',
                  value: '${overview.totalProductsCount} Products',
                  subtitle: '${overview.totalStockUnits} units in stock',
                  icon: Icons.checkroom_rounded,
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductListScreen()),
                    );
                  },
                ),
                // 6. Low Stock Alert
                _AnalyticsKpiCard(
                  title: 'Low Stock Alert',
                  value: '${overview.lowStockCount} Items',
                  subtitle: overview.lowStockCount > 0 ? 'Needs reorder' : 'Stock levels healthy',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LowStockScreen()),
                    );
                  },
                ),
                // 7. Store Customers
                _AnalyticsKpiCard(
                  title: 'Store Customers',
                  value: '${overview.totalCustomersCount} Members',
                  subtitle: 'Registered buyers',
                  icon: Icons.people_alt_rounded,
                  color: AppColors.tertiary,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomerListScreen()),
                    );
                  },
                ),
                // 8. Today's Reference
                _AnalyticsKpiCard(
                  title: "Today's Sales",
                  value: '₹${overview.todaySales.toStringAsFixed(2)}',
                  subtitle: '${overview.todayBillsCount} bills today',
                  icon: Icons.today_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Interactive Sales Trend Graph (Daily, Monthly, Yearly + Custom Range)
            const SalesLineChartCard(enableDateRangePicker: true),
            const SizedBox(height: 24),

            // Top Products & VIP Customers Side by Side on Desktop
            if (isDesktop)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: TopSellingProductsCard()),
                  SizedBox(width: 16),
                  Expanded(child: TopCustomersCard()),
                ],
              )
            else ...[
              const TopSellingProductsCard(),
              const SizedBox(height: 16),
              const TopCustomersCard(),
            ],

            const SizedBox(height: 24),

            // Low Stock Action Banner (Redesigned)
            if (overview.lowStockCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            AppColors.warning.withValues(alpha: 0.12),
                            const Color(0xFF1E1B18),
                          ]
                        : [
                            const Color(0xFFFFFBEB),
                            const Color(0xFFFEF3C7),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: isDark ? 0.35 : 0.45),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warning.withValues(alpha: isDark ? 0.1 : 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 560;

                      final iconAndText = Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${overview.lowStockCount} Product Variants Need Restock',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : const Color(0xFF92400E),
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.priority_high_rounded,
                                              size: 11, color: AppColors.warning),
                                          SizedBox(width: 2),
                                          Text(
                                            'Attention',
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.warning,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Current inventory levels are below the required threshold. Restock these items to maintain peak sales availability.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : const Color(0xFF78350F).withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );

                      final actionButton = ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const LowStockScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          'Review Low Stock',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            iconAndText,
                            const SizedBox(height: 14),
                            actionButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: iconAndText),
                          const SizedBox(width: 16),
                          actionButton,
                        ],
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      );

    if (widget.isEmbedded) {
      return Container(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: body,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Sales & Revenue Analytics',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Analytics',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => provider.loadDashboard(refresh: true),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
    );
  }
}

class _AnalyticsKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _AnalyticsKpiCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon Container & Optional Navigation Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 11,
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Content Area: Metric Value, Title, and Subtitle
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
