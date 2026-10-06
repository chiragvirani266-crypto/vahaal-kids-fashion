import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';
import '../repositories/product_repository.dart';

enum ProductSortOption {
  newest,
  nameAsc,
  nameDesc,
  priceLowHigh,
  priceHighLow,
  stockLowHigh,
  stockHighLow,
}

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  List<Product> _products = [];
  List<String> _categories = [];
  String _selectedCategory = 'All';
  String _selectedGender = 'All';
  bool _lowStockOnly = false;
  bool _includeInactive = false;
  String _searchQuery = '';
  ProductSortOption _sortOption = ProductSortOption.newest;
  bool _isLoading = false;
  String? _errorMessage;
  Product? _selectedProduct;

  ProductProvider({required ProductRepository repository})
      : _repository = repository;

  // Getters
  List<Product> get products => _products;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get selectedGender => _selectedGender;
  bool get lowStockOnly => _lowStockOnly;
  bool get includeInactive => _includeInactive;
  String get searchQuery => _searchQuery;
  ProductSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Product? get selectedProduct => _selectedProduct;

  int get totalProductsCount => _products.length;
  int get activeProductsCount => _products.where((p) => p.isActive).length;
  int get lowStockCount => _products.where((p) => p.hasLowStock).length;
  int get totalStockItems => _products.fold(0, (sum, p) => sum + p.totalStock);

  List<Product> get filteredProducts {
    List<Product> list = List.from(_products);

    // Apply Sort
    switch (_sortOption) {
      case ProductSortOption.newest:
        list.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case ProductSortOption.nameAsc:
        list.sort((a, b) => a.productName.toLowerCase().compareTo(b.productName.toLowerCase()));
        break;
      case ProductSortOption.nameDesc:
        list.sort((a, b) => b.productName.toLowerCase().compareTo(a.productName.toLowerCase()));
        break;
      case ProductSortOption.priceLowHigh:
        list.sort((a, b) => a.sellingPrice.compareTo(b.sellingPrice));
        break;
      case ProductSortOption.priceHighLow:
        list.sort((a, b) => b.sellingPrice.compareTo(a.sellingPrice));
        break;
      case ProductSortOption.stockLowHigh:
        list.sort((a, b) => a.totalStock.compareTo(b.totalStock));
        break;
      case ProductSortOption.stockHighLow:
        list.sort((a, b) => b.totalStock.compareTo(a.totalStock));
        break;
    }

    return list;
  }

  /// Loads all products and categories from repository
  Future<void> loadProducts({bool refresh = false}) async {
    if (_products.isNotEmpty && !refresh) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedCategories = await _repository.getCategories();
      _categories = ['All', ...fetchedCategories];

      _products = await _repository.getProducts(
        includeInactive: _includeInactive,
        category: _selectedCategory,
        gender: _selectedGender,
        lowStockOnly: _lowStockOnly,
        searchQuery: _searchQuery,
      );
      _errorMessage = null;
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load products. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _fetchWithCurrentFilters();
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _fetchWithCurrentFilters();
  }

  void setGender(String gender) {
    if (_selectedGender == gender) return;
    _selectedGender = gender;
    _fetchWithCurrentFilters();
  }

  void setLowStockOnly(bool value) {
    if (_lowStockOnly == value) return;
    _lowStockOnly = value;
    _fetchWithCurrentFilters();
  }

  void setIncludeInactive(bool value) {
    if (_includeInactive == value) return;
    _includeInactive = value;
    _fetchWithCurrentFilters();
  }

  void setSortOption(ProductSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> _fetchWithCurrentFilters() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _repository.getProducts(
        includeInactive: _includeInactive,
        category: _selectedCategory,
        gender: _selectedGender,
        lowStockOnly: _lowStockOnly,
        searchQuery: _searchQuery,
      );
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to update filters.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedProduct = await _repository.getProductById(id);
    } on AppException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load product details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product, List<ProductVariant> variants) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newProduct = await _repository.addProduct(product, variants);
      _products.insert(0, newProduct);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred while creating the product.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(Product product, List<ProductVariant> variants) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateProduct(product, variants);
      final index = _products.indexWhere((p) => p.id == updated.id);
      if (index != -1) {
        _products[index] = updated;
      }
      if (_selectedProduct?.id == updated.id) {
        _selectedProduct = updated;
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
      _errorMessage = 'An error occurred while updating the product.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> softDeleteProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.softDeleteProduct(productId);
      if (!_includeInactive) {
        _products.removeWhere((p) => p.id == productId);
      } else {
        final index = _products.indexWhere((p) => p.id == productId);
        if (index != -1) {
          _products[index] = _products[index].copyWith(isActive: false);
        }
      }
      if (_selectedProduct?.id == productId) {
        _selectedProduct = _selectedProduct?.copyWith(isActive: false);
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
      _errorMessage = 'Failed to deactivate product.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> reactivateProduct(String productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.reactivateProduct(productId);
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(isActive: true);
      }
      if (_selectedProduct?.id == productId) {
        _selectedProduct = _selectedProduct?.copyWith(isActive: true);
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
      _errorMessage = 'Failed to reactivate product.';
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
