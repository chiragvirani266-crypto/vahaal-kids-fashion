class BillItem {
  final String? id;
  final String? billId;
  final String? productId;
  final String variantId;
  final String productNameSnapshot;
  final String skuSnapshot;
  final String sizeSnapshot;
  final String colorSnapshot;
  final int quantity;
  final double unitPrice;
  final double discount;
  final double total;
  final int availableStock;

  const BillItem({
    this.id,
    this.billId,
    this.productId,
    required this.variantId,
    required this.productNameSnapshot,
    required this.skuSnapshot,
    required this.sizeSnapshot,
    required this.colorSnapshot,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
    required this.total,
    this.availableStock = 999,
  });

  String get variantDescription => '$sizeSnapshot / $colorSnapshot';

  BillItem copyWith({
    String? id,
    String? billId,
    String? productId,
    String? variantId,
    String? productNameSnapshot,
    String? skuSnapshot,
    String? sizeSnapshot,
    String? colorSnapshot,
    int? quantity,
    double? unitPrice,
    double? discount,
    double? total,
    int? availableStock,
  }) {
    return BillItem(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      skuSnapshot: skuSnapshot ?? this.skuSnapshot,
      sizeSnapshot: sizeSnapshot ?? this.sizeSnapshot,
      colorSnapshot: colorSnapshot ?? this.colorSnapshot,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String?,
      billId: json['bill_id'] as String?,
      productId: json['product_id'] as String?,
      variantId: json['variant_id'] as String? ?? '',
      productNameSnapshot: json['product_name_snapshot'] as String? ?? 'Item',
      skuSnapshot: json['sku_snapshot'] as String? ?? '',
      sizeSnapshot: json['size_snapshot'] as String? ?? '',
      colorSnapshot: json['color_snapshot'] as String? ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'product_name_snapshot': productNameSnapshot,
      'sku_snapshot': skuSnapshot,
      'size_snapshot': sizeSnapshot,
      'color_snapshot': colorSnapshot,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount': discount,
      'total': total,
    };
  }
}
