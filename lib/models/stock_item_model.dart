enum StockStatus {
  inStock,
  lowStock,
  outOfStock,
}

class StockItem {
  final String variantId;
  final String productId;
  final String productName;
  final String category;
  final String brand;
  final String gender;
  final String size;
  final String color;
  final String sku;
  final String barcode;
  final double sellingPrice;
  final double purchasePrice;
  final int currentStock;
  final int lowStockAlert;
  final bool isProductActive;

  const StockItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.category,
    required this.brand,
    required this.gender,
    required this.size,
    required this.color,
    required this.sku,
    required this.barcode,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.currentStock,
    required this.lowStockAlert,
    required this.isProductActive,
  });

  StockStatus get status {
    if (currentStock <= 0) return StockStatus.outOfStock;
    if (currentStock <= lowStockAlert) return StockStatus.lowStock;
    return StockStatus.inStock;
  }

  String get statusLabel {
    switch (status) {
      case StockStatus.outOfStock:
        return 'Out of Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.inStock:
        return 'In Stock';
    }
  }

  String get variantDisplayName => '$productName ($size / $color)';

  factory StockItem.fromVariantJson(Map<String, dynamic> json) {
    final prod = json['products'] as Map<String, dynamic>? ?? {};

    return StockItem(
      variantId: json['id'] as String,
      productId: (json['product_id'] ?? prod['id'] ?? '') as String,
      productName: (prod['product_name'] as String?) ?? 'Unknown Product',
      category: (prod['category'] as String?) ?? 'General',
      brand: (prod['brand'] as String?) ?? 'Vahaal',
      gender: (prod['gender'] as String?) ?? 'Unisex',
      size: (json['size'] as String?) ?? '',
      color: (json['color'] as String?) ?? '',
      sku: (json['sku'] as String?) ?? '',
      barcode: (json['barcode'] as String?) ?? '',
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? prod['selling_price']?.toString() ?? '0') ?? 0.0,
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? prod['purchase_price']?.toString() ?? '0') ?? 0.0,
      currentStock: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockAlert: (json['low_stock_alert'] as num?)?.toInt() ?? 3,
      isProductActive: (prod['is_active'] as bool?) ?? true,
    );
  }
}
