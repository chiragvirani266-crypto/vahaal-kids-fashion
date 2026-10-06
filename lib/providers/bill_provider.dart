import 'package:flutter/foundation.dart';
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

  // State Variables
  List<BillItem> _cartItems = [];
  Customer? _selectedCustomer;
  DiscountType _discountType = DiscountType.fixed;
  double _discountValue = 0.0;
  String _paymentMethod = 'cash'; // 'cash' | 'upi' | 'card' | 'other'
  String _notes = '';
  String _previewBillNumber = 'VKF-POS';
  bool _isLoading = false;
  String? _errorMessage;
  Bill? _lastCompletedBill;

  // History State
  List<Bill> _billsHistory = [];
  bool _isHistoryLoading = false;

  // Getters
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
  List<Bill> get billsHistory => _billsHistory;
  bool get isHistoryLoading => _isHistoryLoading;

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
      _previewBillNumber = 'VKF-POS';
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
    if (index == -1) return;

    final item = _cartItems[index];

    if (newQuantity <= 0) {
      _cartItems.removeAt(index);
      notifyListeners();
      return;
    }

    if (newQuantity > item.availableStock) {
      _errorMessage =
          'Stock limit reached. Only ${item.availableStock} available for ${item.productNameSnapshot} (${item.variantDescription}).';
      notifyListeners();
      return;
    }

    final newTotal = (newQuantity * item.unitPrice) - item.discount;
    _cartItems[index] = item.copyWith(
      quantity: newQuantity,
      total: newTotal > 0 ? newTotal : 0.0,
    );

    notifyListeners();
  }

  void incrementQuantity(String variantId) {
    final item = _cartItems.firstWhere(
      (item) => item.variantId == variantId,
      orElse: () => const BillItem(
        variantId: '',
        productNameSnapshot: '',
        skuSnapshot: '',
        sizeSnapshot: '',
        colorSnapshot: '',
        quantity: 0,
        unitPrice: 0,
        total: 0,
      ),
    );
    if (item.variantId.isNotEmpty) {
      updateQuantity(variantId, item.quantity + 1);
    }
  }

  void decrementQuantity(String variantId) {
    final item = _cartItems.firstWhere(
      (item) => item.variantId == variantId,
      orElse: () => const BillItem(
        variantId: '',
        productNameSnapshot: '',
        skuSnapshot: '',
        sizeSnapshot: '',
        colorSnapshot: '',
        quantity: 0,
        unitPrice: 0,
        total: 0,
      ),
    );
    if (item.variantId.isNotEmpty) {
      updateQuantity(variantId, item.quantity - 1);
    }
  }

  void removeItem(String variantId) {
    _cartItems.removeWhere((item) => item.variantId == variantId);
    _errorMessage = null;
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _discountType = DiscountType.fixed;
    _discountValue = 0.0;
    _notes = '';
    _selectedCustomer = null;
    _errorMessage = null;
    loadPreviewBillNumber();
    notifyListeners();
  }

  // Customer Management & Discount Memory in POS
  /// When selecting an existing customer:
  /// 1. Sets selected customer
  /// 2. Automatically loads customer.last_discount as default fixed discount
  void setCustomer(Customer? customer) {
    _selectedCustomer = customer;
    _errorMessage = null;

    if (customer != null) {
      // Customer discount memory: Load customer's last discount as default
      _discountType = DiscountType.fixed;
      _discountValue = customer.lastDiscount;
    } else {
      _discountType = DiscountType.fixed;
      _discountValue = 0.0;
    }

    notifyListeners();
  }

  /// Sets discount mode (Fixed ₹ or Percentage %)
  void setDiscountType(DiscountType type) {
    if (_discountType != type) {
      _discountType = type;
      // If switching to percentage and value > 100, reset or clamp
      if (_discountType == DiscountType.percentage && _discountValue > 100) {
        _discountValue = 10.0;
      }
      notifyListeners();
    }
  }

  /// Sets discount value (amount in ₹ or percentage in %)
  void setDiscountValue(double value) {
    if (value < 0) {
      _discountValue = 0.0;
    } else {
      _discountValue = value;
    }
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

  void clearError() {
    _errorMessage = null;
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

  // Load Sales Bills History
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
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isHistoryLoading = false;
      notifyListeners();
    }
  }
}
