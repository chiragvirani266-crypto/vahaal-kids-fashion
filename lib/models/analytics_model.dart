class DashboardOverview {
  final double todaySales;
  final int todayBillsCount;
  final double monthSales;
  final int monthBillsCount;
  final double yearSales;
  final int yearBillsCount;
  final double totalSales;
  final int totalBillsCount;
  final int totalCustomersCount;
  final int totalProductsCount;
  final int lowStockCount;
  final int totalStockUnits;

  const DashboardOverview({
    this.todaySales = 0.0,
    this.todayBillsCount = 0,
    this.monthSales = 0.0,
    this.monthBillsCount = 0,
    this.yearSales = 0.0,
    this.yearBillsCount = 0,
    this.totalSales = 0.0,
    this.totalBillsCount = 0,
    this.totalCustomersCount = 0,
    this.totalProductsCount = 0,
    this.lowStockCount = 0,
    this.totalStockUnits = 0,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      todaySales: double.tryParse(json['today_sales']?.toString() ?? '0') ?? 0.0,
      todayBillsCount: (json['today_bills_count'] as num?)?.toInt() ?? 0,
      monthSales: double.tryParse(json['month_sales']?.toString() ?? '0') ?? 0.0,
      monthBillsCount: (json['month_bills_count'] as num?)?.toInt() ?? 0,
      yearSales: double.tryParse(json['year_sales']?.toString() ?? '0') ?? 0.0,
      yearBillsCount: (json['year_bills_count'] as num?)?.toInt() ?? 0,
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '0') ?? 0.0,
      totalBillsCount: (json['total_bills_count'] as num?)?.toInt() ?? 0,
      totalCustomersCount: (json['total_customers_count'] as num?)?.toInt() ?? 0,
      totalProductsCount: (json['total_products_count'] as num?)?.toInt() ?? 0,
      lowStockCount: (json['low_stock_count'] as num?)?.toInt() ?? 0,
      totalStockUnits: (json['total_stock_units'] as num?)?.toInt() ?? 0,
    );
  }
}

class SalesChartPoint {
  final DateTime date;
  final String label; // e.g. "06 Oct", "Oct 2026", "2026"
  final double salesAmount;
  final int billsCount;

  const SalesChartPoint({
    required this.date,
    required this.label,
    required this.salesAmount,
    required this.billsCount,
  });
}

class TopSellingProduct {
  final String productId;
  final String productName;
  final String sku;
  final String category;
  final int totalQuantitySold;
  final double totalRevenue;
  final String? imageUrl;

  const TopSellingProduct({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.category,
    required this.totalQuantitySold,
    required this.totalRevenue,
    this.imageUrl,
  });

  factory TopSellingProduct.fromJson(Map<String, dynamic> json) {
    return TopSellingProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name_snapshot']?.toString() ??
          json['product_name']?.toString() ??
          'Unknown Product',
      sku: json['sku_snapshot']?.toString() ?? json['sku']?.toString() ?? 'N/A',
      category: json['category']?.toString() ?? 'General',
      totalQuantitySold: (json['total_quantity_sold'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      totalRevenue: double.tryParse(
              json['total_revenue']?.toString() ?? json['total']?.toString() ?? '0') ??
          0.0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class TopCustomer {
  final String customerId;
  final String name;
  final String mobile;
  final int totalBillsCount;
  final double totalSpent;
  final double lastDiscount;

  const TopCustomer({
    required this.customerId,
    required this.name,
    required this.mobile,
    required this.totalBillsCount,
    required this.totalSpent,
    this.lastDiscount = 0.0,
  });

  factory TopCustomer.fromJson(Map<String, dynamic> json) {
    int count = 0;
    if (json['bills'] != null && json['bills'] is List) {
      count = (json['bills'] as List).length;
    }

    return TopCustomer(
      customerId: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Customer',
      mobile: json['mobile']?.toString() ?? '',
      totalBillsCount: (json['bills_count'] as num?)?.toInt() ?? count,
      totalSpent: double.tryParse(json['total_purchase']?.toString() ?? '0') ?? 0.0,
      lastDiscount: double.tryParse(json['last_discount']?.toString() ?? '0') ?? 0.0,
    );
  }
}

enum SalesChartGrouping {
  daily,
  monthly,
  yearly,
}
