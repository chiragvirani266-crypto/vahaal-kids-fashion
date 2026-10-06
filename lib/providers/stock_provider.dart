import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/stock_item_model.dart';
import '../models/stock_transaction_model.dart';
import '../repositories/stock_repository.dart';

class StockProvider extends ChangeNotifier {
  final StockRepository _repository;

  List<StockItem> _stockItems = [];
  List<StockItem> _lowStockItems = [];
  List<StockTransaction> _transactions = [];
  Map<String, dynamic> _overviewStats = {
    'totalVariants': 0,
    'totalStockUnits': 0,
    'lowStockCount': 0,
    'outOfStockCount': 0,
    'totalValuation': 0.0,
    'totalRetailValue': 0.0,
  };

  String _selectedCategory = 'All';
  String _selectedSize = 'All';
  String _searchQuery = '';
  String _selectedTxType = 'All';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool _isLoading = false;
  String? _errorMessage;

  StockProvider({required StockRepository repository}) : _repository = repository;

  // Getters
  List<StockItem> get stockItems => _stockItems;
  List<StockItem> get lowStockItems => _lowStockItems;
  List<StockTransaction> get transactions => _transactions;
  Map<String, dynamic> get overviewStats => _overviewStats;

  String get selectedCategory => _selectedCategory;
  String get selectedSize => _selectedSize;
  String get searchQuery => _searchQuery;
  String get selectedTxType => _selectedTxType;
  DateTime? get filterStartDate => _filterStartDate;
  DateTime? get filterEndDate => _filterEndDate;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalStockUnits => (_overviewStats['totalStockUnits'] as num?)?.toInt() ?? 0;
  int get lowStockCount => (_overviewStats['lowStockCount'] as num?)?.toInt() ?? 0;
  int get outOfStockCount => (_overviewStats['outOfStockCount'] as num?)?.toInt() ?? 0;
  double get totalValuation => (_overviewStats['totalValuation'] as num?)?.toDouble() ?? 0.0;

  List<String> get availableCategories {
    final set = <String>{'All'};
    for (final item in _stockItems) {
      if (item.category.isNotEmpty) set.add(item.category);
    }
    return set.toList();
  }

  /// Loads full stock overview data
  Future<void> loadStockDashboard({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getStockOverviewStats(),
        _repository.getStockItems(
          category: _selectedCategory,
          size: _selectedSize,
          search: _searchQuery,
        ),
        _repository.getLowStockItems(),
        _repository.getStockTransactions(),
      ]);

      _overviewStats = results[0] as Map<String, dynamic>;
      _stockItems = results[1] as List<StockItem>;
      _lowStockItems = results[2] as List<StockItem>;
      _transactions = (results[3] as List<StockTransaction>).take(20).toList();
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load stock data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads inventory list with active filters
  Future<void> loadStockItems({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stockItems = await _repository.getStockItems(
        category: _selectedCategory,
        size: _selectedSize,
        search: _searchQuery,
      );
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load stock inventory.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads low stock items only
  Future<void> loadLowStockItems({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _lowStockItems = await _repository.getLowStockItems();
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load low stock items.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads stock transactions history
  Future<void> loadStockHistory({bool refresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _repository.getStockTransactions(
        transactionType: _selectedTxType,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        search: _searchQuery,
      );
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load stock movement history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadStockItems();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    loadStockItems();
  }

  void setSize(String size) {
    if (_selectedSize == size) return;
    _selectedSize = size;
    loadStockItems();
  }

  void setTxType(String txType) {
    if (_selectedTxType == txType) return;
    _selectedTxType = txType;
    loadStockHistory();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _filterStartDate = start;
    _filterEndDate = end;
    loadStockHistory();
  }

  /// Performs Stock In (Purchase Addition)
  Future<bool> stockIn({
    required String variantId,
    required int quantity,
    required String invoiceRef,
    String? note,
  }) async {
    if (quantity <= 0) {
      _errorMessage = 'Stock In quantity must be greater than zero.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.recordStockTransaction(
        variantId: variantId,
        transactionType: 'purchase_in',
        quantity: quantity,
        reference: invoiceRef.isNotEmpty ? invoiceRef : 'MANUAL-STOCK-IN',
        note: note,
      );

      await loadStockDashboard(refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to process Stock In.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Performs Stock Out (Damage / Loss / Removal)
  Future<bool> stockOut({
    required String variantId,
    required int quantity,
    required String reason,
    required String reference,
  }) async {
    if (quantity <= 0) {
      _errorMessage = 'Quantity must be greater than zero.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.recordStockTransaction(
        variantId: variantId,
        transactionType: 'damage',
        quantity: -quantity,
        reference: reference.isNotEmpty ? reference : 'DAMAGE-WRITE-OFF',
        note: reason,
      );

      await loadStockDashboard(refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to process stock deduction.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Performs Customer Stock Return
  Future<bool> stockReturn({
    required String variantId,
    required int quantity,
    required String billRef,
    String? note,
  }) async {
    if (quantity <= 0) {
      _errorMessage = 'Return quantity must be greater than zero.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.recordStockTransaction(
        variantId: variantId,
        transactionType: 'return',
        quantity: quantity,
        reference: billRef.isNotEmpty ? billRef : 'RETURN-RESTOCK',
        note: note,
      );

      await loadStockDashboard(refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to process stock return.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Performs Stock Adjustment to target physical count
  Future<bool> stockAdjustment({
    required String variantId,
    required int targetStock,
    required String reason,
    required String reference,
  }) async {
    if (targetStock < 0) {
      _errorMessage = 'Target stock cannot be negative.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.recordStockAdjustment(
        variantId: variantId,
        targetNewStock: targetStock,
        reason: reason,
        reference: reference.isNotEmpty ? reference : 'AUDIT-ADJUSTMENT',
      );

      await loadStockDashboard(refresh: true);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to adjust stock quantity.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
