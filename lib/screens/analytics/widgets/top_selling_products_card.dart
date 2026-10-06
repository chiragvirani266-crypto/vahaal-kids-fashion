import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../theme/app_colors.dart';

class TopSellingProductsCard extends StatelessWidget {
  const TopSellingProductsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<DashboardProvider>();
    final products = provider.topSellingProducts;

    final maxSold = products.isNotEmpty ? products.first.totalQuantitySold : 1;

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.accent, size: 22),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Top Selling Products',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Text(
                'By Volume & Revenue',
                style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
              ),
            ],
          ),
          const Divider(height: 24),

          if (provider.isChartLoading)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (products.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 36, color: AppColors.textMutedLight),
                  const SizedBox(height: 8),
                  const Text('No product sales recorded yet',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(
                    'Completed sales will populate the leaderboard',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                final progress = maxSold > 0 ? (product.totalQuantitySold / maxSold) : 0.0;

                Color rankColor;
                if (index == 0) {
                  rankColor = const Color(0xFFEAB308); // Gold
                } else if (index == 1) {
                  rankColor = const Color(0xFF94A3B8); // Silver
                } else if (index == 2) {
                  rankColor = const Color(0xFFB45309); // Bronze
                } else {
                  rankColor = AppColors.primary;
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Rank Badge
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: rankColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: rankColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Product Title & SKU
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'SKU: ${product.sku}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Quantity & Revenue
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${product.totalRevenue.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${product.totalQuantitySold} sold',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        backgroundColor: isDark
                            ? AppColors.surfaceDark
                            : AppColors.backgroundLight,
                        valueColor: AlwaysStoppedAnimation<Color>(rankColor),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
