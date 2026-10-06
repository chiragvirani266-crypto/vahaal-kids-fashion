class Customer {
  final String? id;
  final String name;
  final String mobile;
  final String? address;
  final double lastDiscount;
  final double totalPurchase;
  final int billsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Customer({
    this.id,
    required this.name,
    required this.mobile,
    this.address,
    this.lastDiscount = 0.0,
    this.totalPurchase = 0.0,
    this.billsCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get initials {
    if (name.trim().isEmpty) return 'C';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['bills'] != null && json['bills'] is List) {
      count = (json['bills'] as List).length;
    }

    return Customer(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Unknown Customer',
      mobile: json['mobile'] as String? ?? '',
      address: json['address'] as String?,
      lastDiscount: double.tryParse(json['last_discount']?.toString() ?? '0') ?? 0.0,
      totalPurchase: double.tryParse(json['total_purchase']?.toString() ?? '0') ?? 0.0,
      billsCount: count,
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
      'name': name.trim(),
      'mobile': mobile.trim(),
      'address': address?.trim(),
      'last_discount': lastDiscount,
      'total_purchase': totalPurchase,
    };
  }

  Customer copyWith({
    String? id,
    String? name,
    String? mobile,
    String? address,
    double? lastDiscount,
    double? totalPurchase,
    int? billsCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      lastDiscount: lastDiscount ?? this.lastDiscount,
      totalPurchase: totalPurchase ?? this.totalPurchase,
      billsCount: billsCount ?? this.billsCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
