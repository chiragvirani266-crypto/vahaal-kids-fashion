import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common/app_badge.dart';
import '../../widgets/common/app_empty_state.dart';
import '../../widgets/common/app_loading_state.dart';
import '../../widgets/common/app_text_field.dart';
import 'add_product_screen.dart';
import 'label_print_screen.dart';
import 'product_details_screen.dart';

class ProductListScreen extends StatefulWidget {
  final bool isEmbedded;

  const ProductListScreen({
    super.key,
    this.isEmbedded = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  bool _isTableView = true;

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
    final isDesktop = size.width >= 900;

    final content = Column(
      children: [
        // Embedded Header Bar when inside desktop workstation shell
        if (widget.isEmbedded)
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Products & Sizes Catalog',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${provider.products.length} products • 0–12Y Kids Wear',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // View Mode Switcher on Desktop
                if (isDesktop) ...[
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.table_chart_rounded, size: 16),
                        label: Text('Table', style: TextStyle(fontSize: 12)),
                      ),
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.grid_view_rounded, size: 16),
                        label: Text('Cards', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    selected: {_isTableView},
                    onSelectionChanged: (set) => setState(() => _isTableView = set.first),
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.qr_code_2_rounded),
                    tooltip: 'Print Barcode Labels',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LabelPrintScreen()),
                      );
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh',
                  onPressed: () => provider.loadProducts(refresh: true),
                ),
                if (isDesktop)
                  IconButton(
                    icon: Icon(
                      provider.includeInactive ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                      color: provider.includeInactive ? AppColors.secondary : null,
                    ),
                    tooltip: provider.includeInactive ? 'Showing Inactive Items' : 'Show Inactive Items',
                    onPressed: () => provider.setIncludeInactive(!provider.includeInactive),
                  ),
                const SizedBox(width: 8),
                if (isDesktop)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Product'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  )
                else
                  IconButton.filled(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddProductScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    tooltip: 'New Product',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

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
                        color: provider.lowStockOnly ? AppColors.warning : AppColors.warning.withValues(alpha: 0.3),
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

        // Product List / Table / Grid
        Expanded(
          child: provider.isLoading
              ? const AppLoadingState(message: 'Loading products & size variants...')
              : provider.filteredProducts.isEmpty
                  ? AppEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No Products Found',
                      description: provider.searchQuery.isNotEmpty || provider.selectedCategory != 'All'
                          ? 'No items match your active search or filters. Try adjusting keywords.'
                          : 'Start building your kidswear catalog by creating your first product.',
                      actionLabel: 'Add New Product',
                      actionIcon: Icons.add_rounded,
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AddProductScreen()),
                        );
                      },
                    )
                  : RefreshIndicator(
                      onRefresh: () => provider.loadProducts(refresh: true),
                      child: isDesktop
                          ? (_isTableView
                              ? _buildDesktopTable(context, provider.filteredProducts, isDark)
                              : _buildDesktopGrid(context, provider.filteredProducts))
                          : _buildMobileList(context, provider.filteredProducts),
                    ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return Material(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Product Catalog',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // View mode toggle on desktop
          if (isDesktop) ...[
            IconButton(
              icon: Icon(_isTableView ? Icons.grid_view_rounded : Icons.table_chart_rounded),
              tooltip: _isTableView ? 'Switch to Grid Cards' : 'Switch to Data Table',
              onPressed: () => setState(() => _isTableView = !_isTableView),
            ),
            IconButton(
              icon: const Icon(Icons.qr_code_2_rounded),
              tooltip: 'Print Barcode Labels',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LabelPrintScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(
                provider.includeInactive ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                color: provider.includeInactive ? AppColors.secondary : null,
              ),
              tooltip: provider.includeInactive ? 'Showing Inactive Items' : 'Show Inactive Items',
              onPressed: () => provider.setIncludeInactive(!provider.includeInactive),
            ),
          ] else
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (val) {
                if (val == 'labels') {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LabelPrintScreen()),
                  );
                } else if (val == 'inactive') {
                  provider.setIncludeInactive(!provider.includeInactive);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'labels',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Print Labels'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'inactive',
                  child: Row(
                    children: [
                      Icon(
                        provider.includeInactive ? Icons.visibility_rounded : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(provider.includeInactive ? 'Hide Inactive' : 'Show Inactive'),
                    ],
                  ),
                ),
              ],
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => provider.loadProducts(refresh: true),
          ),
          const SizedBox(width: 4),
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
      body: content,
    );
  }

  // ==========================================
  // RESPONSIVE DESKTOP DATA TABLE
  // ==========================================
  Widget _buildDesktopTable(BuildContext context, List<Product> products, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 80),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 850),
              child: DataTable(
                headingRowHeight: 48,
                dataRowMinHeight: 56,
                dataRowMaxHeight: 64,
                headingRowColor: WidgetStateProperty.all(
                  isDark ? AppColors.cardDark : const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(label: Text('Item & SKU', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Gender', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Margin', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Sizes', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: products.map((product) {
                  final margin = product.sellingPrice > 0 && product.purchasePrice > 0
                      ? (((product.sellingPrice - product.purchasePrice) / product.sellingPrice) * 100).toStringAsFixed(0)
                      : null;

                  return DataRow(
                    cells: [
                      // Product Name & SKU
                      DataCell(
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(productId: product.id!),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    product.productName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    'SKU: ${product.sku}${product.barcode != null ? " • ${product.barcode}" : ""}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Category
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            product.category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      // Gender
                      DataCell(AppBadge.gender(product.gender)),
                      // Price
                      DataCell(
                        Text(
                          '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      // Cost
                      DataCell(
                        Text(
                          product.purchasePrice > 0
                              ? '${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(2)}'
                              : '-',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      // Margin
                      DataCell(
                        margin != null
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+$margin%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              )
                            : const Text('-', style: TextStyle(color: Colors.grey)),
                      ),
                      // Stock Status Badge
                      DataCell(AppBadge.stock(stockQuantity: product.totalStock)),
                      // Variants Count
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.variants.length} ${product.variants.length == 1 ? "variant" : "variants"}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                      // Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 18),
                              tooltip: 'View Details',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsScreen(productId: product.id!),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.qr_code_2_rounded, size: 18, color: AppColors.secondary),
                              tooltip: 'Print Barcode Labels',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LabelPrintScreen(initialProduct: product),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
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
        return _ProductCard(product: product, isGrid: false);
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
        return _ProductCard(product: product, isGrid: true);
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final bool isGrid;

  const _ProductCard({
    required this.product,
    this.isGrid = false,
  });

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight = constraints.hasBoundedHeight;
        final shouldUseSpacer = isGrid && hasBoundedHeight;

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
              mainAxisSize: shouldUseSpacer ? MainAxisSize.max : MainAxisSize.min,
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

                if (shouldUseSpacer)
                  const Spacer()
                else
                  const SizedBox(height: 12),

                const Divider(height: 16),

                // Bottom Row: Price & Stock Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppConstants.currencySymbol}${product.sellingPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (product.purchasePrice > 0)
                            Text(
                              'Cost: ${AppConstants.currencySymbol}${product.purchasePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stockColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
      },
    );
  }
}
