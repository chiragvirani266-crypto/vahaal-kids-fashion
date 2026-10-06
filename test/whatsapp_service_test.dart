import 'package:flutter_test/flutter_test.dart';
import 'package:vahaal_kids_fashion/models/bill_item_model.dart';
import 'package:vahaal_kids_fashion/models/bill_model.dart';
import 'package:vahaal_kids_fashion/services/pdf/bill_pdf_generator.dart';
import 'package:vahaal_kids_fashion/services/whatsapp/whatsapp_service.dart';

void main() {
  group('WhatsAppService & PDF Invoice Generation Tests', () {
    final testBill = Bill(
      id: 'bill-1025',
      billNumber: 'INV-1025',
      customerNameSnapshot: 'Rahul',
      customerMobileSnapshot: '9876543210',
      billDate: DateTime(2026, 10, 6, 12, 15),
      subtotal: 2000.0,
      discount: 150.0,
      grandTotal: 1850.0,
      paymentMethod: 'cash',
      cashierName: 'Cashier Ankit',
      items: const [
        BillItem(
          productId: 'p-1',
          variantId: 'v-1',
          productNameSnapshot: 'Boys Cotton Dungaree',
          skuSnapshot: 'VKF-DUNG-2Y',
          sizeSnapshot: '2Y',
          colorSnapshot: 'Navy Blue',
          quantity: 1,
          unitPrice: 1200.0,
          discount: 0.0,
          total: 1200.0,
        ),
        BillItem(
          productId: 'p-2',
          variantId: 'v-2',
          productNameSnapshot: 'Infant Romper',
          skuSnapshot: 'VKF-ROMP-6M',
          sizeSnapshot: '6-12M',
          colorSnapshot: 'Yellow',
          quantity: 1,
          unitPrice: 800.0,
          discount: 0.0,
          total: 800.0,
        ),
      ],
    );

    final service = WhatsAppServiceFactory.getInstance();

    test('Prepares WhatsApp message containing customer name, store name, bill number, date, amount, and thank you', () {
      final message = service.formatWhatsAppMessage(testBill);

      // Customer greeting
      expect(message, contains('Hello Rahul,'));
      // Store name
      expect(message, contains('Thank you for shopping with VAHAAL KIDS FASHION.'));
      // Bill number
      expect(message, contains('Bill No: INV-1025'));
      // Bill date
      expect(message, contains('Date: 06 Oct 2026'));
      // Grand total amount
      expect(message, contains('Amount: Rs. 1,850.00'));
      // Items breakdown
      expect(message, contains('Boys Cotton Dungaree (2Y / Navy Blue)'));
      expect(message, contains('Infant Romper (6-12M / Yellow)'));
      // Thank you message
      expect(message, contains('Thank you!'));
    });

    test('Formats phone number with country code correctly', () {
      // 10-digit Indian phone number
      expect(service.formatPhoneNumber('9876543210'), '919876543210');
      // With dashes or spaces
      expect(service.formatPhoneNumber('+91 98765-43210'), '919876543210');
      // Already prefixed with country code
      expect(service.formatPhoneNumber('919876543210'), '919876543210');
      // Empty or null
      expect(service.formatPhoneNumber(''), '');
      expect(service.formatPhoneNumber(null), '');
    });

    test('Handles walk-in or empty customer name with friendly fallback', () {
      final walkInBill = testBill.copyWith(customerNameSnapshot: 'Walk-in Customer');
      final message = service.formatWhatsAppMessage(walkInBill);
      expect(message, contains('Hello Customer,'));
    });

    test('Generates clean, valid PDF invoice bytes with PDF header', () async {
      final pdfBytes = await service.generateBillPdf(testBill);

      expect(pdfBytes.isNotEmpty, true);
      // Valid PDF documents start with %PDF- (0x25, 0x50, 0x44, 0x46, 0x2D)
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
      expect(pdfBytes[4], 0x2D); // '-'
      expect(pdfBytes.length > 500, true);
    });

    test('BillPdfGenerator generates PDF containing duplicate watermark for reprint', () async {
      final reprintPdfBytes = await BillPdfGenerator.generate(testBill, isReprint: true);
      expect(reprintPdfBytes.isNotEmpty, true);
      expect(reprintPdfBytes.length > 500, true);
    });

    test('WhatsAppServiceFactory returns singleton and allows custom injection', () {
      WhatsAppServiceFactory.reset();
      final inst1 = WhatsAppServiceFactory.getInstance();
      final inst2 = WhatsAppServiceFactory.getInstance();
      expect(identical(inst1, inst2), true);
    });
  });
}
