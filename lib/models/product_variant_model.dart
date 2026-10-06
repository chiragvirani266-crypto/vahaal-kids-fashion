class ProductVariant {
  final String? id;
  final String? productId;
  final String size;
  final String color;
  final String sku;
  final String barcode;
  final double? purchasePrice;
  final double? sellingPrice;
  final int stockQuantity;
  final int lowStockAlert;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductVariant({
    this.id,
    this.productId,
    required this.size,
    required this.color,
    required this.sku,
    required this.barcode,
    this.purchasePrice,
    this.sellingPrice,
    this.stockQuantity = 0,
    this.lowStockAlert = 3,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= lowStockAlert;
  bool get isOutOfStock => stockQuantity <= 0;

  String get displayName => '$size / $color';

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String?,
      productId: json['product_id'] as String?,
      size: json['size'] as String? ?? '',
      color: json['color'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      purchasePrice: json['purchase_price'] != null
          ? double.tryParse(json['purchase_price'].toString())
          : null,
      sellingPrice: json['selling_price'] != null
          ? double.tryParse(json['selling_price'].toString())
          : null,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      lowStockAlert: (json['low_stock_alert'] as num?)?.toInt() ?? 3,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    final map = <String, dynamic>{
      if (includeId && id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      'size': size,
      'color': color,
      'sku': sku,
      'barcode': barcode,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_alert': lowStockAlert,
    };
    return map;
  }

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? size,
    String? color,
    String? sku,
    String? barcode,
    double? purchasePrice,
    double? sellingPrice,
    int? stockQuantity,
    int? lowStockAlert,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      size: size ?? this.size,
      color: color ?? this.color,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
