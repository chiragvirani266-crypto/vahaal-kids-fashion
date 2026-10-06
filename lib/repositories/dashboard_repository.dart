import 'dart:io';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/analytics_model.dart';

abstract class DashboardRepository {
  Future<DashboardOverview> getDashboardOverview();

  Future<List<SalesChartPoint>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
    required SalesChartGrouping grouping,
  });

  Future<List<TopSellingProduct>> getTopSellingProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<List<TopCustomer>> getTopCustomers({int limit = 5});
}

class SupabaseDashboardRepository implements DashboardRepository {
  final SupabaseClient _supabase;

  SupabaseDashboardRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<DashboardOverview> getDashboardOverview() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final monthStart = DateTime(now.year, now.month, 1, 0, 0, 0);
      final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      final yearStart = DateTime(now.year, 1, 1, 0, 0, 0);
      final yearEnd = DateTime(now.year, 12, 31, 23, 59, 59);

      // Perform parallel optimized queries
      final results = await Future.wait([
        // 0: Today's Bills
        _supabase
            .from(SupabaseConstants.tableBills)
            .select('grand_total')
            .gte('bill_date', todayStart.toIso8601String())
            .lte('bill_date', todayEnd.toIso8601String()),

        // 1: This Month's Bills
        _supabase
            .from(SupabaseConstants.tableBills)
            .select('grand_total')
            .gte('bill_date', monthStart.toIso8601String())
            .lte('bill_date', monthEnd.toIso8601String()),

        // 2: This Year's Bills
        _supabase
            .from(SupabaseConstants.tableBills)
            .select('grand_total')
            .gte('bill_date', yearStart.toIso8601String())
            .lte('bill_date', yearEnd.toIso8601String()),

        // 3: Lifetime Total Bills
        _supabase
            .from(SupabaseConstants.tableBills)
            .select('grand_total'),

        // 4: Total Customers Count
        _supabase
            .from(SupabaseConstants.tableCustomers)
            .select('id'),

        // 5: Total Products Count
        _supabase
            .from(SupabaseConstants.tableProducts)
            .select('id')
            .eq('is_active', true),

        // 6: Variants for Stock stats
        _supabase
            .from(SupabaseConstants.tableProductVariants)
            .select('stock_quantity, low_stock_alert'),
      ]);

      // Calculate Today Sales & Bills
      final todayBills = results[0] as List;
      final todayBillsCount = todayBills.length;
      final todaySales = todayBills.fold(
          0.0, (sum, b) => sum + (double.tryParse(b['grand_total']?.toString() ?? '0') ?? 0.0));

      // Calculate Month Sales & Bills
      final monthBills = results[1] as List;
      final monthBillsCount = monthBills.length;
      final monthSales = monthBills.fold(
          0.0, (sum, b) => sum + (double.tryParse(b['grand_total']?.toString() ?? '0') ?? 0.0));

      // Calculate Year Sales & Bills
      final yearBills = results[2] as List;
      final yearBillsCount = yearBills.length;
      final yearSales = yearBills.fold(
          0.0, (sum, b) => sum + (double.tryParse(b['grand_total']?.toString() ?? '0') ?? 0.0));

      // Calculate Lifetime Total Sales & Bills
      final totalBillsList = results[3] as List;
      final totalBillsCount = totalBillsList.length;
      final totalSales = totalBillsList.fold(
          0.0, (sum, b) => sum + (double.tryParse(b['grand_total']?.toString() ?? '0') ?? 0.0));

      // Customer & Product counts
      final totalCustomersCount = (results[4] as List).length;
      final totalProductsCount = (results[5] as List).length;

      // Variant inventory stats
      final variantsList = results[6] as List;
      int lowStockCount = 0;
      int totalStockUnits = 0;

      for (final v in variantsList) {
        final stock = (v['stock_quantity'] as num?)?.toInt() ?? 0;
        final alert = (v['low_stock_alert'] as num?)?.toInt() ?? 3;
        totalStockUnits += stock;
        if (stock <= alert) {
          lowStockCount++;
        }
      }

      return DashboardOverview(
        todaySales: todaySales,
        todayBillsCount: todayBillsCount,
        monthSales: monthSales,
        monthBillsCount: monthBillsCount,
        yearSales: yearSales,
        yearBillsCount: yearBillsCount,
        totalSales: totalSales,
        totalBillsCount: totalBillsCount,
        totalCustomersCount: totalCustomersCount,
        totalProductsCount: totalProductsCount,
        lowStockCount: lowStockCount,
        totalStockUnits: totalStockUnits,
      );
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load dashboard overview stats: $e');
    }
  }

  @override
  Future<List<SalesChartPoint>> getSalesChartData({
    required DateTime startDate,
    required DateTime endDate,
    required SalesChartGrouping grouping,
  }) async {
    try {
      final startIso = startDate.toIso8601String();
      final endIso = endDate.toIso8601String();

      final data = await _supabase
          .from(SupabaseConstants.tableBills)
          .select('bill_date, grand_total')
          .gte('bill_date', startIso)
          .lte('bill_date', endIso)
          .order('bill_date', ascending: true);

      final bills = (data as List);

      final Map<String, _BucketAccumulator> buckets = {};

      if (grouping == SalesChartGrouping.daily) {
        // Pre-fill every day between start and end date so the graph is smooth with zero-sale days
        var current = DateTime(startDate.year, startDate.month, startDate.day);
        final endDay = DateTime(endDate.year, endDate.month, endDate.day);

        while (!current.isAfter(endDay)) {
          final key = DateFormat('yyyy-MM-dd').format(current);
          final label = DateFormat('dd MMM').format(current);
          buckets[key] = _BucketAccumulator(date: current, label: label);
          current = current.add(const Duration(days: 1));
        }

        for (final bill in bills) {
          final dateStr = bill['bill_date']?.toString();
          if (dateStr == null) continue;
          final d = DateTime.tryParse(dateStr);
          if (d == null) continue;

          final key = DateFormat('yyyy-MM-dd').format(d);
          final amount = double.tryParse(bill['grand_total']?.toString() ?? '0') ?? 0.0;

          if (buckets.containsKey(key)) {
            buckets[key]!.salesAmount += amount;
            buckets[key]!.billsCount += 1;
          } else {
            final label = DateFormat('dd MMM').format(d);
            buckets[key] = _BucketAccumulator(
              date: d,
              label: label,
              salesAmount: amount,
              billsCount: 1,
            );
          }
        }
      } else if (grouping == SalesChartGrouping.monthly) {
        // Pre-fill months
        var current = DateTime(startDate.year, startDate.month, 1);
        final endMonth = DateTime(endDate.year, endDate.month, 1);

        while (!current.isAfter(endMonth)) {
          final key = DateFormat('yyyy-MM').format(current);
          final label = DateFormat('MMM yy').format(current);
          buckets[key] = _BucketAccumulator(date: current, label: label);
          current = DateTime(current.year, current.month + 1, 1);
        }

        for (final bill in bills) {
          final dateStr = bill['bill_date']?.toString();
          if (dateStr == null) continue;
          final d = DateTime.tryParse(dateStr);
          if (d == null) continue;

          final key = DateFormat('yyyy-MM').format(d);
          final amount = double.tryParse(bill['grand_total']?.toString() ?? '0') ?? 0.0;

          if (buckets.containsKey(key)) {
            buckets[key]!.salesAmount += amount;
            buckets[key]!.billsCount += 1;
          }
        }
      } else if (grouping == SalesChartGrouping.yearly) {
        // Pre-fill years
        for (int y = startDate.year; y <= endDate.year; y++) {
          final current = DateTime(y, 1, 1);
          final key = '$y';
          final label = '$y';
          buckets[key] = _BucketAccumulator(date: current, label: label);
        }

        for (final bill in bills) {
          final dateStr = bill['bill_date']?.toString();
          if (dateStr == null) continue;
          final d = DateTime.tryParse(dateStr);
          if (d == null) continue;

          final key = '${d.year}';
          final amount = double.tryParse(bill['grand_total']?.toString() ?? '0') ?? 0.0;

          if (buckets.containsKey(key)) {
            buckets[key]!.salesAmount += amount;
            buckets[key]!.billsCount += 1;
          }
        }
      }

      final points = buckets.values
          .map((b) => SalesChartPoint(
                date: b.date,
                label: b.label,
                salesAmount: b.salesAmount,
                billsCount: b.billsCount,
              ))
          .toList();

      return points;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load sales chart analytics: $e');
    }
  }

  @override
  Future<List<TopSellingProduct>> getTopSellingProducts({
    int limit = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableBillItems)
          .select('product_id, product_name_snapshot, sku_snapshot, quantity, total');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query;
      final items = (data as List);

      // Aggregate by product_name or product_id
      final Map<String, TopSellingProduct> map = {};

      for (final item in items) {
        final name = item['product_name_snapshot']?.toString() ?? 'Product';
        final sku = item['sku_snapshot']?.toString() ?? '';
        final productId = item['product_id']?.toString() ?? name;
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final total = double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;

        if (map.containsKey(name)) {
          final existing = map[name]!;
          map[name] = TopSellingProduct(
            productId: existing.productId,
            productName: existing.productName,
            sku: existing.sku,
            category: existing.category,
            totalQuantitySold: existing.totalQuantitySold + qty,
            totalRevenue: existing.totalRevenue + total,
          );
        } else {
          map[name] = TopSellingProduct(
            productId: productId,
            productName: name,
            sku: sku,
            category: 'Kids Apparel',
            totalQuantitySold: qty,
            totalRevenue: total,
          );
        }
      }

      final list = map.values.toList();
      list.sort((a, b) => b.totalQuantitySold.compareTo(a.totalQuantitySold));

      return list.take(limit).toList();
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load top selling products: $e');
    }
  }

  @override
  Future<List<TopCustomer>> getTopCustomers({int limit = 5}) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableCustomers)
          .select('*, bills(id)')
          .order('total_purchase', ascending: false)
          .limit(limit);

      final list = (data as List)
          .map((row) => TopCustomer.fromJson(row as Map<String, dynamic>))
          .toList();

      return list;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load top customers: $e');
    }
  }
}

class _BucketAccumulator {
  final DateTime date;
  final String label;
  double salesAmount;
  int billsCount;

  _BucketAccumulator({
    required this.date,
    required this.label,
    this.salesAmount = 0.0,
    this.billsCount = 0,
  });
}
