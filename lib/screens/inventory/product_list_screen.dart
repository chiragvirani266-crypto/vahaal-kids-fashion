import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_text_field.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Product Catalog',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadProducts(refresh: true),
          ),
          IconButton(
            icon: Icon(
              provider.includeInactive ? Icons.visibility_rounded : Icons.visibility_off_outlined,
              color: provider.includeInactive ? AppColors.secondary : null,
            ),
            tooltip: provider.includeInactive ? 'Showing Inactive Items' : 'Show Inactive Items',
            onPressed: () => provider.setIncludeInactive(!provider.includeInactive),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter & Search Controls Header
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search row & sort button
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _searchController,
                        hint: 'Search by name, SKU, barcode, size...',
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
                    const SizedBox(width: 12),
                    // Sort Dropdown Menu
                    PopupMenuButton<ProductSortOption>(
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
                      tooltip: 'Sort Products',
                      onSelected: (opt) => provider.setSortOption(opt),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ProductSortOption.newest,
                          child: Text('Newest First'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.nameAsc,
                          child: Text('Name (A-Z)'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.nameDesc,
                          child: Text('Name (Z-A)'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.priceLowHigh,
                          child: Text('Price: Low to High'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.priceHighLow,
                          child: Text('Price: High to Low'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.stockLowHigh,
                          child: Text('Stock: Low to High'),
                        ),
                        const PopupMenuItem(
                          value: ProductSortOption.stockHighLow,
                          child: Text('Stock: High to Low'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category and Gender Filter Chips Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Low stock toggle chip
                      FilterChip(
                        selected: provider.lowStockOnly,
                        onSelected: (val) => provider.setLowStockOnly(val),
                        avatar: Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: provider.lowStockOnly ? Colors.white : AppColors.warning,
                        ),
                        label: Text('Low Stock (${provider.lowStockCount})'),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: provider.lowStockOnly ? Colors.white : AppColors.warning,
                        ),
                        selectedColor: AppColors.warning,
                        backgroundColor: isDark ? AppColors.cardDark : AppColors.warningBg,
                        side: BorderSide(
                          color: provider.lowStockOnly ? AppColors.warning : AppColors.warning.withAlpha(80),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Gender Chips
                      ...['All', ...AppConstants.genders].map((g) {
                        final isSelected = provider.selectedGender == g;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(g),
                            selected: isSelected,
                            onSelected: (_) => provider.setGender(g),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                          ),
                        );
                      }),

                      const SizedBox(width: 8),
                      // Categories Chips
                      ...provider.categories.map((cat) {
                        final isSelected = provider.selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (_) => provider.setCategory(cat),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            selectedColor: AppColors.primary,
                            backgroundColor: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List / Grid
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.filteredProducts.isEmpty
                    ? _buildEmptyState(context, provider)
                    : RefreshIndicator(
                        onRefresh: () => provider.loadProducts(refresh: true),
                        child: isDesktop
                            ? _buildDesktopGrid(context, provider.filteredProducts)
                            : _buildMobileList(context, provider.filteredProducts),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ProductProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No Products Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.searchQuery.isNotEmpty || provider.selectedCategory != 'All'
                  ? 'No items match your active search or filters.'
                  : 'Start building your kidswear catalog by adding your first product.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add New Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(180, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(BuildContext context, List<Product> products) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product);
      },
    );
  }

  Widget _buildDesktopGrid(BuildContext context, List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        mainAxisExtent: 220,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(product: product);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color stockColor;
    String stockText;
    if (product.isOutOfStock) {
      stockColor = AppColors.error;
      stockText = 'Out of Stock';
    } else if (product.hasLowStock) {
      stockColor = AppColors.warning;
      stockText = 'Low Stock (${product.totalStock})';
    } else {
      stockColor = AppColors.success;
      stockText = '${product.totalStock} in stock';
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailsScreen(productId: product.id!),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category tag, Gender tag, Active badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    product.gender,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const Spacer(),
                if (!product.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.errorBg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'INACTIVE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Product Name & SKU
            Text(
              product.productName,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'SKU: ${product.sku}${product.barcode != null ? ' • ${product.barcode}' : ''}',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
            const SizedBox(height: 10),

            // Variants Preview Chips
            if (product.variants.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: product.variants.take(4).map((v) {
                    return Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: v.isLowStock
                              ? AppColors.warning.withAlpha(100)
                              : (isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                      ),
                      child: Text(
                        v.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: v.isLowStock ? AppColors.warning : null,
                        ),
                      ),
                    );
                  }).toList()
                    ..addAll(
                      product.variants.length > 4
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Text(
                                  '+${product.variants.length - 4} more',
                                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryLight),
                                ),
                              ),
                            ]
                          : [],
                    ),
                ),
              ),

            const Spacer(),
            const Divider(height: 16),

            // Bottom Row: Price & Stock Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    if (product.purchasePrice > 0)
                      Text(
                        'Cost: ${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: stockColor),
                      const SizedBox(width: 5),
                      Text(
                        stockText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: stockColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
