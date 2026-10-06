class CustomerPurchaseBill {
  final String id;
  final String billNumber;
  final DateTime billDate;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String paymentMethod;
  final String? notes;
  final int itemsCount;

  const CustomerPurchaseBill({
    required this.id,
    required this.billNumber,
    required this.billDate,
    required this.subtotal,
    required this.discount,
    required this.grandTotal,
    required this.paymentMethod,
    this.notes,
    this.itemsCount = 0,
  });

  factory CustomerPurchaseBill.fromJson(Map<String, dynamic> json) {
    int items = 0;
    if (json['bill_items'] != null && json['bill_items'] is List) {
      items = (json['bill_items'] as List).length;
    }

    return CustomerPurchaseBill(
      id: json['id'] as String,
      billNumber: json['bill_number'] as String? ?? 'N/A',
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'].toString()) ?? DateTime.now()
          : (json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now()),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notes: json['notes'] as String?,
      itemsCount: items,
    );
  }
}
