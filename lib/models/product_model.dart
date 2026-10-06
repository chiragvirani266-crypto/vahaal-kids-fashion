import 'product_variant_model.dart';

class Product {
  final String? id;
  final String sku;
  final String? barcode;
  final String productName;
  final String category;
  final String brand;
  final String gender; // 'Boy' | 'Girl' | 'Unisex' | 'Infant'
  final double purchasePrice;
  final double sellingPrice;
  final String? imageUrl;
  final bool isActive;
  final List<ProductVariant> variants;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    required this.sku,
    this.barcode,
    required this.productName,
    required this.category,
    this.brand = 'Vahaal',
    required this.gender,
    required this.purchasePrice,
    required this.sellingPrice,
    this.imageUrl,
    this.isActive = true,
    this.variants = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get totalStock => variants.fold(0, (sum, item) => sum + item.stockQuantity);
  bool get hasLowStock => variants.any((v) => v.isLowStock);
  bool get isOutOfStock => variants.isEmpty || totalStock <= 0;
  int get variantCount => variants.length;
  double get profitMargin => sellingPrice - purchasePrice;
  double get profitPercentage => purchasePrice > 0 ? ((sellingPrice - purchasePrice) / purchasePrice) * 100 : 0.0;

  factory Product.fromJson(Map<String, dynamic> json) {
    List<ProductVariant> parsedVariants = [];
    if (json['product_variants'] != null && json['product_variants'] is List) {
      parsedVariants = (json['product_variants'] as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    return Product(
      id: json['id'] as String?,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      productName: json['product_name'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      brand: json['brand'] as String? ?? 'Vahaal',
      gender: json['gender'] as String? ?? 'Unisex',
      purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0,
      sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0.0,
      imageUrl: json['image_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      variants: parsedVariants,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id != null) 'id': id,
      'sku': sku,
      'barcode': barcode,
      'product_name': productName,
      'category': category,
      'brand': brand,
      'gender': gender,
      'purchase_price': purchasePrice,
      'selling_price': sellingPrice,
      'image_url': imageUrl,
      'is_active': isActive,
    };
  }

  Product copyWith({
    String? id,
    String? sku,
    String? barcode,
    String? productName,
    String? category,
    String? brand,
    String? gender,
    double? purchasePrice,
    double? sellingPrice,
    String? imageUrl,
    bool? isActive,
    List<ProductVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      brand: brand ?? this.brand,
      gender: gender ?? this.gender,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
