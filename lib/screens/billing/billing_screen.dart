import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/bill_success_modal.dart';
import 'widgets/customer_picker_dialog.dart';
import 'widgets/variant_selector_dialog.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeScanController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _barcodeFocusNode = FocusNode();

  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<CustomerProvider>().loadCustomers();
      context.read<BillProvider>().loadPreviewBillNumber();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeScanController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  // Handle direct barcode scanner submission
  void _handleBarcodeScan(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;

    final products = context.read<ProductProvider>().products;
    bool found = false;

    // 1. Search in variants for exact barcode / SKU
    for (final product in products) {
      for (final variant in product.variants) {
        if (variant.barcode.toLowerCase() == code.toLowerCase() ||
            variant.sku.toLowerCase() == code.toLowerCase()) {
          found = true;
          context.read<BillProvider>().addItem(
                product: product,
                variant: variant,
                quantity: 1,
              );
          _showFeedback('Added "${product.productName} (${variant.displayName})" to cart');
          break;
        }
      }
      if (found) break;
    }

    // 2. If not found in variants, search by product barcode or SKU
    if (!found) {
      for (final product in products) {
        if (product.barcode?.toLowerCase() == code.toLowerCase() ||
            product.sku.toLowerCase() == code.toLowerCase()) {
          found = true;
          if (product.variants.length == 1) {
            context.read<BillProvider>().addItem(
                  product: product,
                  variant: product.variants.first,
                  quantity: 1,
                );
            _showFeedback('Added "${product.productName}" to cart');
          } else {
            _openVariantSelector(product);
          }
          break;
        }
      }
    }

    if (!found) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('No item found matching barcode/SKU "$code".'),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _barcodeScanController.clear();
    _barcodeFocusNode.requestFocus();
  }

  void _showFeedback(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _openVariantSelector(Product product) {
    if (product.variants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('This product has no variants configured.'),
        ),
      );
      return;
    }

    if (product.variants.length == 1) {
      context.read<BillProvider>().addItem(
            product: product,
            variant: product.variants.first,
            quantity: 1,
          );
      _showFeedback('Added "${product.productName}" to cart');
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => VariantSelectorDialog(
        product: product,
        onAdd: (variant, quantity) {
          context.read<BillProvider>().addItem(
                product: product,
                variant: variant,
                quantity: quantity,
              );
          _showFeedback('Added $quantity x "${product.productName} (${variant.displayName})"');
        },
      ),
    );
  }

  void _openCustomerPicker() {
    final billProvider = context.read<BillProvider>();
    showDialog(
      context: context,
      builder: (ctx) => CustomerPickerDialog(
        currentCustomer: billProvider.selectedCustomer,
        onSelect: (customer) {
          billProvider.setCustomer(customer);
          _discountController.text =
              customer != null && customer.lastDiscount > 0
                  ? customer.lastDiscount.toStringAsFixed(0)
                  : '';
        },
      ),
    );
  }

  Future<void> _handleCheckout() async {
    final billProvider = context.read<BillProvider>();
    final authProvider = context.read<AuthProvider>();

    if (billProvider.isCartEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Cart is empty. Add products before checkout.'),
        ),
      );
      return;
    }

    final bill = await billProvider.checkout(
      cashierId: authProvider.userProfile?.id,
    );

    if (bill != null && mounted) {
      // Reload stock to reflect inventory reduction
      context.read<ProductProvider>().loadProducts();
      context.read<CustomerProvider>().loadCustomers();

      _discountController.clear();
      _notesController.clear();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => BillSuccessModal(
          bill: bill,
          onNewBill: () {
            billProvider.clearCart();
            _barcodeFocusNode.requestFocus();
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Billing & Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Consumer<BillProvider>(
                  builder: (_, bp, __) => Text(
                    'Bill No: ${bp.previewBillNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Clear Cart Action
          Consumer<BillProvider>(
            builder: (context, bp, _) {
              if (bp.cartItems.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear Cart',
                icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.error),
                onPressed: () {
                  bp.clearCart();
                  _discountController.clear();
                  _notesController.clear();
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (2-COLUMN SPLIT POS VIEW)
  // ==========================================
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Product Search, Barcode Input, & Catalog List
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fast Barcode Scanner Field
                _buildBarcodeBar(),
                const SizedBox(height: 12),

                // Search & Filter Bar
                _buildSearchAndFilters(),
                const SizedBox(height: 12),

                // Products & Variants Catalog Grid
                Expanded(child: _buildProductCatalog()),
              ],
            ),
          ),
        ),

        // Vertical Divider
        const VerticalDivider(width: 1),

        // Right Column: Cart, Customer, Discount, Payment & Summary
        Expanded(
          flex: 4,
          child: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Selector Bar
                _buildCustomerTile(),
                const SizedBox(height: 12),

                // Cart Items List
                Expanded(child: _buildCartItemsList()),
                const SizedBox(height: 12),

                // Checkout Section (Discount, Payment Method, Totals, Button)
                _buildCheckoutSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE RESPONSIVE LAYOUT
  // ==========================================
  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Top Barcode & Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Column(
            children: [
              _buildBarcodeBar(),
              const SizedBox(height: 8),
              _buildSearchAndFilters(),
            ],
          ),
        ),

        // Catalog List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildProductCatalog(),
          ),
        ),

        // Mobile Sticky Bottom Checkout Bar
        _buildMobileBottomCartBar(),
      ],
    );
  }

  // Barcode Fast Scan Input
  Widget _buildBarcodeBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _barcodeScanController,
              focusNode: _barcodeFocusNode,
              decoration: const InputDecoration(
                hintText: 'Scan barcode or enter SKU & press Enter...',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: _handleBarcodeScan,
            ),
          ),
          IconButton(
            tooltip: 'Add',
            icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
            onPressed: () => _handleBarcodeScan(_barcodeScanController.text),
          ),
        ],
      ),
    );
  }

  // Search & Category Filters
  Widget _buildSearchAndFilters() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search Input
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search product by name, brand, or SKU...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          onChanged: (val) {
            setState(() => _searchQuery = val.trim());
          },
        ),
        const SizedBox(height: 8),

        // Categories Single-row Scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...['All', 'T-Shirts', 'Shirts', 'Jeans', 'Dresses', 'Ethnic', 'Nightwear', 'Accessories']
                  .map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                    ),
                    onSelected: (selected) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Product Catalog Grid / List
  Widget _buildProductCatalog() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var products = provider.products.where((p) => p.isActive).toList();

        if (_selectedCategory != 'All') {
          products =
              products.where((p) => p.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          products = products.where((p) {
            final matchesName = p.productName.toLowerCase().contains(q);
            final matchesSku = p.sku.toLowerCase().contains(q);
            final matchesBarcode = p.barcode?.toLowerCase().contains(q) ?? false;
            final matchesVariants = p.variants.any((v) =>
                v.sku.toLowerCase().contains(q) ||
                v.barcode.toLowerCase().contains(q) ||
                v.size.toLowerCase().contains(q) ||
                v.color.toLowerCase().contains(q));
            return matchesName || matchesSku || matchesBarcode || matchesVariants;
          }).toList();
        }

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.textMutedLight),
                const SizedBox(height: 8),
                const Text('No matching products found', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Try searching with another keyword or category',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          );
        }

        final isDesktop = MediaQuery.of(context).size.width > 900;
        final crossAxisCount = isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 3 : 2);

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _buildProductCard(product);
          },
        );
      },
    );
  }

  // Individual Product Card in POS
  Widget _buildProductCard(Product product) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalStock = product.totalStock;
    final isOut = totalStock <= 0;

    return InkWell(
      onTap: () => _openVariantSelector(product),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge Row (Category & Stock)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isOut ? AppColors.error.withAlpha(20) : AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isOut ? 'Out of Stock' : '$totalStock in stock',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOut ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Product Name
            Text(
              product.productName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // SKU & Variant Count
            Text(
              'SKU: ${product.sku} • ${product.variants.length} sizes',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
            const Spacer(),

            // Price & Add Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${product.sellingPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isOut ? Colors.grey.shade400 : AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Customer Selector Tile
  Widget _buildCustomerTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billProvider = context.watch<BillProvider>();
    final customer = billProvider.selectedCustomer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: customer != null ? AppColors.primary : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: customer != null
                ? AppColors.secondary.withAlpha(30)
                : AppColors.primary.withAlpha(20),
            child: Icon(
              customer != null ? Icons.person_rounded : Icons.person_search_rounded,
              size: 18,
              color: customer != null ? AppColors.secondary : AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer != null ? customer.name : 'Walk-in Customer',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  customer != null
                      ? '📱 ${customer.mobile} ${customer.lastDiscount > 0 ? "• Last Disc: ₹${customer.lastDiscount.toStringAsFixed(0)}" : ""}'
                      : 'Tap to select or register customer',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _openCustomerPicker,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 32),
            ),
            child: Text(customer != null ? 'Change' : 'Select'),
          ),
        ],
      ),
    );
  }

  // Active Cart Items List
  Widget _buildCartItemsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BillProvider>(
      builder: (context, billProvider, _) {
        final items = billProvider.cartItems;
        final error = billProvider.errorMessage;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cart is empty',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scan barcode or select products to add to bill',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (error != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        error,
                        style: const TextStyle(fontSize: 11, color: AppColors.error),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 14),
                      onPressed: () => billProvider.clearError(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isStockExceeded = item.quantity > item.availableStock;

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isStockExceeded
                          ? AppColors.error.withAlpha(15)
                          : (isDark ? AppColors.cardDark : AppColors.backgroundLight),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isStockExceeded
                            ? AppColors.error
                            : (isDark ? AppColors.borderDark : AppColors.borderLight),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Item Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productNameSnapshot,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${item.sizeSnapshot} / ${item.colorSnapshot} • ₹${item.unitPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                              ),
                              if (isStockExceeded)
                                Text(
                                  'Only ${item.availableStock} in stock!',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.error,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Quantity Stepper
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                              onPressed: () => billProvider.decrementQuantity(item.variantId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 26),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                              onPressed: () => billProvider.incrementQuantity(item.variantId),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),

                        // Item Total
                        SizedBox(
                          width: 65,
                          child: Text(
                            '₹${item.total.toStringAsFixed(2)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),

                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                          onPressed: () => billProvider.removeItem(item.variantId),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Checkout Section (Discount, Payment Method, Summary, Complete Sale)
  Widget _buildCheckoutSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final billProvider = context.watch<BillProvider>();

    return Column(
      children: [
        const Divider(height: 16),

        // Discount & Remarks Row
        Row(
          children: [
            // Discount input
            Expanded(
              flex: 4,
              child: TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Discount (₹)',
                  isDense: true,
                  prefixText: '₹ ',
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.trim()) ?? 0.0;
                  billProvider.setDiscountAmount(parsed);
                },
              ),
            ),
            const SizedBox(width: 8),

            // Notes / Remarks
            Expanded(
              flex: 5,
              child: TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Remarks',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                onChanged: (val) {
                  billProvider.setNotes(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Payment Method Selector Pills
        Row(
          children: [
            _buildPaymentMethodButton('cash', 'Cash', Icons.payments_rounded),
            const SizedBox(width: 6),
            _buildPaymentMethodButton('upi', 'UPI', Icons.qr_code_rounded),
            const SizedBox(width: 6),
            _buildPaymentMethodButton('card', 'Card', Icons.credit_card_rounded),
            const SizedBox(width: 6),
            _buildPaymentMethodButton('other', 'Other', Icons.account_balance_wallet_rounded),
          ],
        ),
        const SizedBox(height: 12),

        // Totals Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal (${billProvider.totalQuantity} items):',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '₹${billProvider.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (billProvider.effectiveDiscount > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discount Applied:',
                      style: TextStyle(fontSize: 12, color: AppColors.success),
                    ),
                    Text(
                      '-₹${billProvider.effectiveDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '₹${billProvider.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Complete Checkout Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: billProvider.canCheckout ? _handleCheckout : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: billProvider.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Complete Sale (₹${billProvider.grandTotal.toStringAsFixed(2)})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton(String methodKey, String label, IconData icon) {
    final billProvider = context.watch<BillProvider>();
    final isSelected = billProvider.paymentMethod == methodKey;

    return Expanded(
      child: InkWell(
        onTap: () => billProvider.setPaymentMethod(methodKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textPrimaryLight),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Mobile Bottom Cart Summary Bar
  Widget _buildMobileBottomCartBar() {
    final billProvider = context.watch<BillProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${billProvider.totalQuantity} items • Total',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(
                    '₹${billProvider.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: billProvider.isCartEmpty ? null : () => _showMobileCartSheet(context),
              icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
              label: const Text('View Cart & Pay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobile Bottom Sheet for reviewing cart & checking out
  void _showMobileCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Bill / Cart',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
            const Divider(),
            _buildCustomerTile(),
            const SizedBox(height: 8),
            Expanded(child: _buildCartItemsList()),
            _buildCheckoutSection(),
          ],
        ),
      ),
    );
  }
}
