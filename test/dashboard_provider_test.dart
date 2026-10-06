import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/analytics_model.dart';
import 'package:vahaal_kids_fashion/providers/dashboard_provider.dart';
import 'package:vahaal_kids_fashion/repositories/dashboard_repository.dart';

class MockDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardOverview> getDashboardOverview() async {
    return const DashboardOverview(
      todaySales: 2450.0,
      todayBillsCount: 3,
      monthSales: 48500.0,
      monthBillsCount: 42,
      yearSales: 280000.0,
      yearBillsCount: 260,
      totalSales: 540000.0,
      totalBillsCount: 490,
      totalCustomersCount: 120,
      totalProductsCount: 45,
      lowStockCount: 4,
      totalStockUnits: 380,
    );
  }

  @override
  Future<List<SalesChartPoint>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
    required SalesChartGrouping grouping,
  }) async {
    if (grouping == SalesChartGrouping.daily) {
      return [
        SalesChartPoint(
          date: DateTime(2026, 10, 1),
          label: '01 Oct',
          salesAmount: 1500.0,
          billsCount: 2,
        ),
        SalesChartPoint(
          date: DateTime(2026, 10, 2),
          label: '02 Oct',
          salesAmount: 2300.0,
          billsCount: 3,
        ),
        SalesChartPoint(
          date: DateTime(2026, 10, 3),
          label: '03 Oct',
          salesAmount: 0.0,
          billsCount: 0,
        ),
        SalesChartPoint(
          date: DateTime(2026, 10, 4),
          label: '04 Oct',
          salesAmount: 3100.0,
          billsCount: 4,
        ),
      ];
    } else if (grouping == SalesChartGrouping.monthly) {
      return [
        SalesChartPoint(
          date: DateTime(2026, 1, 1),
          label: 'Jan 26',
          salesAmount: 42000.0,
          billsCount: 35,
        ),
        SalesChartPoint(
          date: DateTime(2026, 2, 1),
          label: 'Feb 26',
          salesAmount: 38000.0,
          billsCount: 30,
        ),
      ];
    } else {
      return [
        SalesChartPoint(
          date: DateTime(2025, 1, 1),
          label: '2025',
          salesAmount: 320000.0,
          billsCount: 300,
        ),
        SalesChartPoint(
          date: DateTime(2026, 1, 1),
          label: '2026',
          salesAmount: 280000.0,
          billsCount: 260,
        ),
      ];
    }
  }

  @override
  Future<List<TopSellingProduct>> getTopSellingProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return const [
      TopSellingProduct(
        productId: 'p1',
        productName: 'Cotton Graphic T-Shirt',
        sku: 'VKF-TSH-001',
        category: 'T-Shirts',
        totalQuantitySold: 28,
        totalRevenue: 13972.0,
      ),
      TopSellingProduct(
        productId: 'p2',
        productName: 'Denim Dungarees',
        sku: 'VKF-DNG-002',
        category: 'Dungarees',
        totalQuantitySold: 16,
        totalRevenue: 14384.0,
      ),
    ];
  }

  @override
  Future<List<TopCustomer>> getTopCustomers({int limit = 5}) async {
    return const [
      TopCustomer(
        customerId: 'c1',
        name: 'Priya Sharma',
        mobile: '9876543210',
        totalBillsCount: 8,
        totalSpent: 12450.0,
        lastDiscount: 100.0,
      ),
      TopCustomer(
        customerId: 'c2',
        name: 'Rahul Patel',
        mobile: '9988776655',
        totalBillsCount: 5,
        totalSpent: 8600.0,
        lastDiscount: 50.0,
      ),
    ];
  }
}

void main() {
  group('DashboardProvider & Sales Analytics Unit Tests', () {
    late MockDashboardRepository mockRepo;
    late DashboardProvider provider;

    setUp(() {
      mockRepo = MockDashboardRepository();
      provider = DashboardProvider(repository: mockRepo);
    });

    test('Initial loading populates 8 dashboard KPI overview metrics', () async {
      await provider.loadDashboard();

      final o = provider.overview;
      expect(o.todaySales, 2450.0);
      expect(o.todayBillsCount, 3);
      expect(o.monthSales, 48500.0);
      expect(o.monthBillsCount, 42);
      expect(o.yearSales, 280000.0);
      expect(o.yearBillsCount, 260);
      expect(o.totalSales, 540000.0);
      expect(o.totalBillsCount, 490);
      expect(o.totalCustomersCount, 120);
      expect(o.totalProductsCount, 45);
      expect(o.lowStockCount, 4);
      expect(o.totalStockUnits, 380);
    });

    test('Daily sales chart calculations', () async {
      await provider.loadDashboard();

      expect(provider.chartPoints.length, 4);
      expect(provider.totalChartSales, 6900.0); // 1500 + 2300 + 0 + 3100
      expect(provider.totalChartBills, 9); // 2 + 3 + 0 + 4
      expect(provider.maxSalesAmount, 3100.0);
      expect(provider.maxBillsCount, 4);
    });

    test('Switching chart grouping to Monthly and Yearly', () async {
      await provider.loadDashboard();

      // Monthly
      await provider.setGrouping(SalesChartGrouping.monthly);
      expect(provider.selectedGrouping, SalesChartGrouping.monthly);
      expect(provider.chartPoints.length, 2);
      expect(provider.totalChartSales, 80000.0); // 42k + 38k

      // Yearly
      await provider.setGrouping(SalesChartGrouping.yearly);
      expect(provider.selectedGrouping, SalesChartGrouping.yearly);
      expect(provider.chartPoints.length, 2);
      expect(provider.totalChartSales, 600000.0); // 320k + 280k
    });

    test('Custom date range filtering updates chart data', () async {
      await provider.loadDashboard();

      final start = DateTime(2026, 10, 1);
      final end = DateTime(2026, 10, 15);
      await provider.setDateRange(start, end);

      expect(provider.startDate, start);
      expect(provider.endDate, end);
      expect(provider.selectedGrouping, SalesChartGrouping.daily);
      expect(provider.chartPoints.isNotEmpty, true);
    });

    test('Top selling products and VIP customers leaderboard', () async {
      await provider.loadDashboard();

      expect(provider.topSellingProducts.length, 2);
      expect(provider.topSellingProducts.first.productName, 'Cotton Graphic T-Shirt');
      expect(provider.topSellingProducts.first.totalQuantitySold, 28);

      expect(provider.topCustomers.length, 2);
      expect(provider.topCustomers.first.name, 'Priya Sharma');
      expect(provider.topCustomers.first.totalSpent, 12450.0);
    });
  });
}
