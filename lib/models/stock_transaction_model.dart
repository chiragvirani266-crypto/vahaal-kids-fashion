class StockTransaction {
  final String id;
  final String variantId;
  final String transactionType; // 'purchase_in' | 'sale' | 'return' | 'adjustment' | 'damage'
  final int quantity; // positive for additions, negative for deductions
  final int previousStock;
  final int newStock;
  final String? reference;
  final String? note;
  final String? createdBy;
  final DateTime createdAt;
  
  // Enriched metadata for UI display
  final String? productName;
  final String? variantSize;
  final String? variantColor;
  final String? variantSku;
  final String? variantBarcode;
  final String? category;
  final String? creatorName;

  const StockTransaction({
    required this.id,
    required this.variantId,
    required this.transactionType,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reference,
    this.note,
    this.createdBy,
    required this.createdAt,
    this.productName,
    this.variantSize,
    this.variantColor,
    this.variantSku,
    this.variantBarcode,
    this.category,
    this.creatorName,
  });

  String get typeLabel {
    switch (transactionType.toLowerCase()) {
      case 'purchase_in':
        return 'Stock In';
      case 'sale':
        return 'Store Sale';
      case 'return':
        return 'Customer Return';
      case 'damage':
        return 'Damage / Loss';
      case 'adjustment':
        return 'Stock Adjustment';
      default:
        return transactionType.toUpperCase();
    }
  }

  bool get isAddition => quantity > 0;

  factory StockTransaction.fromJson(Map<String, dynamic> json) {
    String? prodName;
    String? size;
    String? color;
    String? sku;
    String? barcode;
    String? cat;
    String? creator;

    if (json['product_variants'] != null && json['product_variants'] is Map) {
      final variantMap = json['product_variants'] as Map<String, dynamic>;
      size = variantMap['size'] as String?;
      color = variantMap['color'] as String?;
      sku = variantMap['sku'] as String?;
      barcode = variantMap['barcode'] as String?;

      if (variantMap['products'] != null && variantMap['products'] is Map) {
        final prodMap = variantMap['products'] as Map<String, dynamic>;
        prodName = prodMap['product_name'] as String?;
        cat = prodMap['category'] as String?;
      }
    }

    if (json['profiles'] != null && json['profiles'] is Map) {
      creator = (json['profiles'] as Map<String, dynamic>)['full_name'] as String?;
    }

    return StockTransaction(
      id: json['id'] as String,
      variantId: json['variant_id'] as String,
      transactionType: json['transaction_type'] as String? ?? 'adjustment',
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      previousStock: (json['previous_stock'] as num?)?.toInt() ?? 0,
      newStock: (json['new_stock'] as num?)?.toInt() ?? 0,
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      productName: prodName,
      variantSize: size,
      variantColor: color,
      variantSku: sku,
      variantBarcode: barcode,
      category: cat,
      creatorName: creator,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variant_id': variantId,
      'transaction_type': transactionType,
      'quantity': quantity,
      'previous_stock': previousStock,
      'new_stock': newStock,
      'reference': reference,
      'note': note,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
