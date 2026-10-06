import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_navigator.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_snackbar.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProductDetails(widget.productId);
    });
  }

  Future<void> _handleToggleStatus(Product product) async {
    final provider = context.read<ProductProvider>();
    final isDeactivating = product.isActive;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isDeactivating ? Icons.visibility_off_outlined : Icons.check_circle_outline,
              color: isDeactivating ? AppColors.error : AppColors.success,
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(isDeactivating ? 'Deactivate Product' : 'Reactivate Product'),
          ],
        ),
        content: Text(
          isDeactivating
              ? 'Are you sure you want to deactivate "${product.productName}"? It will be hidden from checkout but preserved for existing sales records.'
              : 'Reactivate "${product.productName}" and make it available in billing again?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDeactivating ? AppColors.error : AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: Text(isDeactivating ? 'Deactivate' : 'Reactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (isDeactivating) {
        await provider.softDeleteProduct(product.id!);
      } else {
        await provider.reactivateProduct(product.id!);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDeactivating
                  ? 'Product deactivated successfully'
                  : 'Product reactivated successfully',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final authProvider = context.watch<AuthProvider>();
    final product = provider.selectedProduct;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading && product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Product not found or has been deleted.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          product.productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            tooltip: 'Print Barcode Labels',
            onPressed: () {
              AppNavigator.toLabelPrint(context: context, initialProduct: product);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Product',
            onPressed: () async {
              final updated = await AppNavigator.toEditProduct(
                context: context,
                product: product,
              );
              if (updated == true && mounted) {
                provider.loadProductDetails(widget.productId);
              }
            },
          ),
          if (authProvider.isAdmin)
            IconButton(
              icon: Icon(
                product.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: product.isActive ? AppColors.error : AppColors.success,
              ),
              tooltip: product.isActive ? 'Deactivate Product' : 'Reactivate Product',
              onPressed: () => _handleToggleStatus(product),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner if Inactive
            if (!product.isActive) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.error, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This product is currently INACTIVE and hidden from checkout.',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Main Product Info Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.checkroom_rounded,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Brand: ${product.brand} • Category: ${product.category}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Base SKU: ${product.sku}${product.barcode != null ? ' | Barcode: ${product.barcode}' : ''}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Financial KPI Row
                  Row(
                    children: [
                      _StatBox(
                        title: 'Selling Price',
                        value: '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        title: 'Purchase Price',
                        value: '${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(2)}',
                        color: AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        title: 'Margin',
                        value: '${AppConstants.currencySymbol}${product.profitMargin.toStringAsFixed(2)} (${product.profitPercentage.toStringAsFixed(0)}%)',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 12),
                      _StatBox(
                        title: 'Total Stock',
                        value: '${product.totalStock} Units',
                        color: product.isOutOfStock
                            ? AppColors.error
                            : (product.hasLowStock ? AppColors.warning : AppColors.tertiary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Variants Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Size & Color Variants (${product.variants.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final updated = await AppNavigator.toEditProduct(
                      context: context,
                      product: product,
                    );
                    if (updated == true && mounted) {
                      provider.loadProductDetails(widget.productId);
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add / Edit Variants', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withAlpha(25),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    minimumSize: const Size(100, 36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Variants List
            if (product.variants.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: const Center(
                  child: Text(
                    'No variants configured yet. Tap "Add / Edit Variants" to generate sizes and colors.',
                    style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: product.variants.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final v = product.variants[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: v.isLowStock
                            ? AppColors.warning.withAlpha(120)
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            v.size,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    v.color,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  if (v.isLowStock) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warningBg,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'LOW STOCK',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'SKU: ${v.sku} • Barcode: ${v.barcode}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${v.stockQuantity} in stock',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: v.isOutOfStock
                                    ? AppColors.error
                                    : (v.isLowStock ? AppColors.warning : AppColors.success),
                              ),
                            ),
                            Text(
                              'Alert at ≤ ${v.lowStockAlert}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Add Stock (Stock In)',
                          icon: const Icon(Icons.add_box_outlined, size: 20, color: AppColors.secondary),
                          onPressed: () async {
                            final updated = await AppNavigator.toStockIn(
                              context: context,
                              variantId: v.id,
                            );
                            if (updated == true && mounted) {
                              provider.loadProductDetails(widget.productId);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'Add to POS Cart',
                          icon: const Icon(Icons.add_shopping_cart_rounded, size: 20, color: AppColors.primary),
                          onPressed: () {
                            context.read<BillProvider>().addItem(
                              product: product,
                              variant: v,
                              quantity: 1,
                            );
                            AppSnackbar.showSuccess(
                              context,
                              'Added ${product.productName} (${v.displayName}) to POS Cart',
                            );
                          },
                        ),
                        IconButton(
                          tooltip: 'Print Barcode Sticker',
                          icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: AppColors.textSecondaryLight),
                          onPressed: () {
                            AppNavigator.toLabelPrint(
                              context: context,
                              initialProduct: product,
                              initialVariant: v,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatBox({
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
                fontSize: 12,
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
