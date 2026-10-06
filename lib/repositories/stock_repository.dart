import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/stock_item_model.dart';
import '../models/stock_transaction_model.dart';

abstract class StockRepository {
  Future<List<StockItem>> getStockItems({
    String? category,
    String? size,
    String? search,
    bool? lowStockOnly,
  });

  Future<void> recordStockTransaction({
    required String variantId,
    required String transactionType, // 'purchase_in' | 'sale' | 'return' | 'adjustment' | 'damage'
    required int quantity,
    required String reference,
    String? note,
  });

  Future<void> recordStockAdjustment({
    required String variantId,
    required int targetNewStock,
    required String reason,
    required String reference,
  });

  Future<List<StockTransaction>> getStockTransactions({
    String? variantId,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  });

  Future<List<StockItem>> getLowStockItems();

  Future<Map<String, dynamic>> getStockOverviewStats();
}

class SupabaseStockRepository implements StockRepository {
  final SupabaseClient _supabase;

  SupabaseStockRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<List<StockItem>> getStockItems({
    String? category,
    String? size,
    String? search,
    bool? lowStockOnly,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableProductVariants)
          .select('*, products(*)');

      final data = await query;
      List<StockItem> items = (data as List)
          .map((row) => StockItem.fromVariantJson(row as Map<String, dynamic>))
          .toList();

      // Client-side multi-filter
      if (category != null && category.isNotEmpty && category != 'All') {
        items = items.where((i) => i.category.toLowerCase() == category.toLowerCase()).toList();
      }

      if (size != null && size.isNotEmpty && size != 'All') {
        items = items.where((i) => i.size.toLowerCase() == size.toLowerCase()).toList();
      }

      if (lowStockOnly == true) {
        items = items.where((i) => i.status != StockStatus.inStock).toList();
      }

      if (search != null && search.trim().isNotEmpty) {
        final queryLower = search.trim().toLowerCase();
        items = items.where((i) {
          final matchesProduct = i.productName.toLowerCase().contains(queryLower);
          final matchesSku = i.sku.toLowerCase().contains(queryLower);
          final matchesBarcode = i.barcode.toLowerCase().contains(queryLower);
          final matchesColor = i.color.toLowerCase().contains(queryLower);
          final matchesSize = i.size.toLowerCase().contains(queryLower);
          return matchesProduct || matchesSku || matchesBarcode || matchesColor || matchesSize;
        }).toList();
      }

      return items;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load stock inventory: $e');
    }
  }

  @override
  Future<void> recordStockTransaction({
    required String variantId,
    required String transactionType,
    required int quantity,
    required String reference,
    String? note,
  }) async {
    try {
      // 1. Fetch current stock
      final variantData = await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .select('stock_quantity, sku, size, products(product_name)')
          .eq('id', variantId)
          .single();

      final previousStock = (variantData['stock_quantity'] as num?)?.toInt() ?? 0;
      final newStock = previousStock + quantity;

      if (newStock < 0) {
        throw AppException(
          'Insufficient stock available. Current stock: $previousStock units, requested change: $quantity units.',
        );
      }

      final user = _supabase.auth.currentUser;

      // 2. Update variant stock
      await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .update({'stock_quantity': newStock})
          .eq('id', variantId);

      // 3. Log stock transaction
      await _supabase.from(SupabaseConstants.tableStockTransactions).insert({
        'variant_id': variantId,
        'transaction_type': transactionType,
        'quantity': quantity,
        'previous_stock': previousStock,
        'new_stock': newStock,
        'reference': reference.trim(),
        'note': note?.trim(),
        'created_by': user?.id,
      });
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to record stock movement: $e');
    }
  }

  @override
  Future<void> recordStockAdjustment({
    required String variantId,
    required int targetNewStock,
    required String reason,
    required String reference,
  }) async {
    try {
      if (targetNewStock < 0) {
        throw const AppException('Target stock quantity cannot be negative.');
      }

      final variantData = await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .select('stock_quantity')
          .eq('id', variantId)
          .single();

      final previousStock = (variantData['stock_quantity'] as num?)?.toInt() ?? 0;
      final diff = targetNewStock - previousStock;
      final user = _supabase.auth.currentUser;

      // Update variant stock
      await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .update({'stock_quantity': targetNewStock})
          .eq('id', variantId);

      // Log transaction
      await _supabase.from(SupabaseConstants.tableStockTransactions).insert({
        'variant_id': variantId,
        'transaction_type': 'adjustment',
        'quantity': diff,
        'previous_stock': previousStock,
        'new_stock': targetNewStock,
        'reference': reference.trim(),
        'note': reason.trim(),
        'created_by': user?.id,
      });
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to adjust stock: $e');
    }
  }

  @override
  Future<List<StockTransaction>> getStockTransactions({
    String? variantId,
    String? transactionType,
    DateTime? startDate,
    DateTime? endDate,
    String? search,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableStockTransactions)
          .select('*, product_variants(*, products(*)), profiles(*)');

      if (variantId != null && variantId.isNotEmpty) {
        query = query.eq('variant_id', variantId);
      }

      if (transactionType != null && transactionType.isNotEmpty && transactionType != 'All') {
        query = query.eq('transaction_type', transactionType.toLowerCase());
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final data = await query.order('created_at', ascending: false);

      List<StockTransaction> list = (data as List)
          .map((row) => StockTransaction.fromJson(row as Map<String, dynamic>))
          .toList();

      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        list = list.where((tx) {
          final matchesRef = tx.reference?.toLowerCase().contains(q) ?? false;
          final matchesNote = tx.note?.toLowerCase().contains(q) ?? false;
          final matchesProd = tx.productName?.toLowerCase().contains(q) ?? false;
          final matchesSku = tx.variantSku?.toLowerCase().contains(q) ?? false;
          final matchesBarcode = tx.variantBarcode?.toLowerCase().contains(q) ?? false;
          return matchesRef || matchesNote || matchesProd || matchesSku || matchesBarcode;
        }).toList();
      }

      return list;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load stock history: $e');
    }
  }

  @override
  Future<List<StockItem>> getLowStockItems() async {
    try {
      final items = await getStockItems(lowStockOnly: true);
      return items;
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load low stock items: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStockOverviewStats() async {
    try {
      final items = await getStockItems();
      final totalVariants = items.length;
      final totalStockUnits = items.fold(0, (sum, i) => sum + i.currentStock);
      final lowStockCount = items.where((i) => i.status == StockStatus.lowStock).length;
      final outOfStockCount = items.where((i) => i.status == StockStatus.outOfStock).length;
      final totalValuation = items.fold(0.0, (sum, i) => sum + (i.currentStock * i.purchasePrice));
      final totalRetailValue = items.fold(0.0, (sum, i) => sum + (i.currentStock * i.sellingPrice));

      return {
        'totalVariants': totalVariants,
        'totalStockUnits': totalStockUnits,
        'lowStockCount': lowStockCount,
        'outOfStockCount': outOfStockCount,
        'totalValuation': totalValuation,
        'totalRetailValue': totalRetailValue,
      };
    } catch (e) {
      return {
        'totalVariants': 0,
        'totalStockUnits': 0,
        'lowStockCount': 0,
        'outOfStockCount': 0,
        'totalValuation': 0.0,
        'totalRetailValue': 0.0,
      };
    }
  }
}
