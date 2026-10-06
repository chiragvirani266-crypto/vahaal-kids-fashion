import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_constants.dart';
import '../models/bill_model.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';
import '../theme/app_colors.dart';
import 'printer/printer_models.dart';
import 'printer/printer_service_factory.dart';
import 'whatsapp/whatsapp_service.dart';

class ReceiptService {
  /// Formats the bill into clean text for WhatsApp, clipboard, or SMS sharing
  static String formatBillText(Bill bill, {bool isReprint = false}) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🛍️ *${AppConstants.storeName}*');
    buffer.writeln(AppConstants.storeTagline);
    if (isReprint) {
      buffer.writeln('⚠️ *[REPRINTED DUPLICATE INVOICE]*');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('🧾 *Invoice:* ${bill.billNumber}');
    buffer.writeln('📅 *Date:* $formattedDate');
    buffer.writeln('👤 *Customer:* ${bill.displayCustomerName}');
    if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty) {
      buffer.writeln('📱 *Mobile:* ${bill.customerMobileSnapshot}');
    }
    if (bill.cashierName != null && bill.cashierName!.isNotEmpty) {
      buffer.writeln('👨‍💼 *Cashier:* ${bill.cashierName}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*PURCHASED ITEMS:*');

    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      buffer.writeln(
        '${i + 1}. *${item.productNameSnapshot}*',
      );
      buffer.writeln(
        '   Variant: ${item.variantDescription}',
      );
      buffer.writeln(
        '   Qty: ${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ₹${bill.subtotal.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      buffer.writeln('Discount: -₹${bill.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('*Grand Total: ₹${bill.grandTotal.toStringAsFixed(2)}*');
    buffer.writeln('Payment Method: ${bill.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('✨ ${AppConstants.storeThankYou}');
    buffer.writeln(AppConstants.storeReturnPolicy);

    return buffer.toString();
  }

  /// Direct WhatsApp share delegating to WhatsAppService
  static Future<void> shareOnWhatsApp(
    BuildContext context,
    Bill bill, {
    bool isReprint = false,
    bool attachPdf = false,
  }) async {
    await WhatsAppServiceFactory.getInstance().shareBill(
      context: context,
      bill: bill,
      attachPdf: attachPdf,
    );
  }

  /// Displays the interactive WhatsApp / PDF share modal dialog
  static void showWhatsAppShareModal(
    BuildContext context,
    Bill bill, {
    VoidCallback? onShareCompleted,
  }) {
    WhatsAppServiceFactory.getInstance().showShareModal(
      context,
      bill,
      onShareCompleted: onShareCompleted,
    );
  }

  /// Copies bill text to clipboard
  static Future<void> copyToClipboard(BuildContext context, Bill bill, {bool isReprint = false}) async {
    final text = formatBillText(bill, isReprint: isReprint);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Bill text copied to clipboard'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the Thermal Receipt Print Preview modal dialog via PrinterService abstraction
  static void showThermalReceipt(
    BuildContext context,
    Bill bill, {
    bool isReprint = false,
    PrinterConfig? initialConfig,
    VoidCallback? onPrintCompleted,
  }) {
    PrinterServiceFactory.getInstance().showPrintPreview(
      context,
      bill: bill,
      isReprint: isReprint,
      initialConfig: initialConfig,
      onPrintCompleted: onPrintCompleted,
    );
  }

  /// Opens the Barcode / Price Tag Sticker Print Preview dialog for a Product Variant
  static void showLabelPrint(
    BuildContext context,
    ProductVariant variant, {
    Product? product,
  }) {
    PrinterServiceFactory.getInstance().showPrintPreview(
      context,
      variant: variant,
      product: product,
    );
  }
}
