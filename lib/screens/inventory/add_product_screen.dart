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

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _VariantDraft {
  final String id;
  String size;
  String color;
  String sku;
  String barcode;
  int stock;
  int lowStockAlert;

  _VariantDraft({
    required this.id,
    required this.size,
    required this.color,
    required this.sku,
    required this.barcode,
    this.stock = 5,
    this.lowStockAlert = 3,
  });
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Basic Controllers
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _categoryController = TextEditingController(text: 'T-Shirts');
  final _brandController = TextEditingController(text: 'Vahaal');
  final _purchasePriceController = TextEditingController(text: '0.00');
  final _sellingPriceController = TextEditingController(text: '0.00');

  String _selectedGender = 'Unisex';
  bool _isActive = true;

  // Matrix Generator State
  final Set<String> _selectedMatrixSizes = {'2Y', '3Y'};
  final Set<String> _selectedMatrixColors = {'Red', 'Blue'};
  final _customColorController = TextEditingController();

  final List<String> _presetColors = [
    'Red',
    'Blue',
    'Pink',
    'Yellow',
    'Navy',
    'White',
    'Black',
    'Green',
    'Orange',
    'Purple',
  ];

  // Configured Variants
  final List<_VariantDraft> _variants = [];

  @override
  void initState() {
    super.initState();
    _generateMatrix();
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
    _customColorController.dispose();
    super.dispose();
  }

  String _generateBarcodeSeed() {
    final random = Random();
    final randomNum = 100000 + random.nextInt(900000);
    return '890$randomNum';
  }

  void _generateMatrix() {
    if (_selectedMatrixSizes.isEmpty || _selectedMatrixColors.isEmpty) return;

    final baseSku = _skuController.text.trim().isNotEmpty
        ? _skuController.text.trim().toUpperCase()
        : (_nameController.text.trim().isNotEmpty
            ? _nameController.text.trim().replaceAll(' ', '-').toUpperCase()
            : 'VKF-${Random().nextInt(9999)}');

    setState(() {
      _variants.clear();
      for (final size in _selectedMatrixSizes) {
        for (final color in _selectedMatrixColors) {
          final sizeClean = size.replaceAll('-', '').replaceAll(' ', '');
          final colorClean = color.replaceAll(' ', '').toUpperCase();
          final vSku = '$baseSku-$sizeClean-$colorClean';
          final vBarcode = _generateBarcodeSeed();

          _variants.add(
            _VariantDraft(
              id: UniqueKey().toString(),
              size: size,
              color: color,
              sku: vSku,
              barcode: vBarcode,
              stock: 5,
              lowStockAlert: 3,
            ),
          );
        }
      }
    });
  }

  void _addCustomColor() {
    final val = _customColorController.text.trim();
    if (val.isNotEmpty && !_selectedMatrixColors.contains(val)) {
      setState(() {
        _selectedMatrixColors.add(val);
        _customColorController.clear();
      });
    }
  }

  void _addSingleVariant() {
    setState(() {
      final baseSku = _skuController.text.trim().isNotEmpty ? _skuController.text.trim() : 'VKF';
      _variants.add(
        _VariantDraft(
          id: UniqueKey().toString(),
          size: '2Y',
          color: 'Standard',
          sku: '$baseSku-${_variants.length + 1}',
          barcode: _generateBarcodeSeed(),
          stock: 5,
          lowStockAlert: 3,
        ),
      );
    });
  }

  Future<void> _handleSave() async {
    final provider = context.read<ProductProvider>();
    provider.clearError();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please generate or add at least one product variant (size/color).'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final purchasePrice = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;

    String baseSku = _skuController.text.trim();
    if (baseSku.isEmpty) {
      baseSku = 'VKF-${_nameController.text.trim().split(' ').first.toUpperCase()}-${Random().nextInt(9999)}';
    }

    final product = Product(
      sku: baseSku,
      barcode: _barcodeController.text.trim().isNotEmpty ? _barcodeController.text.trim() : null,
      productName: _nameController.text.trim(),
      category: _categoryController.text.trim(),
      brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : 'Vahaal',
      gender: _selectedGender,
      purchasePrice: purchasePrice,
      sellingPrice: sellingPrice,
      isActive: _isActive,
    );

    final variants = _variants.map((v) {
      return ProductVariant(
        size: v.size,
        color: v.color,
        sku: v.sku.trim(),
        barcode: v.barcode.trim(),
        stockQuantity: v.stock,
        lowStockAlert: v.lowStockAlert,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
      );
    }).toList();

    final success = await provider.addProduct(product, variants);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product & variants created successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
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
          'Add New Product',
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

              // Section 1: Basic Details Card
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
                      hint: 'e.g. Cotton Printed T-Shirt',
                      validator: (val) => Validators.validateRequired(val, 'Product Name'),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _skuController,
                            label: 'Base SKU (Optional)',
                            hint: 'e.g. TSHIRT-01',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _barcodeController,
                            label: 'Base Barcode (Optional)',
                            hint: 'e.g. 89012345678',
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
                            hint: 'e.g. T-Shirts, Frocks',
                            validator: (val) => Validators.validateRequired(val, 'Category'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _brandController,
                            label: 'Brand',
                            hint: 'Vahaal',
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

                    // Pricing Row
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _purchasePriceController,
                            label: 'Purchase Cost (${AppConstants.currencySymbol}) *',
                            hint: '250.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => Validators.validateRequired(val, 'Cost price'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _sellingPriceController,
                            label: 'Selling Price / MRP (${AppConstants.currencySymbol}) *',
                            hint: '499.00',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (val) => Validators.validateRequired(val, 'Selling price'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    SwitchListTile(
                      title: const Text('Product Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        _isActive ? 'Active (Available in billing catalog)' : 'Inactive (Hidden from catalog)',
                        style: TextStyle(fontSize: 12, color: _isActive ? AppColors.success : AppColors.error),
                      ),
                      value: _isActive,
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _isActive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Variant Matrix Generator
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
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2. Kidswear Variant Generator',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Pick sizes & colors to auto-generate the inventory matrix',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _generateMatrix,
                          icon: const Icon(Icons.flash_on_rounded, size: 16),
                          label: const Text('Generate Matrix'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(120, 36),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Age Sizes Multi-select Chips
                    const Text(
                      'Select Age Sizes (0–12 Years):',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: AppConstants.ageGroups.map((size) {
                        final isSelected = _selectedMatrixSizes.contains(size);
                        return FilterChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMatrixSizes.add(size);
                              } else {
                                _selectedMatrixSizes.remove(size);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withAlpha(40),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Colors Selection
                    const Text(
                      'Select Colors:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _presetColors.map((color) {
                        final isSelected = _selectedMatrixColors.contains(color);
                        return FilterChip(
                          label: Text(color),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMatrixColors.add(color);
                              } else {
                                _selectedMatrixColors.remove(color);
                              }
                            });
                          },
                          selectedColor: AppColors.secondary.withAlpha(40),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.secondary : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Custom Color Adder
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _customColorController,
                            hint: 'Add custom color (e.g. Mint Green)',
                            onFieldSubmitted: (_) => _addCustomColor(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addCustomColor,
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Generated Variants List & Stock Inputs
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
                          '3. Generated Variants (${_variants.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addSingleVariant,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Single', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_variants.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No variants generated. Click "Generate Matrix" above to create variants.',
                            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _variants.length,
                        separatorBuilder: (_, __) => const Divider(height: 20),
                        itemBuilder: (context, index) {
                          final v = _variants[index];
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Size & Color Tag
                              Container(
                                width: 90,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      v.size,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      v.color,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Stock Input
                              SizedBox(
                                width: 75,
                                child: TextFormField(
                                  initialValue: v.stock.toString(),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    labelText: 'Stock',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  ),
                                  onChanged: (val) {
                                    v.stock = int.tryParse(val) ?? 0;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),

                              // SKU & Barcode Inputs
                              Expanded(
                                child: Column(
                                  children: [
                                    TextFormField(
                                      initialValue: v.sku,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        labelText: 'Variant SKU',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (val) => v.sku = val,
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      initialValue: v.barcode,
                                      style: const TextStyle(fontSize: 12),
                                      decoration: const InputDecoration(
                                        labelText: 'Variant Barcode',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      ),
                                      onChanged: (val) => v.barcode = val,
                                    ),
                                  ],
                                ),
                              ),

                              // Remove button
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

              // Save Action Button
              AppButton(
                text: 'Save & Create Product',
                icon: Icons.check_circle_outline_rounded,
                isLoading: provider.isLoading,
                onPressed: _handleSave,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
