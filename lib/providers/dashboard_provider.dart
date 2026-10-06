import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../repositories/dashboard_repository.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardRepository _repository;

  DashboardProvider({required DashboardRepository repository}) : _repository = repository;

  // State
  DashboardOverview _overview = const DashboardOverview();
  List<SalesChartPoint> _chartPoints = [];
  List<TopSellingProduct> _topSellingProducts = [];
  List<TopCustomer> _topCustomers = [];

  SalesChartGrouping _selectedGrouping = SalesChartGrouping.daily;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();

  bool _isLoading = false;
  bool _isChartLoading = false;
  String? _errorMessage;

  // Getters
  DashboardOverview get overview => _overview;
  List<SalesChartPoint> get chartPoints => _chartPoints;
  List<TopSellingProduct> get topSellingProducts => _topSellingProducts;
  List<TopCustomer> get topCustomers => _topCustomers;
  SalesChartGrouping get selectedGrouping => _selectedGrouping;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  bool get isLoading => _isLoading;
  bool get isChartLoading => _isChartLoading;
  String? get errorMessage => _errorMessage;

  double get totalChartSales =>
      _chartPoints.fold(0.0, (sum, p) => sum + p.salesAmount);

  int get totalChartBills =>
      _chartPoints.fold(0, (sum, p) => sum + p.billsCount);

  double get maxSalesAmount {
    if (_chartPoints.isEmpty) return 1000.0;
    final maxVal = _chartPoints.map((p) => p.salesAmount).reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal : 1000.0;
  }

  int get maxBillsCount {
    if (_chartPoints.isEmpty) return 10;
    final maxVal = _chartPoints.map((p) => p.billsCount).reduce((a, b) => a > b ? a : b);
    return maxVal > 0 ? maxVal : 10;
  }

  /// Initial / full load of dashboard KPIs, chart points, top products, top customers
  Future<void> loadDashboard({bool refresh = false}) async {
    if (_chartPoints.isNotEmpty && !refresh && !_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getDashboardOverview(),
        _repository.getSalesChartData(
          startDate: _startDate,
          endDate: _endDate,
          grouping: _selectedGrouping,
        ),
        _repository.getTopSellingProducts(
          limit: 5,
          startDate: _startDate,
          endDate: _endDate,
        ),
        _repository.getTopCustomers(limit: 5),
      ]);

      _overview = results[0] as DashboardOverview;
      _chartPoints = results[1] as List<SalesChartPoint>;
      _topSellingProducts = results[2] as List<TopSellingProduct>;
      _topCustomers = results[3] as List<TopCustomer>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('AppException: ', '').replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes chart grouping: Daily, Monthly, Yearly
  Future<void> setGrouping(SalesChartGrouping grouping) async {
    _selectedGrouping = grouping;
    final now = DateTime.now();

    if (grouping == SalesChartGrouping.daily) {
      _startDate = now.subtract(const Duration(days: 6));
      _endDate = now;
    } else if (grouping == SalesChartGrouping.monthly) {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    } else if (grouping == SalesChartGrouping.yearly) {
      _startDate = DateTime(now.year - 4, 1, 1);
      _endDate = DateTime(now.year, 12, 31);
    }

    await reloadChart();
  }

  /// Custom Date Range selection
  Future<void> setDateRange(DateTime start, DateTime end) async {
    _startDate = start;
    _endDate = end;

    // Adjust grouping automatically if custom range is large
    final differenceDays = end.difference(start).inDays;
    if (differenceDays > 90 && _selectedGrouping == SalesChartGrouping.daily) {
      _selectedGrouping = SalesChartGrouping.monthly;
    } else if (differenceDays <= 31 && _selectedGrouping != SalesChartGrouping.daily) {
      _selectedGrouping = SalesChartGrouping.daily;
    }

    await reloadChart();
  }

  /// Reloads only chart data & top products for date range changes
  Future<void> reloadChart() async {
    _isChartLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getSalesChartData(
          startDate: _startDate,
          endDate: _endDate,
          grouping: _selectedGrouping,
        ),
        _repository.getTopSellingProducts(
          limit: 5,
          startDate: _startDate,
          endDate: _endDate,
        ),
      ]);

      _chartPoints = results[0] as List<SalesChartPoint>;
      _topSellingProducts = results[1] as List<TopSellingProduct>;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isChartLoading = false;
      notifyListeners();
    }
  }
}
