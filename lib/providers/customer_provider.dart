import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/customer_model.dart';
import '../models/customer_purchase_bill_model.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository;

  List<Customer> _customers = [];
  Customer? _selectedCustomer;
  List<CustomerPurchaseBill> _selectedCustomerBills = [];
  Map<String, dynamic> _customerStats = {
    'totalCustomers': 0,
    'totalSpent': 0.0,
    'avgSpent': 0.0,
    'totalBills': 0,
  };

  String _searchQuery = '';
  String _sortBy = 'newest';
  bool _isLoading = false;
  String? _errorMessage;

  CustomerProvider({required CustomerRepository repository})
      : _repository = repository;

  // Getters
  List<Customer> get customers => _customers;
  Customer? get selectedCustomer => _selectedCustomer;
  List<CustomerPurchaseBill> get selectedCustomerBills => _selectedCustomerBills;
  Map<String, dynamic> get customerStats => _customerStats;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalCustomersCount => (_customerStats['totalCustomers'] as num?)?.toInt() ?? _customers.length;
  double get totalLifetimeSpend => (_customerStats['totalSpent'] as num?)?.toDouble() ?? 0.0;
  double get averageCustomerSpend => (_customerStats['avgSpent'] as num?)?.toDouble() ?? 0.0;

  /// Loads all customers and aggregate stats
  Future<void> loadCustomers({bool refresh = false}) async {
    if (_customers.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCustomers(searchQuery: _searchQuery, sortBy: _sortBy),
        _repository.getCustomerStats(),
      ]);

      _customers = results[0] as List<Customer>;
      _customerStats = results[1] as Map<String, dynamic>;
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load customers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _fetchFiltered();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    _fetchFiltered();
  }

  Future<void> _fetchFiltered() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _customers = await _repository.getCustomers(
        searchQuery: _searchQuery,
        sortBy: _sortBy,
      );
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to filter customers.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads full customer profile and historical purchase invoices
  Future<void> loadCustomerDetails(String customerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCustomerById(customerId),
        _repository.getCustomerBills(customerId),
      ]);

      _selectedCustomer = results[0] as Customer;
      _selectedCustomerBills = results[1] as List<CustomerPurchaseBill>;
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load customer details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fast lookup by phone for billing / checkout
  Future<Customer?> searchByMobile(String mobile) async {
    try {
      return await _repository.getCustomerByMobile(mobile);
    } catch (_) {
      return null;
    }
  }

  /// Adds a new customer
  Future<Customer?> addCustomer(Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _repository.addCustomer(customer);
      _customers.insert(0, created);
      _isLoading = false;
      notifyListeners();
      return created;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Failed to register customer.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Updates an existing customer profile
  Future<bool> updateCustomer(Customer customer) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateCustomer(customer);
      final index = _customers.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _customers[index] = updated;
      }
      if (_selectedCustomer?.id == updated.id) {
        _selectedCustomer = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update customer.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates in-memory customer spend & last_discount after a checkout
  void recordCustomerSaleLocally({
    required String customerId,
    required double saleAmount,
    required double newLastDiscount,
  }) {
    final index = _customers.indexWhere((c) => c.id == customerId);
    if (index != -1) {
      final old = _customers[index];
      final updated = old.copyWith(
        totalPurchase: old.totalPurchase + saleAmount,
        lastDiscount: newLastDiscount,
        billsCount: old.billsCount + 1,
      );
      _customers[index] = updated;
      if (_selectedCustomer?.id == customerId) {
        _selectedCustomer = updated;
      }
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
