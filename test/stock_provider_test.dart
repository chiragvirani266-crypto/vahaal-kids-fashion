import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/core/errors/app_exception.dart';
import 'package:vahaal_kids_fashion/models/stock_item_model.dart';
import 'package:vahaal_kids_fashion/models/stock_transaction_model.dart';
import 'package:vahaal_kids_fashion/providers/stock_provider.dart';
import 'package:vahaal_kids_fashion/repositories/stock_repository.dart';

class MockStockRepository implements StockRepository {
  bool shouldThrowError = false;
  String? lastTransactionType;
  int? lastQuantity;
  String? lastVariantId;
  String? lastReference;
  String? lastReason;
  int? lastTargetStock;

  final List<StockItem> dummyItems = [
    const StockItem(
      variantId: 'var-1',
      productId: 'prod-1',
      productName: 'T-Shirt Red M',
      category: 'Clothing',
      brand: 'KidsClub',
      gender: 'Unisex',
      size: 'M',
      color: 'Red',
      sku: 'TS-RED-M',
      barcode: '123456789',
      sellingPrice: 499.0,
      purchasePrice: 250.0,
      currentStock: 15,
      lowStockAlert: 5,
      isProductActive: true,
    ),
    const StockItem(
      variantId: 'var-2',
      productId: 'prod-2',
      productName: 'Denim Shorts S',
      category: 'Bottoms',
      brand: 'KidsClub',
      gender: 'Boys',
      size: 'S',
      color: 'Blue',
      sku: 'DS-BLU-S',
      barcode: '987654321',
      sellingPrice: 799.0,
      purchasePrice: 400.0,
      currentStock: 2,
      lowStockAlert: 5,
      isProductActive: true,
    ),
  ];

  @override
  Future<List<StockItem>> getStockItems({
    String? category,
    String? size,
    String? search,
    bool? lowStockOnly,
  }) async {
    if (shouldThrowError) {
      throw const AppException('Database connection error');
    }
    return dummyItems;
  }

  @override
  Future<List<StockItem>> getLowStockItems() async {
    if (shouldThrowError) {
      throw const AppException('Failed to load low stock');
    }
    return dummyItems.where((i) => i.currentStock <= i.lowStockAlert).toList();
  }

  @override
  Future<List<StockTransaction>> getStockTransactions({
    String? variantId,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    if (shouldThrowError) {
      throw const AppException('Failed to load history');
    }
    return [
      StockTransaction(
        id: 'tx-1',
        variantId: 'var-1',
        transactionType: 'purchase_in',
        quantity: 10,
        previousStock: 5,
        newStock: 15,
        reference: 'INV-100',
        createdAt: DateTime(2026, 10, 20),
      ),
    ];
  }

  @override
  Future<Map<String, dynamic>> getStockOverviewStats() async {
    if (shouldThrowError) {
      throw const AppException('Failed to load stats');
    }
    return {
      'totalVariants': 2,
      'totalStockUnits': 17,
      'lowStockCount': 1,
      'outOfStockCount': 0,
      'totalValuation': 4550.0,
      'totalRetailValue': 9083.0,
    };
  }

  @override
  Future<void> recordStockTransaction({
    required String variantId,
    required String transactionType,
    required int quantity,
    required String reference,
    String? note,
  }) async {
    if (shouldThrowError) {
      throw const AppException('Transaction failed');
    }
    lastVariantId = variantId;
    lastTransactionType = transactionType;
    lastQuantity = quantity;
    lastReference = reference;
  }

  @override
  Future<void> recordStockAdjustment({
    required String variantId,
    required int targetNewStock,
    required String reason,
    required String reference,
  }) async {
    if (shouldThrowError) {
      throw const AppException('Adjustment failed');
    }
    lastVariantId = variantId;
    lastTargetStock = targetNewStock;
    lastReason = reason;
    lastReference = reference;
  }
}

void main() {
  late MockStockRepository mockRepo;
  late StockProvider provider;

  setUp(() {
    mockRepo = MockStockRepository();
    provider = StockProvider(repository: mockRepo);
  });

  group('StockProvider Initialization & Dashboard', () {
    test('initial state has empty data and no error', () {
      expect(provider.stockItems, isEmpty);
      expect(provider.lowStockItems, isEmpty);
      expect(provider.transactions, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.currentPage, 1);
      expect(provider.pageSize, 20);
    });

    test('loadStockDashboard populates overview and stock list', () async {
      await provider.loadStockDashboard();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, isNull);
      expect(provider.stockItems.length, 2);
      expect(provider.lowStockItems.length, 1);
      expect(provider.transactions.length, 1);
      expect(provider.totalStockUnits, 17);
      expect(provider.lowStockCount, 1);
      expect(provider.totalValuation, 4550.0);
      expect(provider.availableCategories, containsAll(['All', 'Clothing', 'Bottoms']));
    });

    test('loadStockDashboard handles AppException and sets errorMessage', () async {
      mockRepo.shouldThrowError = true;

      await provider.loadStockDashboard();

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'Failed to load stats');
    });

    test('clearError resets errorMessage', () async {
      mockRepo.shouldThrowError = true;
      await provider.loadStockDashboard();
      expect(provider.errorMessage, isNotNull);

      provider.clearError();
      expect(provider.errorMessage, isNull);
    });
  });

  group('Stock Operations', () {
    test('stockIn with invalid quantity fails with error', () async {
      final success = await provider.stockIn(
        variantId: 'var-1',
        quantity: 0,
        invoiceRef: 'INV-001',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('greater than zero'));
    });

    test('stockIn records purchase transaction successfully', () async {
      final success = await provider.stockIn(
        variantId: 'var-1',
        quantity: 20,
        invoiceRef: 'INV-1234',
        note: 'New batch',
      );

      expect(success, isTrue);
      expect(mockRepo.lastVariantId, 'var-1');
      expect(mockRepo.lastTransactionType, 'purchase_in');
      expect(mockRepo.lastQuantity, 20);
      expect(mockRepo.lastReference, 'INV-1234');
      expect(provider.errorMessage, isNull);
    });

    test('stockOut with invalid quantity fails with error', () async {
      final success = await provider.stockOut(
        variantId: 'var-1',
        quantity: -5,
        reason: 'Damaged item',
        reference: 'DMG-1',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('greater than zero'));
    });

    test('stockOut records negative quantity transaction', () async {
      final success = await provider.stockOut(
        variantId: 'var-1',
        quantity: 3,
        reason: 'Water damage',
        reference: 'DMG-101',
      );

      expect(success, isTrue);
      expect(mockRepo.lastVariantId, 'var-1');
      expect(mockRepo.lastTransactionType, 'damage');
      expect(mockRepo.lastQuantity, -3);
      expect(mockRepo.lastReference, 'DMG-101');
    });

    test('stockReturn records return transaction', () async {
      final success = await provider.stockReturn(
        variantId: 'var-2',
        quantity: 1,
        billRef: 'BILL-555',
        note: 'Customer size exchange',
      );

      expect(success, isTrue);
      expect(mockRepo.lastVariantId, 'var-2');
      expect(mockRepo.lastTransactionType, 'return');
      expect(mockRepo.lastQuantity, 1);
      expect(mockRepo.lastReference, 'BILL-555');
    });

    test('stockAdjustment validates negative target count', () async {
      final success = await provider.stockAdjustment(
        variantId: 'var-1',
        targetStock: -1,
        reason: 'Audit error',
        reference: 'AUD-01',
      );

      expect(success, isFalse);
      expect(provider.errorMessage, contains('cannot be negative'));
    });

    test('stockAdjustment records adjustment successfully', () async {
      final success = await provider.stockAdjustment(
        variantId: 'var-1',
        targetStock: 12,
        reason: 'Physical count audit',
        reference: 'AUD-99',
      );

      expect(success, isTrue);
      expect(mockRepo.lastVariantId, 'var-1');
      expect(mockRepo.lastTargetStock, 12);
      expect(mockRepo.lastReason, 'Physical count audit');
      expect(mockRepo.lastReference, 'AUD-99');
    });
  });

  group('Pagination & Filtering', () {
    test('pagination calculations work correctly', () async {
      await provider.loadStockDashboard();

      provider.setPageSize(1);
      expect(provider.totalPages, 2);
      expect(provider.hasNextPage, isTrue);
      expect(provider.hasPreviousPage, isFalse);
      expect(provider.paginatedStockItems.length, 1);
      expect(provider.paginatedStockItems.first.variantId, 'var-1');

      provider.nextPage();
      expect(provider.currentPage, 2);
      expect(provider.hasNextPage, isFalse);
      expect(provider.hasPreviousPage, isTrue);
      expect(provider.paginatedStockItems.first.variantId, 'var-2');

      provider.previousPage();
      expect(provider.currentPage, 1);
    });

    test('filters reset page to 1', () async {
      await provider.loadStockDashboard();
      provider.setPageSize(1);
      provider.nextPage();
      expect(provider.currentPage, 2);

      provider.setSearchQuery('Denim');
      expect(provider.currentPage, 1);
      expect(provider.searchQuery, 'Denim');
    });
  });
}
