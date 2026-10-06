import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts({
    bool includeInactive = false,
    String? category,
    String? gender,
    bool? lowStockOnly,
    String? searchQuery,
  });

  Future<Product> getProductById(String id);

  Future<Product> addProduct(Product product, List<ProductVariant> variants);

  Future<Product> updateProduct(Product product, List<ProductVariant> variants);

  Future<void> softDeleteProduct(String productId);

  Future<void> reactivateProduct(String productId);

  Future<ProductVariant?> findVariantByBarcode(String barcode);

  Future<List<String>> getCategories();
}

class SupabaseProductRepository implements ProductRepository {
  final SupabaseClient _supabase;

  SupabaseProductRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<List<Product>> getProducts({
    bool includeInactive = false,
    String? category,
    String? gender,
    bool? lowStockOnly,
    String? searchQuery,
  }) async {
    try {
      var query = _supabase
          .from(SupabaseConstants.tableProducts)
          .select('*, product_variants(*)');

      if (!includeInactive) {
        query = query.eq('is_active', true);
      }

      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }

      if (gender != null && gender.isNotEmpty && gender != 'All') {
        query = query.eq('gender', gender);
      }

      final data = await query.order('created_at', ascending: false);

      List<Product> products = (data as List)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      // Client-side search and low stock filtering
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final queryLower = searchQuery.trim().toLowerCase();
        products = products.where((p) {
          final matchesName = p.productName.toLowerCase().contains(queryLower);
          final matchesSku = p.sku.toLowerCase().contains(queryLower);
          final matchesBarcode = p.barcode?.toLowerCase().contains(queryLower) ?? false;
          final matchesCategory = p.category.toLowerCase().contains(queryLower);
          final matchesVariant = p.variants.any((v) =>
              v.sku.toLowerCase().contains(queryLower) ||
              v.barcode.toLowerCase().contains(queryLower) ||
              v.color.toLowerCase().contains(queryLower) ||
              v.size.toLowerCase().contains(queryLower));
          return matchesName || matchesSku || matchesBarcode || matchesCategory || matchesVariant;
        }).toList();
      }

      if (lowStockOnly == true) {
        products = products.where((p) => p.hasLowStock || p.isOutOfStock).toList();
      }

      return products;
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to fetch products: $e');
    }
  }

  @override
  Future<Product> getProductById(String id) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableProducts)
          .select('*, product_variants(*)')
          .eq('id', id)
          .single();

      return Product.fromJson(data);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to load product details: $e');
    }
  }

  @override
  Future<Product> addProduct(Product product, List<ProductVariant> variants) async {
    try {
      // 1. Insert parent product
      final productData = await _supabase
          .from(SupabaseConstants.tableProducts)
          .insert(product.toJson(includeId: false))
          .select()
          .single();

      final newProductId = productData['id'] as String;

      // 2. Insert variants if any
      List<ProductVariant> savedVariants = [];
      if (variants.isNotEmpty) {
        final variantsToInsert = variants.map((v) {
          final map = v.toJson(includeId: false);
          map['product_id'] = newProductId;
          return map;
        }).toList();

        final variantsData = await _supabase
            .from(SupabaseConstants.tableProductVariants)
            .insert(variantsToInsert)
            .select();

        savedVariants = (variantsData as List)
            .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
            .toList();

        // 3. Log initial stock transactions for any variants with stock > 0
        final user = _supabase.auth.currentUser;
        for (final v in savedVariants) {
          if (v.stockQuantity > 0 && v.id != null) {
            await _supabase.from(SupabaseConstants.tableStockTransactions).insert({
              'variant_id': v.id,
              'transaction_type': 'purchase_in',
              'quantity': v.stockQuantity,
              'previous_stock': 0,
              'new_stock': v.stockQuantity,
              'reference': 'INITIAL-STOCK',
              'note': 'Initial stock registration for ${product.productName} (${v.displayName})',
              'created_by': user?.id,
            });
          }
        }
      }

      return Product.fromJson(productData).copyWith(variants: savedVariants);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate key') || e.code == '23505') {
        if (e.message.contains('barcode')) {
          throw const AppException('A product or variant with this barcode already exists.');
        }
        if (e.message.contains('sku')) {
          throw const AppException('A product or variant with this SKU already exists.');
        }
      }
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to create product: $e');
    }
  }

  @override
  Future<Product> updateProduct(Product product, List<ProductVariant> variants) async {
    try {
      if (product.id == null) {
        throw const AppException('Product ID is required for updating.');
      }

      // 1. Update parent product
      final productData = await _supabase
          .from(SupabaseConstants.tableProducts)
          .update(product.toJson(includeId: false))
          .eq('id', product.id!)
          .select()
          .single();

      // 2. Fetch existing variants to determine update/insert/delete
      final existingData = await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .select()
          .eq('product_id', product.id!);

      final existingVariants = (existingData as List)
          .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
          .toList();

      final existingIds = existingVariants.map((v) => v.id).whereType<String>().toSet();
      final currentIds = variants.map((v) => v.id).whereType<String>().toSet();

      // Variants to delete
      final idsToDelete = existingIds.difference(currentIds);
      for (final id in idsToDelete) {
        try {
          await _supabase
              .from(SupabaseConstants.tableProductVariants)
              .delete()
              .eq('id', id);
        } catch (_) {
          // If referenced by past bills, foreign key cascade handles or keep
        }
      }

      // Upsert current variants
      List<ProductVariant> updatedVariants = [];
      final user = _supabase.auth.currentUser;

      for (final variant in variants) {
        if (variant.id != null && existingIds.contains(variant.id)) {
          // Update existing variant
          final oldVariant = existingVariants.firstWhere((v) => v.id == variant.id);
          
          final updatedData = await _supabase
              .from(SupabaseConstants.tableProductVariants)
              .update(variant.toJson(includeId: false))
              .eq('id', variant.id!)
              .select()
              .single();

          final updated = ProductVariant.fromJson(updatedData);
          updatedVariants.add(updated);

          // Log stock adjustment if stock changed
          if (oldVariant.stockQuantity != variant.stockQuantity) {
            final diff = variant.stockQuantity - oldVariant.stockQuantity;
            await _supabase.from(SupabaseConstants.tableStockTransactions).insert({
              'variant_id': variant.id,
              'transaction_type': diff > 0 ? 'adjustment' : 'damage',
              'quantity': diff,
              'previous_stock': oldVariant.stockQuantity,
              'new_stock': variant.stockQuantity,
              'reference': 'MANUAL-EDIT',
              'note': 'Stock adjusted during product update',
              'created_by': user?.id,
            });
          }
        } else {
          // Insert new variant
          final map = variant.toJson(includeId: false);
          map['product_id'] = product.id;

          final insertedData = await _supabase
              .from(SupabaseConstants.tableProductVariants)
              .insert(map)
              .select()
              .single();

          final inserted = ProductVariant.fromJson(insertedData);
          updatedVariants.add(inserted);

          if (inserted.stockQuantity > 0 && inserted.id != null) {
            await _supabase.from(SupabaseConstants.tableStockTransactions).insert({
              'variant_id': inserted.id,
              'transaction_type': 'purchase_in',
              'quantity': inserted.stockQuantity,
              'previous_stock': 0,
              'new_stock': inserted.stockQuantity,
              'reference': 'NEW-VARIANT',
              'note': 'Initial stock for added variant (${inserted.displayName})',
              'created_by': user?.id,
            });
          }
        }
      }

      return Product.fromJson(productData).copyWith(variants: updatedVariants);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      if (e.message.contains('duplicate key') || e.code == '23505') {
        throw const AppException('A variant with this barcode or SKU already exists.');
      }
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to update product: $e');
    }
  }

  @override
  Future<void> softDeleteProduct(String productId) async {
    try {
      await _supabase
          .from(SupabaseConstants.tableProducts)
          .update({'is_active': false})
          .eq('id', productId);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to deactivate product: $e');
    }
  }

  @override
  Future<void> reactivateProduct(String productId) async {
    try {
      await _supabase
          .from(SupabaseConstants.tableProducts)
          .update({'is_active': true})
          .eq('id', productId);
    } on SocketException {
      throw const NetworkException();
    } on PostgrestException catch (e) {
      throw AppException(e.message);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Failed to reactivate product: $e');
    }
  }

  @override
  Future<ProductVariant?> findVariantByBarcode(String barcode) async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableProductVariants)
          .select('*, products(*)')
          .eq('barcode', barcode.trim())
          .maybeSingle();

      if (data == null) return null;
      return ProductVariant.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final data = await _supabase
          .from(SupabaseConstants.tableProducts)
          .select('category');

      final set = <String>{
        'Frocks',
        'T-Shirts',
        'Shirts',
        'Jeans & Pants',
        'Shorts',
        'Ethnic Wear',
        'Nightwear',
        'Winterwear',
        'Dungarees',
        'Infant Sets',
        'Accessories',
      };

      for (final row in (data as List)) {
        final cat = row['category'] as String?;
        if (cat != null && cat.isNotEmpty) {
          set.add(cat);
        }
      }

      return set.toList()..sort();
    } catch (_) {
      return [
        'Frocks',
        'T-Shirts',
        'Shirts',
        'Jeans & Pants',
        'Shorts',
        'Ethnic Wear',
        'Nightwear',
        'Winterwear',
        'Dungarees',
        'Infant Sets',
        'Accessories',
      ];
    }
  }
}
