import 'bill_item_model.dart';

class Bill {
  final String? id;
  final String billNumber;
  final String? customerId;
  final String? customerNameSnapshot;
  final String? customerMobileSnapshot;
  final DateTime billDate;
  final double subtotal;
  final double discount;
  final double grandTotal;
  final String paymentMethod; // 'cash' | 'upi' | 'card' | 'other' | 'split'
  final String? notes;
  final String? cashierId;
  final String? cashierName;
  final List<BillItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Bill({
    this.id,
    required this.billNumber,
    this.customerId,
    this.customerNameSnapshot,
    this.customerMobileSnapshot,
    required this.billDate,
    required this.subtotal,
    this.discount = 0.0,
    required this.grandTotal,
    this.paymentMethod = 'cash',
    this.notes,
    this.cashierId,
    this.cashierName,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  int get totalItemsCount => items.length;
  int get totalUnitsCount => items.fold(0, (sum, item) => sum + item.quantity);

  String get displayCustomerName =>
      (customerNameSnapshot != null && customerNameSnapshot!.trim().isNotEmpty)
          ? customerNameSnapshot!
          : 'Walk-in Customer';

  String get displayCustomerMobile =>
      (customerMobileSnapshot != null && customerMobileSnapshot!.trim().isNotEmpty)
          ? customerMobileSnapshot!
          : 'N/A';

  factory Bill.fromJson(Map<String, dynamic> json) {
    List<BillItem> parsedItems = [];
    if (json['bill_items'] != null && json['bill_items'] is List) {
      parsedItems = (json['bill_items'] as List)
          .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    String? cashierName;
    if (json['profiles'] != null && json['profiles'] is Map) {
      cashierName = json['profiles']['full_name'] as String?;
    }

    return Bill(
      id: json['id'] as String?,
      billNumber: json['bill_number'] as String? ?? 'N/A',
      customerId: json['customer_id'] as String?,
      customerNameSnapshot: json['customer_name_snapshot'] as String?,
      customerMobileSnapshot: json['customer_mobile_snapshot'] as String?,
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'].toString()) ?? DateTime.now()
          : (json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
              : DateTime.now()),
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      grandTotal: double.tryParse(json['grand_total']?.toString() ?? '0') ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      notes: json['notes'] as String?,
      cashierId: json['cashier_id'] as String?,
      cashierName: cashierName,
      items: parsedItems,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toRpcJson() {
    return {
      'bill_number': billNumber,
      'customer_id': customerId,
      'customer_name_snapshot': customerNameSnapshot,
      'customer_mobile_snapshot': customerMobileSnapshot,
      'bill_date': billDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'notes': notes,
      'cashier_id': cashierId,
    };
  }

  Map<String, dynamic> toJson({bool includeId = true}) {
    return {
      if (includeId && id != null) 'id': id,
      'bill_number': billNumber,
      'customer_id': customerId,
      'customer_name_snapshot': customerNameSnapshot,
      'customer_mobile_snapshot': customerMobileSnapshot,
      'bill_date': billDate.toIso8601String(),
      'subtotal': subtotal,
      'discount': discount,
      'grand_total': grandTotal,
      'payment_method': paymentMethod,
      'notes': notes,
      'cashier_id': cashierId,
    };
  }

  Bill copyWith({
    String? id,
    String? billNumber,
    String? customerId,
    String? customerNameSnapshot,
    String? customerMobileSnapshot,
    DateTime? billDate,
    double? subtotal,
    double? discount,
    double? grandTotal,
    String? paymentMethod,
    String? notes,
    String? cashierId,
    String? cashierName,
    List<BillItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bill(
      id: id ?? this.id,
      billNumber: billNumber ?? this.billNumber,
      customerId: customerId ?? this.customerId,
      customerNameSnapshot: customerNameSnapshot ?? this.customerNameSnapshot,
      customerMobileSnapshot: customerMobileSnapshot ?? this.customerMobileSnapshot,
      billDate: billDate ?? this.billDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
