import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/providers/product_provider.dart';
import 'package:vahaal_kids_fashion/repositories/product_repository.dart';
import 'package:vahaal_kids_fashion/screens/inventory/product_list_screen.dart';
import 'package:vahaal_kids_fashion/theme/app_theme.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products;
  MockProductRepository(this._products);

  @override
  Future<List<Product>> getProducts({
    bool includeInactive = false,
    String? category,
    String? gender,
    bool? lowStockOnly,
    String? searchQuery,
  }) async => _products;

  @override
  Future<Product> getProductById(String id) async =>
      _products.firstWhere((p) => p.id == id);

  @override
  Future<Product> addProduct(Product product, List<ProductVariant> variants) async =>
      product;

  @override
  Future<Product> updateProduct(Product product, List<ProductVariant> variants) async =>
      product;

  @override
  Future<void> softDeleteProduct(String productId) async {}

  @override
  Future<void> reactivateProduct(String productId) async {}

  @override
  Future<ProductVariant?> findVariantByBarcode(String barcode) async => null;

  @override
  Future<List<String>> getCategories() async => ['Frocks', 'T-Shirts'];
}

void main() {
  final testProducts = [
    Product(
      id: 'prod-1',
      sku: 'VKF-FRK-001',
      productName: 'Baby Girl Summer Floral Frock',
      category: 'Frocks',
      gender: 'Girl',
      purchasePrice: 250.0,
      sellingPrice: 599.0,
      isActive: true,
      variants: const [
        ProductVariant(
          id: 'v-1',
          productId: 'prod-1',
          size: '1-2Y',
          color: 'Pink',
          sku: 'VKF-FRK-001-12Y-PNK',
          barcode: '8901001',
          stockQuantity: 12,
        ),
        ProductVariant(
          id: 'v-2',
          productId: 'prod-1',
          size: '2-3Y',
          color: 'Yellow',
          sku: 'VKF-FRK-001-23Y-YEL',
          barcode: '8901002',
          stockQuantity: 2,
        ),
      ],
    ),
    Product(
      id: 'prod-2',
      sku: 'VKF-TSH-002',
      productName: 'Boys Cotton Dino Graphic T-Shirt',
      category: 'T-Shirts',
      gender: 'Boy',
      purchasePrice: 180.0,
      sellingPrice: 399.0,
      isActive: true,
      variants: const [
        ProductVariant(
          id: 'v-3',
          productId: 'prod-2',
          size: '3-4Y',
          color: 'Blue',
          sku: 'VKF-TSH-002-34Y-BLU',
          barcode: '8901003',
          stockQuantity: 0,
        ),
      ],
    ),
  ];

  Widget buildTestApp({required bool isEmbedded, required Size size}) {
    final mockRepo = MockProductRepository(testProducts);
    final productProvider = ProductProvider(repository: mockRepo);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: ChangeNotifierProvider<ProductProvider>.value(
            value: productProvider..loadProducts(),
            child: ProductListScreen(isEmbedded: isEmbedded),
          ),
        ),
      ),
    );
  }

  testWidgets('renders ProductListScreen in mobile embedded mode without unbounded RenderFlex errors',
      (tester) async {
    const mobileSize = Size(390, 844); // Standard iPhone width & height
    tester.view.physicalSize = mobileSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp(isEmbedded: true, size: mobileSize));
    await tester.pumpAndSettle();

    // Verify products are displayed
    expect(find.text('Baby Girl Summer Floral Frock'), findsOneWidget);
    expect(find.text('Boys Cotton Dino Graphic T-Shirt'), findsOneWidget);

    // Verify no rendering exceptions thrown
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders ProductListScreen in mobile standalone mode without unbounded RenderFlex errors',
      (tester) async {
    const mobileSize = Size(360, 720); // Small Android screen
    tester.view.physicalSize = mobileSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp(isEmbedded: false, size: mobileSize));
    await tester.pumpAndSettle();

    expect(find.text('Baby Girl Summer Floral Frock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders ProductListScreen in desktop grid and table mode without error',
      (tester) async {
    const desktopSize = Size(1280, 800);
    tester.view.physicalSize = desktopSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp(isEmbedded: true, size: desktopSize));
    await tester.pumpAndSettle();

    expect(find.text('Baby Girl Summer Floral Frock'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
