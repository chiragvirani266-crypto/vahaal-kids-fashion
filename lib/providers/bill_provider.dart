import 'package:flutter/material.dart';
import '../models/bill_filter_model.dart';
import '../models/bill_item_model.dart';
import '../models/bill_model.dart';
import '../models/customer_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';
import '../repositories/bill_repository.dart';

enum DiscountType {
  fixed, // Fixed amount in Rupees (₹)
  percentage, // Percentage (%)
}

class BillProvider extends ChangeNotifier {
  final BillRepository _repository;

  BillProvider({required BillRepository repository}) : _repository = repository {
    loadPreviewBillNumber();
  }

  // Billing State Variables
  List<BillItem> _cartItems = [];
  Customer? _selectedCustomer;
  DiscountType _discountType = DiscountType.fixed;
  double _discountValue = 0.0;
  String _paymentMethod = 'cash'; // 'cash' | 'upi' | 'card' | 'other'
  String _notes = '';
  String _previewBillNumber = 'VKF-BILL';
  bool _isLoading = false;
  String? _errorMessage;
  Bill? _lastCompletedBill;

  // Bill History & Search State
  List<Bill> _billsHistory = [];
  bool _isHistoryLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const int _pageSize = 20;
  int _totalCount = 0;

  // Search & Filter state
  String _searchQuery = '';
  BillDateFilterOption _activeDateFilter = BillDateFilterOption.all;
  DateTimeRange? _customDateRange;
  String _paymentFilter = 'All';

  // Getters - Billing
  List<BillItem> get cartItems => List.unmodifiable(_cartItems);
  Customer? get selectedCustomer => _selectedCustomer;
  DiscountType get discountType => _discountType;
  double get discountValue => _discountValue;
  String get paymentMethod => _paymentMethod;
  String get notes => _notes;
  String get previewBillNumber => _previewBillNumber;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Bill? get lastCompletedBill => _lastCompletedBill;

  // Getters - Bill Search & History
  List<Bill> get billsHistory => List.unmodifiable(_billsHistory);
  bool get isHistoryLoading => _isHistoryLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get page => _page;
  int get totalCount => _totalCount;
  String get searchQuery => _searchQuery;
  BillDateFilterOption get activeDateFilter => _activeDateFilter;
  DateTimeRange? get customDateRange => _customDateRange;
  String get paymentFilter => _paymentFilter;

  int get totalUniqueItems => _cartItems.length;
  int get totalQuantity => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal =>
      _cartItems.fold(0.0, (sum, item) => sum + (item.unitPrice * item.quantity));

  /// Calculates effective discount in Rupees (₹), strictly clamped to [0.0, subtotal]
  double get effectiveDiscount {
    if (subtotal <= 0 || _discountValue <= 0) return 0.0;

    double calculated;
    if (_discountType == DiscountType.percentage) {
      calculated = (subtotal * _discountValue) / 100.0;
    } else {
      calculated = _discountValue;
    }

    if (calculated < 0) return 0.0;
    if (calculated > subtotal) return subtotal;
    return calculated;
  }

  /// Flag indicating if the entered discount exceeds subtotal or 100%
  bool get isDiscountExceedingSubtotal {
    if (_discountType == DiscountType.percentage) {
      return _discountValue > 100.0;
    }
    return _discountValue > subtotal && subtotal > 0;
  }

  double get grandTotal {
    final total = subtotal - effectiveDiscount;
    return total < 0 ? 0.0 : total;
  }

  bool get isCartEmpty => _cartItems.isEmpty;
  bool get canCheckout => _cartItems.isNotEmpty && !_isLoading;

  // Initial / Preview Bill Number Loader
  Future<void> loadPreviewBillNumber() async {
    try {
      _previewBillNumber = await _repository.generateNextBillNumber();
      notifyListeners();
    } catch (_) {
      _previewBillNumber = 'VKF-BILL';
    }
  }

  // Cart Operations
  void addItem({
    required Product product,
    required ProductVariant variant,
    int quantity = 1,
  }) {
    _errorMessage = null;

    final variantId = variant.id ?? '${product.id}_${variant.size}_${variant.color}';
    final existingIndex = _cartItems.indexWhere((item) => item.variantId == variantId);

    final availableStock = variant.stockQuantity;
    final unitPrice = variant.sellingPrice ?? product.sellingPrice;

    if (existingIndex >= 0) {
      final currentItem = _cartItems[existingIndex];
      final targetQuantity = currentItem.quantity + quantity;

      if (targetQuantity > availableStock) {
        _errorMessage =
            'Cannot add more units. Only $availableStock in stock for ${product.productName} (${variant.displayName}).';
        notifyListeners();
        return;
      }

      final updatedTotal = (targetQuantity * currentItem.unitPrice) - currentItem.discount;
      _cartItems[existingIndex] = currentItem.copyWith(
        quantity: targetQuantity,
        total: updatedTotal > 0 ? updatedTotal : 0.0,
        availableStock: availableStock,
      );
    } else {
      if (quantity > availableStock) {
        _errorMessage =
            'Insufficient stock! Only $availableStock available for ${product.productName} (${variant.displayName}).';
        notifyListeners();
        return;
      }

      final itemTotal = unitPrice * quantity;
      final newItem = BillItem(
        productId: product.id,
        variantId: variantId,
        productNameSnapshot: product.productName,
        skuSnapshot: variant.sku.isNotEmpty ? variant.sku : product.sku,
        sizeSnapshot: variant.size,
        colorSnapshot: variant.color,
        quantity: quantity,
        unitPrice: unitPrice,
        discount: 0.0,
        total: itemTotal,
        availableStock: availableStock,
      );

      _cartItems.add(newItem);
    }

    notifyListeners();
  }

  void updateQuantity(String variantId, int newQuantity) {
    _errorMessage = null;

    final index = _cartItems.indexWhere((item) => item.variantId == variantId);
    if (index < 0) return;

    if (newQuantity <= 0) {
      removeItem(variantId);
      return;
    }

    final item = _cartItems[index];
    if (newQuantity > item.availableStock) {
      _errorMessage =
          'Cannot exceed available stock of ${item.availableStock} for "${item.productNameSnapshot}".';
      notifyListeners();
      return;
    }

    final updatedTotal = (newQuantity * item.unitPrice) - item.discount;
    _cartItems[index] = item.copyWith(
      quantity: newQuantity,
      total: updatedTotal > 0 ? updatedTotal : 0.0,
    );

    notifyListeners();
  }

  void incrementQuantity(String variantId) {
    final item = _cartItems.firstWhere((i) => i.variantId == variantId, orElse: () => _cartItems.first);
    updateQuantity(variantId, item.quantity + 1);
  }

  void decrementQuantity(String variantId) {
    final item = _cartItems.firstWhere((i) => i.variantId == variantId, orElse: () => _cartItems.first);
    updateQuantity(variantId, item.quantity - 1);
  }

  void removeItem(String variantId) {
    _cartItems.removeWhere((item) => item.variantId == variantId);
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _discountType = DiscountType.fixed;
    _discountValue = 0.0;
    _notes = '';
    _selectedCustomer = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Customer Management in Billing
  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    if (customer != null && customer.lastDiscount > 0) {
      _discountType = DiscountType.fixed;
      _discountValue = customer.lastDiscount;
    }
    notifyListeners();
  }

  void removeCustomer() {
    _selectedCustomer = null;
    notifyListeners();
  }

  // Discount Management
  void setDiscountType(DiscountType type) {
    _discountType = type;
    notifyListeners();
  }

  void setDiscountValue(double value) {
    _discountValue = value < 0 ? 0.0 : value;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void setNotes(String notes) {
    _notes = notes;
    notifyListeners();
  }

  // Atomic Checkout Execution
  Future<Bill?> checkout({required String? cashierId}) async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Cannot checkout an empty cart. Please add items.';
      notifyListeners();
      return null;
    }

    // Double check stock availability before initiating RPC
    for (final item in _cartItems) {
      if (item.quantity > item.availableStock) {
        _errorMessage =
            'Insufficient stock for "${item.productNameSnapshot}" (${item.variantDescription}). Requested ${item.quantity}, but only ${item.availableStock} in stock.';
        notifyListeners();
        return null;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final finalEffectiveDiscount = effectiveDiscount;

      final billToCreate = Bill(
        billNumber: _previewBillNumber,
        customerId: _selectedCustomer?.id,
        customerNameSnapshot: _selectedCustomer?.name ?? 'Walk-in Customer',
        customerMobileSnapshot: _selectedCustomer?.mobile ?? '',
        billDate: DateTime.now(),
        subtotal: subtotal,
        discount: finalEffectiveDiscount, // Preserved permanently on bill
        grandTotal: grandTotal,
        paymentMethod: _paymentMethod,
        notes: _notes.trim().isNotEmpty ? _notes.trim() : null,
        cashierId: cashierId,
        items: _cartItems,
      );

      final createdBill = await _repository.createBillAtomic(
        bill: billToCreate,
        items: _cartItems,
      );

      _lastCompletedBill = createdBill;

      // Reset cart and prepare for next sale
      _cartItems = [];
      _discountType = DiscountType.fixed;
      _discountValue = 0.0;
      _notes = '';
      _selectedCustomer = null;
      _isLoading = false;

      // Refresh next preview number
      await loadPreviewBillNumber();

      notifyListeners();
      return createdBill;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '').replaceAll('AppException: ', '');
      notifyListeners();
      return null;
    }
  }

  // =========================================================
  // SERVER-SIDE BILL SEARCH & PAGINATION
  // =========================================================

  /// Updates the active date filter and triggers server-side query
  void setDateFilter(BillDateFilterOption option, {DateTimeRange? customRange}) {
    _activeDateFilter = option;
    _customDateRange = customRange;
    fetchBills(refresh: true);
  }

  /// Updates the search query (bill number / customer name / customer mobile)
  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    fetchBills(refresh: true);
  }

  /// Updates the payment method filter
  void setPaymentFilter(String paymentMethod) {
    if (_paymentFilter == paymentMethod) return;
    _paymentFilter = paymentMethod;
    fetchBills(refresh: true);
  }

  /// Clears all active filters and resets to default view
  void resetFilters() {
    _searchQuery = '';
    _activeDateFilter = BillDateFilterOption.all;
    _customDateRange = null;
    _paymentFilter = 'All';
    fetchBills(refresh: true);
  }

  /// Fetches paginated bills directly from Supabase server
  Future<void> fetchBills({bool refresh = true}) async {
    if (refresh) {
      _page = 0;
      _hasMore = true;
      _isHistoryLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final range = BillFilterHelper.resolveDateRange(
        _activeDateFilter,
        customRange: _customDateRange,
      );

      final results = await _repository.getBills(
        startDate: range?.start,
        endDate: range?.end,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        paymentMethod: _paymentFilter != 'All' ? _paymentFilter : null,
        page: _page,
        pageSize: _pageSize,
      );

      if (refresh) {
        _billsHistory = results;
      } else {
        _billsHistory = [..._billsHistory, ...results];
      }

      _hasMore = results.length >= _pageSize;

      // Count estimation
      if (refresh) {
        _totalCount = await _repository.getBillsCount(
          startDate: range?.start,
          endDate: range?.end,
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          paymentMethod: _paymentFilter != 'All' ? _paymentFilter : null,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isHistoryLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Loads the next page of bills from Supabase
  Future<void> loadMoreBills() async {
    if (!_hasMore || _isLoadingMore || _isHistoryLoading) return;

    _isLoadingMore = true;
    _page++;
    notifyListeners();

    try {
      final range = BillFilterHelper.resolveDateRange(
        _activeDateFilter,
        customRange: _customDateRange,
      );

      final newBills = await _repository.getBills(
        startDate: range?.start,
        endDate: range?.end,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        paymentMethod: _paymentFilter != 'All' ? _paymentFilter : null,
        page: _page,
        pageSize: _pageSize,
      );

      _billsHistory = [..._billsHistory, ...newBills];
      _hasMore = newBills.length >= _pageSize;
    } catch (e) {
      _errorMessage = e.toString();
      _page--; // Revert page on failure
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetch full bill details with joined relations
  Future<Bill?> fetchBillDetails(String billId) async {
    try {
      return await _repository.getBillById(billId);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Backward-compatible loader for existing callers
  Future<void> loadBillsHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? search,
    String? paymentMethod,
  }) async {
    _isHistoryLoading = true;
    notifyListeners();

    try {
      _billsHistory = await _repository.getBills(
        startDate: startDate,
        endDate: endDate,
        search: search,
        paymentMethod: paymentMethod,
        page: 0,
        pageSize: 50,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
}
