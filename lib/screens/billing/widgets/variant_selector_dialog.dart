import 'package:flutter/material.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../../../theme/app_colors.dart';

class VariantSelectorDialog extends StatefulWidget {
  final Product product;
  final Function(ProductVariant variant, int quantity) onAdd;

  const VariantSelectorDialog({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  State<VariantSelectorDialog> createState() => _VariantSelectorDialogState();
}

class _VariantSelectorDialogState extends State<VariantSelectorDialog> {
  ProductVariant? _selectedVariant;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Pre-select first variant with available stock, or first variant
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.firstWhere(
        (v) => v.stockQuantity > 0,
        orElse: () => widget.product.variants.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final availableStock = _selectedVariant?.stockQuantity ?? 0;
    final isOutOfStock = availableStock <= 0;
    final unitPrice = _selectedVariant?.sellingPrice ?? widget.product.sellingPrice;
    final totalPrice = unitPrice * _quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.productName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'SKU: ${widget.product.sku} • ${widget.product.category}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Variant Selector
            const Text(
              'Select Size & Color Variant',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),

            if (widget.product.variants.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                    SizedBox(width: 8),
                    Text('No variants found for this product.'),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.product.variants.map((v) {
                  final isSelected = _selectedVariant?.id == v.id ||
                      (_selectedVariant?.size == v.size && _selectedVariant?.color == v.color);
                  final inStock = v.stockQuantity > 0;

                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${v.size} / ${v.color}'),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: inStock
                                ? (isSelected ? Colors.white.withAlpha(50) : AppColors.success.withAlpha(30))
                                : AppColors.error.withAlpha(30),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            inStock ? '${v.stockQuantity}' : '0',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: inStock
                                  ? (isSelected ? Colors.white : AppColors.success)
                                  : AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedVariant = v;
                          if (_quantity > v.stockQuantity && v.stockQuantity > 0) {
                            _quantity = v.stockQuantity;
                          }
                        });
                      }
                    },
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // Stock & Price Info Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unit Price',
                        style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      ),
                      Text(
                        '₹${unitPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Stock Available',
                        style: TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                      ),
                      Text(
                        isOutOfStock ? 'Out of Stock' : '$availableStock units',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isOutOfStock ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quantity Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quantity to Bill:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_rounded, size: 18),
                        onPressed: _quantity > 1
                            ? () {
                                setState(() => _quantity--);
                              }
                            : null,
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 40),
                        alignment: Alignment.center,
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        onPressed: (!isOutOfStock && _quantity < availableStock)
                            ? () {
                                setState(() => _quantity++);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Bottom Add Action
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (isOutOfStock || _selectedVariant == null)
                    ? null
                    : () {
                        widget.onAdd(_selectedVariant!, _quantity);
                        Navigator.of(context).pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_shopping_cart_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      isOutOfStock
                          ? 'Out of Stock'
                          : 'Add to Bill (₹${totalPrice.toStringAsFixed(2)})',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
