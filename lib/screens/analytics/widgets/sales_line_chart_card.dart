import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/analytics_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../theme/app_colors.dart';

class SalesLineChartCard extends StatelessWidget {
  final bool enableDateRangePicker;

  const SalesLineChartCard({
    super.key,
    this.enableDateRangePicker = true,
  });

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final provider = context.read<DashboardProvider>();
    final initialDateRange = DateTimeRange(
      start: provider.startDate,
      end: provider.endDate,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();
    final points = provider.chartPoints;

    final dateFormat = DateFormat('dd MMM yyyy');
    final rangeText =
        '${dateFormat.format(provider.startDate)} – ${dateFormat.format(provider.endDate)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title, Totals & Grouping / Date Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sales & Revenue Trend',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Revenue: ₹${provider.totalChartSales.toStringAsFixed(2)} • ${provider.totalChartBills} Bills ($rangeText)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),

              // Grouping Segmented Switcher (Daily, Monthly, Yearly)
              Row(
                children: [
                  Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildGroupingButton(context, SalesChartGrouping.daily, 'Daily'),
                        _buildGroupingButton(context, SalesChartGrouping.monthly, 'Monthly'),
                        _buildGroupingButton(context, SalesChartGrouping.yearly, 'Yearly'),
                      ],
                    ),
                  ),
                  if (enableDateRangePicker) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Select Custom Date Range',
                      icon: const Icon(Icons.date_range_rounded, size: 20, color: AppColors.primary),
                      onPressed: () => _selectCustomDateRange(context),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const Divider(height: 24),

          // Chart Display Area
          SizedBox(
            height: 240,
            child: provider.isChartLoading
                ? const Center(child: CircularProgressIndicator())
                : points.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bar_chart_rounded,
                                size: 40, color: AppColors.textMutedLight),
                            const SizedBox(height: 8),
                            const Text('No sales recorded for this period',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              'Try selecting a different date range or grouping',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      )
                    : LineChart(
                        _buildLineChartData(points, isDark),
                        duration: const Duration(milliseconds: 300),
                      ),
          ),
          const SizedBox(height: 8),

          // Chart Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Sales Revenue (₹)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 20),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('Bills Count',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupingButton(
    BuildContext context,
    SalesChartGrouping grouping,
    String label,
  ) {
    final provider = context.watch<DashboardProvider>();
    final isSelected = provider.selectedGrouping == grouping;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => provider.setGrouping(grouping),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }

  LineChartData _buildLineChartData(List<SalesChartPoint> points, bool isDark) {
    final maxSales = points.map((p) => p.salesAmount).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxSales > 0 ? (maxSales * 1.25) : 1000.0;

    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.salesAmount);
    }).toList();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY > 0 ? maxY / 4 : 250,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark ? AppColors.borderDark.withAlpha(80) : AppColors.borderLight,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 46,
            interval: maxY > 0 ? maxY / 4 : 250,
            getTitlesWidget: (value, meta) {
              if (value == 0) {
                return const Text('₹0', style: TextStyle(fontSize: 10));
              }
              if (value >= 100000) {
                return Text('₹${(value / 100000).toStringAsFixed(1)}L',
                    style: const TextStyle(fontSize: 10));
              }
              if (value >= 1000) {
                return Text('₹${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(fontSize: 10));
              }
              return Text('₹${value.toInt()}', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: points.length > 10 ? (points.length / 6).ceilToDouble() : 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= points.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  points[index].label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: (points.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.x.toInt();
              if (index < 0 || index >= points.length) return null;
              final p = points[index];
              return LineTooltipItem(
                '${p.label}\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                children: [
                  TextSpan(
                    text: 'Sales: ₹${p.salesAmount.toStringAsFixed(2)}\n',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  TextSpan(
                    text: 'Bills: ${p.billsCount}',
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.25,
          color: AppColors.primary,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: points.length <= 15,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 4,
              color: AppColors.primary,
              strokeWidth: 2,
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withAlpha(60),
                AppColors.primary.withAlpha(0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}
