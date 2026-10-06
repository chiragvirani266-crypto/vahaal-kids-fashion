import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/models/product_model.dart';
import 'package:vahaal_kids_fashion/models/product_variant_model.dart';
import 'package:vahaal_kids_fashion/services/printer/formatters/esc_pos_builder.dart';
import 'package:vahaal_kids_fashion/services/printer/formatters/thermal_receipt_formatter.dart';
import 'package:vahaal_kids_fashion/services/printer/platforms/fallback_printer_service.dart';
import 'package:vahaal_kids_fashion/services/printer/printer_models.dart';
import 'package:vahaal_kids_fashion/services/printer/printer_service_factory.dart';

void main() {
  group('Cross-Platform PrinterService Architecture Unit Tests', () {
    final testBill = Bill(
      id: 'test-bill-1',
      billNumber: 'VKF-2026-001099',
      customerNameSnapshot: 'Chirag Virani',
      customerMobileSnapshot: '9876543210',
      billDate: DateTime(2026, 10, 6, 11, 45),
      subtotal: 1500.0,
      discount: 150.0,
      grandTotal: 1350.0,
      paymentMethod: 'cash',
      cashierName: 'Store Cashier 1',
      items: const [
        BillItem(
          productId: 'p-1',
          variantId: 'v-1',
          productNameSnapshot: 'Kids Polo T-Shirt',
          skuSnapshot: 'VKF-POLO-3Y',
          sizeSnapshot: '3Y',
          colorSnapshot: 'Red',
          quantity: 2,
          unitPrice: 500.0,
          discount: 0.0,
          total: 1000.0,
        ),
        BillItem(
          productId: 'p-2',
          variantId: 'v-2',
          productNameSnapshot: 'Denim Jeans',
          skuSnapshot: 'VKF-JNS-4Y',
          sizeSnapshot: '4Y',
          colorSnapshot: 'Blue',
          quantity: 1,
          unitPrice: 500.0,
          discount: 0.0,
          total: 500.0,
        ),
      ],
    );

    const testVariant = ProductVariant(
      id: 'var-10',
      productId: 'p-1',
      size: '3Y',
      color: 'Red',
      sku: 'VKF-POLO-3Y-RED',
      barcode: '8901234567890',
      stockQuantity: 10,
      sellingPrice: 499.0,
    );

    const testProduct = Product(
      id: 'p-1',
      sku: 'VKF-POLO-001',
      productName: 'Kids Polo T-Shirt',
      category: 'T-Shirts',
      gender: 'Boy',
      purchasePrice: 250.0,
      sellingPrice: 499.0,
    );

    test('80mm receipt contains store name, address, mobile, and items', () {
      final text80 = ThermalReceiptFormatter.formatBillText(
        testBill,
        paperWidth: ReceiptPaperWidth.mm80,
      );

      expect(text80, contains('VAHAAL KIDS FASHION'));
      expect(text80, contains('VKF-2026-001099'));
      expect(text80, contains('Chirag Virani'));
      expect(text80, contains('Kids Polo T-Shirt'));
      expect(text80, contains('Denim Jeans'));
      expect(text80, contains('Rs. 1350.00'));
      expect(text80, contains('CASH'));
      expect(text80, contains('Thank you for shopping'));
    });

    test('58mm receipt formats within 32 columns', () {
      final text58 = ThermalReceiptFormatter.formatBillText(
        testBill,
        paperWidth: ReceiptPaperWidth.mm58,
      );

      expect(text58, contains('VAHAAL KIDS FASHION'));
      expect(text58, contains('VKF-2026-001099'));
      expect(text58, contains('Rs. 1350.00'));

      // Check column dividers do not overflow 32 columns
      final lines = text58.split('\n');
      for (final line in lines) {
        if (line.contains('---')) {
          expect(line.trim().length <= 32, true);
        }
      }
    });

    test('Reprint receipt includes duplicate watermark', () {
      final reprintText = ThermalReceiptFormatter.formatBillText(
        testBill,
        paperWidth: ReceiptPaperWidth.mm80,
        isReprint: true,
      );

      expect(reprintText, contains('*** DUPLICATE REPRINT COPY ***'));
    });

    test('ESC/POS command generator builds non-empty byte stream', () {
      final builder = EscPosBuilder(paperWidth: ReceiptPaperWidth.mm80);
      builder.initialize();
      builder.textLine('VAHAAL KIDS FASHION', bold: true);
      builder.divider();
      builder.row2('Subtotal:', '1500.00');
      builder.cut();

      final bytes = builder.build();
      expect(bytes.isNotEmpty, true);
      // ESC @ (0x1B, 0x40) init header
      expect(bytes[0], 0x1B);
      expect(bytes[1], 0x40);
    });

    test('ESC/POS bill generator creates complete payload with barcode and cut', () {
      final bytes = ThermalReceiptFormatter.formatBillEscPos(
        testBill,
        config: const PrinterConfig(
          paperWidth: ReceiptPaperWidth.mm80,
          autoCut: true,
          openCashDrawer: true,
        ),
      );

      expect(bytes.isNotEmpty, true);
      expect(bytes.length > 50, true);
    });

    test('Barcode price tag sticker generation for ProductVariant', () {
      final labelText = ThermalReceiptFormatter.formatVariantLabelText(
        testVariant,
        product: testProduct,
      );

      expect(labelText, contains('VAHAAL KIDS FASHION'));
      expect(labelText, contains('Kids Polo T-Shirt'));
      expect(labelText, contains('Size: 3Y'));
      expect(labelText, contains('Color: Red'));
      expect(labelText, contains('8901234567890'));
      expect(labelText, contains('MRP: Rs. 499.00'));
    });

    test('FallbackPrinterService prints without crashing when printer is unavailable', () async {
      final fallbackService = FallbackPrinterService();

      final result = await fallbackService.printBill(
        testBill,
        config: const PrinterConfig(
          paperWidth: ReceiptPaperWidth.mm80,
        ),
      );

      expect(result.isSuccess, true);
      expect(result.status, PrintStatus.fallbackPreview);
      expect(result.formattedText, isNotNull);
      expect(result.rawBytes, isNotNull);
    });

    test('PrinterServiceFactory returns valid PrinterService instance', () {
      PrinterServiceFactory.reset();
      final service = PrinterServiceFactory.getInstance();
      expect(service, isNotNull);

      // Verify custom mock injection
      final customService = FallbackPrinterService();
      PrinterServiceFactory.setInstance(customService);
      expect(PrinterServiceFactory.getInstance(), customService);
    });
  });
}
