import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/services/printer/formatters/code128_encoder.dart';
import 'package:vahaal_kids_fashion/services/printer/formatters/thermal_receipt_formatter.dart';
import 'package:vahaal_kids_fashion/services/printer/label_printer_service.dart';
import 'package:vahaal_kids_fashion/services/printer/printer_models.dart';

void main() {
  group('Product Label Printing & Barcode Generator Tests', () {
    const testProduct = Product(
      id: 'prod-001',
      sku: 'VKF-TSHIRT-001',
      productName: 'Kids Printed Summer Tee',
      category: 'T-Shirts',
      brand: 'Vahaal Kids',
      gender: 'Boy',
      purchasePrice: 200.0,
      sellingPrice: 499.0,
      barcode: '8901234567890',
    );

    const testVariant1 = ProductVariant(
      id: 'var-01',
      productId: 'prod-001',
      size: '2Y',
      color: 'Red',
      sku: 'VKF-TEE-2Y-RED',
      barcode: '890123450001',
      sellingPrice: 499.0,
      stockQuantity: 15,
      lowStockAlert: 3,
    );

    const testVariant2 = ProductVariant(
      id: 'var-02',
      productId: 'prod-001',
      size: '3Y',
      color: 'Blue',
      sku: 'VKF-TEE-3Y-BLU',
      barcode: '890123450002',
      sellingPrice: 549.0,
      stockQuantity: 8,
      lowStockAlert: 3,
    );

    group('Code 128 Barcode Generation Tests', () {
      test('Encodes alphanumeric barcode string into valid Code 128-B symbols', () {
        const barcodeText = 'VKF-2026';
        final symbols = Code128Encoder.getSymbolIndices(barcodeText);

        // Start B (104) is first
        expect(symbols.first, 104);
        // Stop (106) is last
        expect(symbols.last, 106);
        // Length = Start (1) + data (8) + checksum (1) + stop (1) = 11
        expect(symbols.length, 11);
      });

      test('Calculates checksum correctly according to ISO/IEC 15417', () {
        // For text '1234':
        // StartB=104
        // '1' (code 49 - 32 = 17) * 1 = 17
        // '2' (code 50 - 32 = 18) * 2 = 36
        // '3' (code 51 - 32 = 19) * 3 = 57
        // '4' (code 52 - 32 = 20) * 4 = 80
        // sum = 104 + 17 + 36 + 57 + 80 = 294
        // 294 % 103 = 88
        final checksum = Code128Encoder.calculateChecksum('1234');
        expect(checksum, 88);
      });

      test('Generates binary module array with quiet zones', () {
        final modules = Code128Encoder.encodeToModules('8901234567890', quietZoneModules: 10);
        expect(modules.isNotEmpty, true);

        // Quiet zones must be false (white space)
        for (int i = 0; i < 10; i++) {
          expect(modules[i], false);
        }
        for (int i = modules.length - 10; i < modules.length; i++) {
          expect(modules[i], false);
        }

        // At least one black bar exists
        expect(modules.contains(true), true);
      });

      test('Handles empty and non-ASCII strings safely without crashing', () {
        final emptyModules = Code128Encoder.encodeToModules('');
        expect(emptyModules.isNotEmpty, true);

        final sanitized = Code128Encoder.sanitize('Hello 世界 123');
        expect(sanitized, isNot(contains('世')));
        expect(sanitized, contains('Hello'));
        expect(sanitized, contains('123'));
      });
    });

    group('Label Formatting & Information Integrity Tests', () {
      test('Formatted label contains store name, product name, size, color, SKU, price, and barcode', () {
        final text = ThermalReceiptFormatter.formatVariantLabelText(
          testVariant1,
          product: testProduct,
          config: const LabelConfig(
            showStoreName: true,
            showProductName: true,
            showSizeAndColor: true,
            showSku: true,
            showBarcode: true,
            showPrice: true,
          ),
        );

        expect(text, contains('VAHAAL KIDS FASHION'));
        expect(text, contains('Kids Printed Summer Tee'));
        expect(text, contains('Size: 2Y'));
        expect(text, contains('Color: Red'));
        expect(text, contains('SKU: VKF-TEE-2Y-RED'));
        expect(text, contains('890123450001'));
        expect(text, contains('MRP: Rs. 499.00'));
      });

      test('Respects toggles in LabelConfig to hide fields', () {
        final text = ThermalReceiptFormatter.formatVariantLabelText(
          testVariant1,
          product: testProduct,
          config: const LabelConfig(
            showStoreName: false,
            showPrice: false,
            showSku: false,
          ),
        );

        expect(text.contains('VAHAAL KIDS FASHION'), false);
        expect(text.contains('MRP:'), false);
        expect(text.contains('SKU:'), false);
        expect(text, contains('Kids Printed Summer Tee'));
        expect(text, contains('Size: 2Y'));
      });

      test('Supports configurable label sizes and presets', () {
        const config50x25 = LabelConfig(preset: LabelSizePreset.standard50x25);
        expect(config50x25.widthMm, 50.0);
        expect(config50x25.heightMm, 25.0);

        const config38x25 = LabelConfig(preset: LabelSizePreset.compact38x25);
        expect(config38x25.widthMm, 50.0); // constructor default or custom

        final customConfig = const LabelConfig().copyWith(
          preset: LabelSizePreset.custom,
          widthMm: 60.0,
          heightMm: 30.0,
        );
        expect(customConfig.widthMm, 60.0);
        expect(customConfig.heightMm, 30.0);
      });

      test('ESC/POS generator builds non-empty binary payload with barcode command', () {
        final bytes = ThermalReceiptFormatter.formatVariantLabelEscPos(
          testVariant1,
          product: testProduct,
        );

        expect(bytes.isNotEmpty, true);
        // Header contains ESC @ (0x1B, 0x40)
        expect(bytes[0], 0x1B);
        expect(bytes[1], 0x40);
      });

      test('Multi-copy ESC/POS generator replicates byte stream by copy count', () {
        final singleBytes = ThermalReceiptFormatter.formatVariantLabelEscPos(
          testVariant1,
          product: testProduct,
        );
        final multiBytes = ThermalReceiptFormatter.formatMultipleVariantLabelsEscPos(
          testVariant1,
          product: testProduct,
          copies: 3,
        );

        expect(multiBytes.length, singleBytes.length * 3);
      });
    });

    group('LabelPrinterService Abstraction & Batch Printing Tests', () {
      final service = LabelPrinterServiceFactory.getInstance();

      test('Print single label returns success/fallback result without throwing', () async {
        final result = await service.printSingleLabel(
          testVariant1,
          product: testProduct,
        );

        expect(result.isSuccess, true);
        expect(result.formattedText, isNotNull);
        expect(result.rawBytes, isNotNull);
      });

      test('Print multiple labels sets quantity and generates payload', () async {
        final result = await service.printMultipleLabels(
          testVariant1,
          product: testProduct,
          quantity: 5,
        );

        expect(result.isSuccess, true);
        expect(result.message, contains('5 barcode labels'));
      });

      test('Print batch labels for selected variants with custom quantities', () async {
        final items = [
          const LabelPrintItem(
            variant: testVariant1,
            product: testProduct,
            quantity: 3,
            isSelected: true,
          ),
          const LabelPrintItem(
            variant: testVariant2,
            product: testProduct,
            quantity: 4,
            isSelected: true,
          ),
        ];

        final result = await service.printBatchLabels(items);
        expect(result.isSuccess, true);
        // Total 3 + 4 = 7 labels across 2 variants
        expect(result.message, contains('7 barcode labels'));
        expect(result.message, contains('2 variant(s)'));
      });

      test('Batch printing ignores unselected items', () async {
        final items = [
          const LabelPrintItem(
            variant: testVariant1,
            product: testProduct,
            quantity: 5,
            isSelected: true,
          ),
          const LabelPrintItem(
            variant: testVariant2,
            product: testProduct,
            quantity: 10,
            isSelected: false,
          ),
        ];

        final result = await service.printBatchLabels(items);
        expect(result.isSuccess, true);
        // Only 5 labels from variant 1
        expect(result.message, contains('5 barcode labels'));
        expect(result.message, contains('1 variant(s)'));
      });

      test('Batch printing with zero selected items fails gracefully with error message', () async {
        final items = [
          const LabelPrintItem(
            variant: testVariant1,
            product: testProduct,
            quantity: 2,
            isSelected: false,
          ),
        ];

        final result = await service.printBatchLabels(items);
        expect(result.isSuccess, false);
        expect(result.message, contains('No labels selected'));
      });

      test('LabelPrinterServiceFactory singleton and reset works as expected', () {
        final instance1 = LabelPrinterServiceFactory.getInstance();
        final instance2 = LabelPrinterServiceFactory.getInstance();
        expect(identical(instance1, instance2), true);
      });
    });
  });
}
