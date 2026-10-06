import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_colors.dart';
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
      context.read<DashboardProvider>().loadDashboard(refresh: true);
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
            // Analytics Summary KPI Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isDesktop ? 2.2 : 2.5,
              children: [
                _AnalyticsKpiCard(
                  title: "Today's Sales",
                  value: '₹${overview.todaySales.toStringAsFixed(2)}',
                  subtitle: '${overview.todayBillsCount} bills today',
                  icon: Icons.today_rounded,
                  color: AppColors.primary,
                ),
                _AnalyticsKpiCard(
                  title: 'This Month',
                  value: '₹${overview.monthSales.toStringAsFixed(2)}',
                  subtitle: '${overview.monthBillsCount} bills in ${DateFormat('MMMM').format(DateTime.now())}',
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.secondary,
                ),
                _AnalyticsKpiCard(
                  title: 'This Year (${DateTime.now().year})',
                  value: '₹${overview.yearSales.toStringAsFixed(2)}',
                  subtitle: '${overview.yearBillsCount} bills this year',
                  icon: Icons.auto_graph_rounded,
                  color: const Color(0xFF0EA5E9),
                ),
                _AnalyticsKpiCard(
                  title: 'Average Sale Value',
                  value: '₹${avgBillValue.toStringAsFixed(2)}',
                  subtitle: 'Across ${overview.totalBillsCount} lifetime bills',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppColors.accent,
                ),
              ],
            ),
            const SizedBox(height: 24),

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

            // Low Stock Action Banner
            if (overview.lowStockCount > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.warning.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${overview.lowStockCount} Product Variants Require Restock',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Inventory levels are below the minimum threshold. Restock now to prevent missed sales.',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LowStockScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.inventory_rounded, size: 16),
                      label: const Text('View Low Stock'),
                    ),
                  ],
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
        title: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Sales & Revenue Analytics'),
          ],
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

  const _AnalyticsKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
