import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import '../../providers/product_provider.dart';
import '../../services/printer/label_printer_service.dart';
import '../../services/printer/printer_models.dart';
import '../../theme/app_colors.dart';
import 'widgets/label_sticker_card.dart';

class LabelPrintScreen extends StatefulWidget {
  final Product? initialProduct;
  final ProductVariant? initialVariant;
  final bool isEmbedded;

  const LabelPrintScreen({
    super.key,
    this.initialProduct,
    this.initialVariant,
    this.isEmbedded = false,
  });

  @override
  State<LabelPrintScreen> createState() => _LabelPrintScreenState();
}

class _LabelPrintScreenState extends State<LabelPrintScreen> {
  final LabelPrinterService _printerService = LabelPrinterServiceFactory.getInstance();

  Product? _selectedProduct;
  List<LabelPrintItem> _items = [];
  int _previewIndex = 0;

  LabelConfig _labelConfig = const LabelConfig();
  PrinterConfig _printerConfig = const PrinterConfig();

  bool _isPrinting = false;
  bool _isAsciiPreview = false;
  double _zoomScale = 1.0;

  final TextEditingController _barcodeSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ProductProvider>();
      if (provider.products.isEmpty) {
        provider.loadProducts();
      }
      _initializeProductSelection();
    });
  }

  @override
  void dispose() {
    _barcodeSearchController.dispose();
    super.dispose();
  }

  void _initializeProductSelection() {
    final provider = context.read<ProductProvider>();
    final targetProduct = widget.initialProduct ??
        (provider.products.isNotEmpty ? provider.products.first : null);

    if (targetProduct != null) {
      _selectProduct(targetProduct, initialVariant: widget.initialVariant);
    }
  }

  void _selectProduct(Product product, {ProductVariant? initialVariant}) {
    setState(() {
      _selectedProduct = product;
      _items = product.variants.map((variant) {
        final isSelected = initialVariant == null || initialVariant.id == variant.id;
        return LabelPrintItem(
          variant: variant,
          product: product,
          quantity: 1,
          isSelected: isSelected,
        );
      }).toList();

      if (initialVariant != null) {
        final idx = _items.indexWhere((i) => i.variant.id == initialVariant.id);
        _previewIndex = idx >= 0 ? idx : 0;
      } else {
        _previewIndex = 0;
      }
    });
  }

  int get _totalSelectedLabels {
    return _items.where((i) => i.isSelected).fold<int>(0, (sum, i) => sum + i.quantity);
  }

  int get _selectedVariantCount {
    return _items.where((i) => i.isSelected).length;
  }

  LabelPrintItem? get _currentPreviewItem {
    if (_items.isEmpty) return null;
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.isNotEmpty) {
      if (_previewIndex >= selected.length) {
        _previewIndex = 0;
      }
      return selected[_previewIndex];
    }
    return _items.first;
  }

  void _toggleSelectAll(bool selectAll) {
    setState(() {
      _items = _items.map((item) => item.copyWith(isSelected: selectAll)).toList();
    });
  }

  void _fillStockQuantities() {
    setState(() {
      _items = _items.map((item) {
        final stock = item.variant.stockQuantity;
        final qty = stock > 0 ? stock : 1;
        return item.copyWith(quantity: qty, isSelected: true);
      }).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Quantities updated to match in-stock inventory.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _setAllQuantitiesToOne() {
    setState(() {
      _items = _items.map((item) => item.copyWith(quantity: 1)).toList();
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _items[index].quantity;
      final newQty = (current + delta).clamp(1, 999);
      _items[index] = _items[index].copyWith(quantity: newQty);
    });
  }

  // Barcode / SKU quick lookup
  void _handleBarcodeSearch(String code) {
    if (code.trim().isEmpty) return;
    final clean = code.trim().toLowerCase();
    final provider = context.read<ProductProvider>();

    for (final prod in provider.products) {
      for (final v in prod.variants) {
        if (v.barcode.toLowerCase() == clean || v.sku.toLowerCase() == clean) {
          _selectProduct(prod, initialVariant: v);
          _barcodeSearchController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.success,
              content: Text('Found variant: ${prod.productName} (${v.displayName})'),
              duration: const Duration(seconds: 2),
            ),
          );
          return;
        }
      }
      if (prod.sku.toLowerCase() == clean || (prod.barcode != null && prod.barcode!.toLowerCase() == clean)) {
        _selectProduct(prod);
        _barcodeSearchController.clear();
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.error,
        content: Text('No product or variant found matching "$code"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handlePrintSingle() async {
    final preview = _currentPreviewItem;
    if (preview == null) return;

    setState(() => _isPrinting = true);
    final result = await _printerService.printSingleLabel(
      preview.variant,
      product: preview.product,
      config: _labelConfig,
      printerConfig: _printerConfig,
    );

    if (mounted) {
      setState(() => _isPrinting = false);
      _showResultFeedback(result, '1 test label printed');
    }
  }

  Future<void> _handlePrintSelected() async {
    final selectedItems = _items.where((i) => i.isSelected && i.quantity > 0).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.warning,
          content: Text('Please select at least one variant with quantity > 0'),
        ),
      );
      return;
    }

    final totalCount = _totalSelectedLabels;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Confirm Label Print Job'),
          ],
        ),
        content: Text(
          'Print $totalCount barcode labels across ${selectedItems.length} selected variant(s)?\n\n'
          'Label Size: ${_labelConfig.preset.label}\n'
          'Target: ${_printerConfig.connectionType.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.print_rounded, size: 18),
            label: Text('Print ($totalCount Labels)'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPrinting = true);
    final result = await _printerService.printBatchLabels(
      selectedItems,
      config: _labelConfig,
      printerConfig: _printerConfig,
    );

    if (mounted) {
      setState(() => _isPrinting = false);
      _showResultFeedback(result, '$totalCount labels printed');
    }
  }

  void _showResultFeedback(PrintResult result, String successSummary) {
    if (result.status == PrintStatus.fallbackPreview) {
      _showFallbackDialog(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.error,
          content: Row(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(result.message)),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showFallbackDialog(PrintResult result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Print Output & Preview'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  result.message,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Formatted Monospaced Thermal Payload:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 220),
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    result.formattedText ?? 'No text generated.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Text'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: result.formattedText ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Label text copied to clipboard.')),
              );
            },
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showConfigSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Label & Printer Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Preset Selector
              const Text(
                'Label Dimensions & Format',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...LabelSizePreset.values.map((preset) {
                final isSelected = _labelConfig.preset == preset;
                return RadioListTile<LabelSizePreset>(
                  value: preset,
                  groupValue: _labelConfig.preset,
                  title: Text(preset.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(preset.description, style: const TextStyle(fontSize: 12)),
                  selected: isSelected,
                  onChanged: (val) {
                    if (val != null) {
                      setSheetState(() {
                        _labelConfig = _labelConfig.copyWith(
                          preset: val,
                          widthMm: val.defaultWidthMm,
                          heightMm: val.defaultHeightMm,
                        );
                      });
                      setState(() {});
                    }
                  },
                );
              }),

              const SizedBox(height: 16),
              const Text(
                'Sticker Content Fields',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Store Name (VAHAAL KIDS FASHION)'),
                value: _labelConfig.showStoreName,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showStoreName: v));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Product Title'),
                value: _labelConfig.showProductName,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showProductName: v));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Size & Color Badges'),
                value: _labelConfig.showSizeAndColor,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showSizeAndColor: v));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('SKU Code'),
                value: _labelConfig.showSku,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showSku: v));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('1D Barcode & Number'),
                value: _labelConfig.showBarcode,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showBarcode: v));
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Selling Price / MRP'),
                value: _labelConfig.showPrice,
                onChanged: (v) {
                  setSheetState(() => _labelConfig = _labelConfig.copyWith(showPrice: v));
                  setState(() {});
                },
              ),

              const SizedBox(height: 16),
              const Text(
                'Thermal Printer Communication',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<PrinterConnectionType>(
                value: _printerConfig.connectionType,
                decoration: const InputDecoration(
                  labelText: 'Connection Mode',
                  border: OutlineInputBorder(),
                ),
                items: PrinterConnectionType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setSheetState(() => _printerConfig = _printerConfig.copyWith(connectionType: val));
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 12),
              if (_printerConfig.connectionType == PrinterConnectionType.network) ...[
                TextFormField(
                  initialValue: _printerConfig.ipAddress,
                  decoration: const InputDecoration(
                    labelText: 'Printer IP Address (e.g. 192.168.1.100)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _printerConfig = _printerConfig.copyWith(ipAddress: v.trim()),
                ),
                const SizedBox(height: 10),
              ],

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Save & Apply Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final body = productProvider.isLoading && productProvider.products.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : isDesktop
            ? _buildDesktopLayout(productProvider)
            : _buildMobileLayout(productProvider);

    if (widget.isEmbedded) {
      return Container(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    'Barcode Label Printing Workstation',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Label & Printer Settings',
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _showConfigSheet,
                  ),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Label Printing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${AppConstants.storeName} • Barcode & Price Tag Generator',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Label & Printer Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: _showConfigSheet,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: body,
      bottomNavigationBar: isDesktop ? null : _buildMobileBottomBar(),
    );
  }

  // DESKTOP LAYOUT (Split View: Left Selection Table, Right Sticky Live Preview)
  Widget _buildDesktopLayout(ProductProvider provider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Product Selection + Variant List
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductSelector(provider),
                const SizedBox(height: 16),
                _buildQuickActionToolbar(),
                const SizedBox(height: 14),
                _buildVariantsList(),
              ],
            ),
          ),
        ),

        // Vertical divider
        Container(width: 1, color: Colors.grey.withValues(alpha: 0.2)),

        // Right Column: Live Sticky Sticker Preview & Print Controls
        Expanded(
          flex: 4,
          child: Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildPreviewHeader(),
                  const SizedBox(height: 16),
                  _buildLiveStickerPreview(),
                  const SizedBox(height: 20),
                  _buildCarouselNavigator(),
                  const SizedBox(height: 24),
                  _buildDesktopActionButtons(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // MOBILE LAYOUT
  Widget _buildMobileLayout(ProductProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductSelector(provider),
          const SizedBox(height: 16),
          _buildQuickActionToolbar(),
          const SizedBox(height: 14),
          _buildVariantsList(),
        ],
      ),
    );
  }

  // Product Selector & Barcode Quick Search
  Widget _buildProductSelector(ProductProvider provider) {
    final products = provider.products;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checkroom_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Select Product',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                if (_selectedProduct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_selectedProduct!.variants.length} Variants Available',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Dropdown Selector
            DropdownButtonFormField<String>(
              value: _selectedProduct?.id,
              decoration: const InputDecoration(
                labelText: 'Choose Product Catalog Item',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: products.map((p) {
                return DropdownMenuItem<String>(
                  value: p.id,
                  child: Text(
                    '${p.productName} (${p.category} • ${p.gender})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (productId) {
                if (productId != null) {
                  final chosen = products.firstWhere((p) => p.id == productId);
                  _selectProduct(chosen);
                }
              },
            ),
            const SizedBox(height: 10),

            // Quick Barcode / SKU Scan Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeSearchController,
                    decoration: const InputDecoration(
                      hintText: 'Or scan/type barcode or SKU...',
                      prefixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _handleBarcodeSearch,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  onPressed: () => _handleBarcodeSearch(_barcodeSearchController.text),
                  child: const Text('Find'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Bulk Operations Toolbar
  Widget _buildQuickActionToolbar() {
    final allSelected = _items.isNotEmpty && _items.every((i) => i.isSelected);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilterChip(
          selected: allSelected,
          label: Text(allSelected ? 'Deselect All' : 'Select All'),
          onSelected: (val) => _toggleSelectAll(!allSelected),
        ),
        ActionChip(
          avatar: const Icon(Icons.inventory_rounded, size: 16),
          label: const Text('Fill Stock Qty'),
          tooltip: 'Set label quantity equal to each variant\'s available inventory',
          onPressed: _fillStockQuantities,
        ),
        ActionChip(
          avatar: const Icon(Icons.filter_1_rounded, size: 16),
          label: const Text('Set All to 1'),
          onPressed: _setAllQuantitiesToOne,
        ),
        Chip(
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          label: Text(
            '$_selectedVariantCount variants / $_totalSelectedLabels labels total',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // Variant Selection List
  Widget _buildVariantsList() {
    if (_items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        alignment: Alignment.center,
        child: const Text('No variants found for the selected product.'),
      );
    }

    return Column(
      children: List.generate(_items.length, (index) {
        final item = _items[index];
        final v = item.variant;
        final isFocused = _currentPreviewItem?.variant.id == v.id;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isFocused
                  ? AppColors.primary
                  : (item.isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2)),
              width: isFocused ? 1.8 : 1.0,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                final selected = _items.where((i) => i.isSelected).toList();
                final previewIdx = selected.indexWhere((i) => i.variant.id == v.id);
                if (previewIdx >= 0) {
                  _previewIndex = previewIdx;
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // 1. Checkbox
                  Checkbox(
                    value: item.isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _items[index] = item.copyWith(isSelected: val ?? false);
                      });
                    },
                  ),

                  // 2. Size & Color Badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                v.size,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              v.color,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            // Low stock badge
                            if (v.isOutOfStock)
                              _buildStockBadge('Out of stock', AppColors.error)
                            else if (v.isLowStock)
                              _buildStockBadge('Low (${v.stockQuantity})', AppColors.warning)
                            else
                              _buildStockBadge('Stock: ${v.stockQuantity}', AppColors.success),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              v.sku.isNotEmpty ? v.sku : 'SKU: -',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Rs. ${(item.effectivePrice).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 3. Quantity Stepper
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                        onPressed: item.quantity > 1 ? () => _updateQuantity(index, -1) : null,
                      ),
                      Container(
                        width: 44,
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                        onPressed: () => _updateQuantity(index, 1),
                      ),
                      const SizedBox(width: 6),
                      // Quick Print 1 on this row
                      IconButton(
                        tooltip: 'Print 1 Label for this variant',
                        icon: const Icon(Icons.print_outlined, size: 20, color: AppColors.primary),
                        onPressed: () async {
                          setState(() => _isPrinting = true);
                          final result = await _printerService.printSingleLabel(
                            v,
                            product: item.product,
                            config: _labelConfig,
                            printerConfig: _printerConfig,
                          );
                          if (mounted) {
                            setState(() => _isPrinting = false);
                            _showResultFeedback(result, '1 label printed');
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStockBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  // PREVIEW PANE HEADER
  Widget _buildPreviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              _isAsciiPreview ? 'Thermal Text Preview' : 'Sticker Tag Preview',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        Row(
          children: [
            // View Mode Toggle
            IconButton(
              tooltip: _isAsciiPreview ? 'Switch to Visual Sticker' : 'Switch to Monospaced ESC/POS Text',
              icon: Icon(_isAsciiPreview ? Icons.image_rounded : Icons.code_rounded),
              onPressed: () => setState(() => _isAsciiPreview = !_isAsciiPreview),
            ),
            // Zoom controls
            IconButton(
              tooltip: 'Zoom Out',
              icon: const Icon(Icons.zoom_out_rounded, size: 20),
              onPressed: _zoomScale > 0.8 ? () => setState(() => _zoomScale -= 0.1) : null,
            ),
            IconButton(
              tooltip: 'Zoom In',
              icon: const Icon(Icons.zoom_in_rounded, size: 20),
              onPressed: _zoomScale < 1.4 ? () => setState(() => _zoomScale += 0.1) : null,
            ),
          ],
        ),
      ],
    );
  }

  // LIVE STICKER PREVIEW
  Widget _buildLiveStickerPreview() {
    final preview = _currentPreviewItem;

    if (preview == null) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const Text('Select a product to view label sticker preview.'),
      );
    }

    if (_isAsciiPreview) {
      final asciiText = _printerService.formatLabelText(
        preview.variant,
        product: preview.product,
        config: _labelConfig,
      );

      return Container(
        width: 320,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade700),
        ),
        child: Text(
          asciiText,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: Colors.greenAccent,
            height: 1.25,
          ),
        ),
      );
    }

    return Center(
      child: LabelStickerCard(
        variant: preview.variant,
        product: preview.product,
        config: _labelConfig,
        scale: _zoomScale,
      ),
    );
  }

  // Carousel navigator when multiple variants are selected
  Widget _buildCarouselNavigator() {
    final selected = _items.where((i) => i.isSelected).toList();
    if (selected.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _previewIndex > 0
              ? () => setState(() => _previewIndex--)
              : null,
        ),
        Text(
          'Sticker ${_previewIndex + 1} of ${selected.length} (${selected[_previewIndex].variant.displayName})',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _previewIndex < selected.length - 1
              ? () => setState(() => _previewIndex++)
              : null,
        ),
      ],
    );
  }

  // Desktop action buttons
  Widget _buildDesktopActionButtons() {
    final count = _totalSelectedLabels;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: _isPrinting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.print_rounded),
            label: Text(
              _isPrinting ? 'Sending to Printer...' : 'Print Selected ($count Labels)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: (_isPrinting || count == 0) ? null : _handlePrintSelected,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: const BorderSide(color: AppColors.secondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.receipt_long_rounded, size: 18),
            label: const Text('Print 1 Test Label'),
            onPressed: _isPrinting ? null : _handlePrintSingle,
          ),
        ),
      ],
    );
  }

  // Mobile Bottom Action Bar
  Widget _buildMobileBottomBar() {
    final count = _totalSelectedLabels;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.visibility_rounded, size: 18),
              label: const Text('Preview'),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (ctx) => Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPreviewHeader(),
                        const SizedBox(height: 16),
                        _buildLiveStickerPreview(),
                        const SizedBox(height: 16),
                        _buildCarouselNavigator(),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _isPrinting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.print_rounded),
                label: Text('Print ($count Labels)', style: const TextStyle(fontWeight: FontWeight.bold)),
                onPressed: (_isPrinting || count == 0) ? null : _handlePrintSelected,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
