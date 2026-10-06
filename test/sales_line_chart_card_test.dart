import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vahaal_kids_fashion/models/analytics_model.dart';
import 'package:vahaal_kids_fashion/providers/dashboard_provider.dart';
import 'package:vahaal_kids_fashion/repositories/dashboard_repository.dart';
import 'package:vahaal_kids_fashion/screens/analytics/widgets/sales_line_chart_card.dart';
import 'package:vahaal_kids_fashion/theme/app_theme.dart';

class MockDashboardRepo implements DashboardRepository {
  @override
  Future<DashboardOverview> getDashboardOverview() async => const DashboardOverview();

  @override
  Future<List<SalesChartPoint>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
    required SalesChartGrouping grouping,
  }) async => [];

  @override
  Future<List<TopSellingProduct>> getTopSellingProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async => [];

  @override
  Future<List<TopCustomer>> getTopCustomers({int limit = 5}) async => [];
}

void main() {
  testWidgets('SalesLineChartCard renders without overflow on narrow mobile screens (360px)', (tester) async {
    final repo = MockDashboardRepo();
    final provider = DashboardProvider(repository: repo);

    // Narrow mobile viewport (360px width)
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<DashboardProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SalesLineChartCard(enableDateRangePicker: true),
              ),
            ),
          ),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isNull);
    expect(find.byType(SalesLineChartCard), findsOneWidget);
    expect(find.text('Sales & Revenue Trend'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);
  });

  testWidgets('SalesLineChartCard renders without overflow on tablet/desktop screens (800px)', (tester) async {
    final repo = MockDashboardRepo();
    final provider = DashboardProvider(repository: repo);

    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<DashboardProvider>.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SalesLineChartCard(enableDateRangePicker: true),
              ),
            ),
          ),
        ),
      ),
    );

    final exception = tester.takeException();
    expect(exception, isNull);
    expect(find.byType(SalesLineChartCard), findsOneWidget);
    expect(find.text('Sales & Revenue Trend'), findsOneWidget);
  });
}
