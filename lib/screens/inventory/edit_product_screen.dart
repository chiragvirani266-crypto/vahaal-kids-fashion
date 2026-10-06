import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditableVariant {
  final String? id;
  String size;
  String color;
  String sku;
  String barcode;
  int stock;
  int lowStockAlert;

  _EditableVariant({
    this.id,
    required this.size,
    required this.color,
    required this.sku,
    required this.barcode,
    required this.stock,
    required this.lowStockAlert,
  });
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _sellingPriceController;

  late String _selectedGender;
  late bool _isActive;

  final List<_EditableVariant> _variants = [];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.productName);
    _skuController = TextEditingController(text: p.sku);
    _barcodeController = TextEditingController(text: p.barcode ?? '');
    _categoryController = TextEditingController(text: p.category);
    _brandController = TextEditingController(text: p.brand);
    _purchasePriceController = TextEditingController(text: p.purchasePrice.toStringAsFixed(2));
    _sellingPriceController = TextEditingController(text: p.sellingPrice.toStringAsFixed(2));
    _selectedGender = p.gender;
    _isActive = p.isActive;

    for (final v in p.variants) {
      _variants.add(
        _EditableVariant(
          id: v.id,
          size: v.size,
          color: v.color,
          sku: v.sku,
          barcode: v.barcode,
          stock: v.stockQuantity,
          lowStockAlert: v.lowStockAlert,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _purchasePriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _addNewVariant() {
    setState(() {
      final baseSku = _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : 'VKF';
      final randomBarcode = '890${100000 + Random().nextInt(900000)}';
      _variants.add(
        _EditableVariant(
          id: null,
          size: '2Y',
          color: 'New Color',
          sku: '$baseSku-${_variants.length + 1}',
          barcode: randomBarcode,
          stock: 5,
          lowStockAlert: 3,
        ),
      );
    });
  }

  Future<void> _handleUpdate() async {
    final provider = context.read<ProductProvider>();
    provider.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product must have at least one variant.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;

    final updatedProduct = widget.product.copyWith(
      productName: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim(),
      gender: _selectedGender,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      isActive: _isActive,
    );

    final variants = _variants.map((v) {
      return ProductVariant(
        id: v.id,
        productId: widget.product.id,
        size: v.size.trim(),
        color: v.color.trim(),
        sku: v.sku.trim(),
        barcode: v.barcode.trim(),
        stockQuantity: v.stock,
        lowStockAlert: v.lowStockAlert,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
      );
    }).toList();

    final success = await provider.updateProduct(updatedProduct, variants);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Edit Product',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Alert
              if (provider.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Section 1: Basic Info
              Container(
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
                    const Text(
                      '1. Product Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _nameController,
                      label: 'Product Name *',
                      validator: (val) => Validators.validateRequired(val, 'Product Name'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _skuController,
                            label: 'Base SKU *',
                            validator: (val) => Validators.validateRequired(val, 'SKU'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _barcodeController,
                            label: 'Base Barcode',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _categoryController,
                            label: 'Category *',
                            validator: (val) => Validators.validateRequired(val, 'Category'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _brandController,
                            label: 'Brand',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Gender Selector
                    const Text(
                      'Gender / Classification *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: AppConstants.genders.map((g) {
                          final isSelected = _selectedGender == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(g),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _selectedGender = g),
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : null,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prices
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _purchasePriceController,
                            label: 'Purchase Cost (${AppConstants.currencySymbol}) *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => Validators.validateRequired(val, 'Cost price'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _sellingPriceController,
                            label: 'Selling Price / MRP (${AppConstants.currencySymbol}) *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => Validators.validateRequired(val, 'Selling price'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Manage Variants
              Container(
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
                        Text(
                          '2. Manage Variants (${_variants.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ElevatedButton.icon(
                          onPressed: _addNewVariant,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Variant', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: const Size(100, 32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _variants.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final v = _variants[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Size & Color dropdown / inputs
                            SizedBox(
                              width: 80,
                              child: TextFormField(
                                initialValue: v.size,
                                decoration: const InputDecoration(
                                  labelText: 'Size',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                onChanged: (val) => v.size = val,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: TextFormField(
                                initialValue: v.color,
                                decoration: const InputDecoration(
                                  labelText: 'Color',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12),
                                onChanged: (val) => v.color = val,
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Stock Quantity
                            SizedBox(
                              width: 70,
                              child: TextFormField(
                                initialValue: v.stock.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stock',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                ),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                onChanged: (val) {
                                  v.stock = int.tryParse(val) ?? 0;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),

                            // SKU & Barcode
                            Expanded(
                              child: Column(
                                children: [
                                  TextFormField(
                                    initialValue: v.sku,
                                    decoration: const InputDecoration(
                                      labelText: 'SKU',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                    onChanged: (val) => v.sku = val,
                                  ),
                                  const SizedBox(height: 4),
                                  TextFormField(
                                    initialValue: v.barcode,
                                    decoration: const InputDecoration(
                                      labelText: 'Barcode',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    ),
                                    style: const TextStyle(fontSize: 11),
                                    onChanged: (val) => v.barcode = val,
                                  ),
                                ],
                              ),
                            ),

                            // Remove
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _variants.removeAt(index);
                                });
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              AppButton(
                text: 'Save Changes',
                icon: Icons.check_circle_outline_rounded,
                isLoading: provider.isLoading,
                onPressed: _handleUpdate,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
