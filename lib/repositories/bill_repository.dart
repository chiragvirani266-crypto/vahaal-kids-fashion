import 'dart:io';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';

abstract class BillRepository {
  Future<Bill> createBillAtomic({
    required Bill bill,
    required List<BillItem> items,
  });

  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int limit = 50,
  });

  Future<Bill> getBillById(String id);

  Future<String> generateNextBillNumber();
}

class SupabaseBillRepository implements BillRepository {
  final SupabaseClient _supabase;

  SupabaseBillRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<Bill> createBillAtomic({
    required Bill bill,
    required List<BillItem> items,
  }) async {
    try {
      if (items.isEmpty) {
        throw const AppException('Cannot create an empty bill. Add at least one item.');
      }

      // Check for zero or negative quantities
      for (final item in items) {
        if (item.quantity <= 0) {
          throw AppException(
            'Invalid quantity (${item.quantity}) for "${item.productNameSnapshot}". Quantity must be at least 1.',
          );
        }
      }

      final billRpcJson = bill.toRpcJson();
      final itemsRpcJson = items.map((i) => i.toRpcJson()).toList();

      // Invoke PostgreSQL Atomic Transaction RPC Function
      final response = await _supabase.rpc(
        'create_pos_bill',
        params: {
          'p_bill': billRpcJson,
          'p_items': itemsRpcJson,
        },
      );

      if (response == null) {
        throw const AppException('Unexpected empty response from billing server.');
      }

      final Map<String, dynamic> result =
          response is Map<String, dynamic> ? response : Map<String, dynamic>.from(response as Map);

      final String? billId = result['bill_id']?.toString();
      final String? returnedBillNumber = result['bill_number']?.toString();

      if (billId == null || billId.isEmpty) {
        throw const AppException('Failed to generate bill ID in transaction.');
      }

      // Fetch the full recorded bill with joined relations
      try {
        final createdBill = await getBillById(billId);
        return createdBill;
      } catch (_) {
        // Fallback with created details if instant query is delayed
        return bill.copyWith(
          id: billId,
          billNumber: returnedBillNumber ?? bill.billNumber,
          items: items,
          createdAt: DateTime.now(),
        );
      }
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      final msg = e.message;
      if (msg.contains('Insufficient stock')) {
        throw AppException('Stock Error: $msg');
      }
      throw AppException(msg);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to complete billing transaction: $e');
    }
  }

  @override
  Future<List<Bill>> getBills({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableBills)
          .select('*, bill_items(*), profiles(full_name)');

      if (startDate != null) {
        query = query.gte('bill_date', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('bill_date', endDate.toIso8601String());
      }

      if (paymentMethod != null && paymentMethod.isNotEmpty && paymentMethod != 'All') {
        query = query.eq('payment_method', paymentMethod.toLowerCase());
      }

      final data = await query.order('bill_date', ascending: false).limit(limit);

      List<Bill> list = (data as List)
          .map((row) => Bill.fromJson(row as Map<String, dynamic>))
          .toList();

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((b) {
          final matchesNumber = b.billNumber.toLowerCase().contains(q);
          final matchesCust = b.customerNameSnapshot?.toLowerCase().contains(q) ?? false;
          final matchesMobile = b.customerMobileSnapshot?.contains(q) ?? false;
          return matchesNumber || matchesCust || matchesMobile;
        }).toList();
      }

      return list;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load bills: $e');
    }
  }

  @override
  Future<Bill> getBillById(String id) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableBills)
          .select('*, bill_items(*), profiles(full_name)')
          .eq('id', id)
          .single();

      return Bill.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch bill details: $e');
    }
  }

  @override
  Future<String> generateNextBillNumber() async {
    try {
      // Query the latest bill number to calculate preview
      final latest = await _supabase
          .from(SupabaseConstants.tableBills)
          .select('bill_number')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final year = DateFormat('yyyy').format(DateTime.now());
      if (latest == null || latest['bill_number'] == null) {
        return 'VKF-$year-001001';
      }

      final lastNumStr = latest['bill_number'].toString();
      final parts = lastNumStr.split('-');
      if (parts.length >= 3) {
        final lastSeq = int.tryParse(parts.last) ?? 1000;
        final nextSeq = (lastSeq + 1).toString().padLeft(6, '0');
        return 'VKF-$year-$nextSeq';
      }

      return 'VKF-$year-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    } catch (_) {
      final year = DateFormat('yyyy').format(DateTime.now());
      return 'VKF-$year-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }
}
