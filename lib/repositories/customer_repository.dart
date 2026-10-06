import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/customer_model.dart';
import '../models/customer_purchase_bill_model.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers({String? searchQuery, String? sortBy});

  Future<Customer> getCustomerById(String id);

  Future<Customer?> getCustomerByMobile(String mobile);

  Future<Customer> addCustomer(Customer customer);

  Future<Customer> updateCustomer(Customer customer);

  Future<List<CustomerPurchaseBill>> getCustomerBills(String customerId);

  Future<Map<String, dynamic>> getCustomerStats();
}

class SupabaseCustomerRepository implements CustomerRepository {
  final SupabaseClient _supabase;

  SupabaseCustomerRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<List<Customer>> getCustomers({String? searchQuery, String? sortBy}) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableCustomers)
          .select('*, bills(id)');

      final data = await query.order('created_at', ascending: false);

      List<Customer> list = (data as List)
          .map((row) => Customer.fromJson(row as Map<String, dynamic>))
          .toList();

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        list = list.where((c) {
          final matchesName = c.name.toLowerCase().contains(q);
          final matchesMobile = c.mobile.contains(q);
          final matchesAddress = c.address?.toLowerCase().contains(q) ?? false;
          return matchesName || matchesMobile || matchesAddress;
        }).toList();
      }

      // Sorting
      if (sortBy == 'nameAsc') {
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      } else if (sortBy == 'purchasesHighLow') {
        list.sort((a, b) => b.totalPurchase.compareTo(a.totalPurchase));
      } else if (sortBy == 'billsHighLow') {
        list.sort((a, b) => b.billsCount.compareTo(a.billsCount));
      }

      return list;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load customers: $e');
    }
  }

  @override
  Future<Customer> getCustomerById(String id) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableCustomers)
          .select('*, bills(id)')
          .eq('id', id)
          .single();

      return Customer.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch customer: $e');
    }
  }

  @override
  Future<Customer?> getCustomerByMobile(String mobile) async {
    try {
      final clean = mobile.trim();
      if (clean.isEmpty) return null;

      final data = await _supabase
          .from(SupabaseConstants.tableCustomers)
          .select('*, bills(id)')
          .eq('mobile', clean)
          .maybeSingle();

      if (data == null) return null;
      return Customer.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Customer> addCustomer(Customer customer) async {
    try {
      // 1. Check if mobile already exists to prevent duplication
      final existing = await getCustomerByMobile(customer.mobile);
      if (existing != null) {
        throw const AppException('A customer with this mobile number already exists.');
      }

      final data = await _supabase
          .from(SupabaseConstants.tableCustomers)
          .insert(customer.toJson(includeId: false))
          .select()
          .single();

      return Customer.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate key') || e.code == '23505') {
        throw const AppException('A customer with this mobile number already exists.');
      }
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to add customer: $e');
    }
  }

  @override
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      if (customer.id == null) {
        throw const AppException('Customer ID is required for update.');
      }

      final data = await _supabase
          .from(SupabaseConstants.tableCustomers)
          .update(customer.toJson(includeId: false))
          .eq('id', customer.id!)
          .select('*, bills(id)')
          .single();

      return Customer.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate key') || e.code == '23505') {
        throw const AppException('Another customer with this mobile number already exists.');
      }
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to update customer: $e');
    }
  }

  @override
  Future<List<CustomerPurchaseBill>> getCustomerBills(String customerId) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableBills)
          .select('*, bill_items(*)')
          .eq('customer_id', customerId)
          .order('bill_date', ascending: false);

      return (data as List)
          .map((row) => CustomerPurchaseBill.fromJson(row as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load customer bill history: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final list = await getCustomers();
      final totalCustomers = list.length;
      final totalSpent = list.fold(0.0, (sum, c) => sum + c.totalPurchase);
      final avgSpent = totalCustomers > 0 ? (totalSpent / totalCustomers) : 0.0;
      final totalBills = list.fold(0, (sum, c) => sum + c.billsCount);

      return {
        'totalCustomers': totalCustomers,
        'totalSpent': totalSpent,
        'avgSpent': avgSpent,
        'totalBills': totalBills,
      };
    } catch (_) {
      return {
        'totalCustomers': 0,
        'totalSpent': 0.0,
        'avgSpent': 0.0,
        'totalBills': 0,
      };
    }
  }
}
