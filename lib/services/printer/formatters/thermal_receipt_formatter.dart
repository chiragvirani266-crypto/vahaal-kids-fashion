import 'dart:typed_data';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/bill_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../printer_models.dart';
import 'esc_pos_builder.dart';

class ThermalReceiptFormatter {
  /// Generates human-readable monospaced text for thermal receipt preview & print
  static String formatBillText(
    Bill bill, {
    ReceiptPaperWidth paperWidth = ReceiptPaperWidth.mm80,
    bool isReprint = false,
  }) {
    final cols = paperWidth.columns;
    final buffer = StringBuffer();
    final dividerLine = '-' * cols;
    final doubleDivider = '=' * cols;
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    // Helper: Center text
    String center(String s) {
      if (s.length >= cols) return s.substring(0, cols);
      final leftPad = (cols - s.length) ~/ 2;
      final rightPad = cols - s.length - leftPad;
      return (' ' * leftPad) + s + (' ' * rightPad);
    }

    // Helper: Two-column row (Left label, Right value)
    String row2(String left, String right) {
      if (left.length + right.length >= cols) {
        final maxLeft = cols - right.length - 1;
        if (maxLeft > 0) {
          left = left.substring(0, maxLeft);
        }
      }
      final space = cols - left.length - right.length;
      return left + (' ' * (space > 0 ? space : 1)) + right;
    }

    // 1. REPRINT WATERMARK (If applicable)
    if (isReprint) {
      buffer.writeln(center('*** DUPLICATE REPRINT COPY ***'));
      buffer.writeln(dividerLine);
    }

    // 2. STORE HEADER
    buffer.writeln(center(AppConstants.storeName));
    buffer.writeln(center(AppConstants.storeTagline));
    buffer.writeln(center(AppConstants.storeAddress));
    buffer.writeln(center('Tel: ${AppConstants.storeMobile} | GST: ${AppConstants.storeGstin}'));
    buffer.writeln(doubleDivider);

    // 3. INVOICE META
    buffer.writeln(row2('Bill Number:', bill.billNumber));
    buffer.writeln(row2('Date & Time:', dateFormat.format(bill.billDate)));
    buffer.writeln(row2('Customer:', bill.displayCustomerName));
    if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty) {
      buffer.writeln(row2('Mobile:', bill.customerMobileSnapshot!));
    }
    if (bill.cashierName != null && bill.cashierName!.isNotEmpty) {
      buffer.writeln(row2('Cashier:', bill.cashierName!));
    }

    // 4. ITEM TABLE HEADER
    buffer.writeln(dividerLine);
    if (paperWidth == ReceiptPaperWidth.mm80) {
      // 48 columns format: Item (22), Qty (5), Price (9), Amount (12)
      buffer.writeln(
        'Item Description'.padRight(22) +
            'Qty'.padLeft(5) +
            'Price'.padLeft(9) +
            'Amount'.padLeft(12),
      );
    } else {
      // 32 columns format: Item (14), Qty (4), Price (6), Amount (8)
      buffer.writeln(
        'Item'.padRight(14) +
            'Qty'.padLeft(4) +
            'Price'.padLeft(6) +
            'Amount'.padLeft(8),
      );
    }
    buffer.writeln(dividerLine);

    // 5. ITEM ROWS
    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      final title = '${i + 1}. ${item.productNameSnapshot}';
      final variantDesc = '   (${item.variantDescription})';

      buffer.writeln(title);
      if (item.variantDescription.isNotEmpty) {
        buffer.writeln(variantDesc);
      }

      final qtyStr = '${item.quantity}';
      final priceStr = item.unitPrice.toStringAsFixed(2);
      final totalStr = item.total.toStringAsFixed(2);

      if (paperWidth == ReceiptPaperWidth.mm80) {
        buffer.writeln(
          ''.padRight(22) +
              qtyStr.padLeft(5) +
              priceStr.padLeft(9) +
              totalStr.padLeft(12),
        );
      } else {
        buffer.writeln(
          ''.padRight(14) +
              qtyStr.padLeft(4) +
              priceStr.padLeft(6) +
              totalStr.padLeft(8),
        );
      }
    }

    // 6. TOTALS & FINANCIAL SUMMARY
    buffer.writeln(doubleDivider);
    buffer.writeln(row2('Subtotal:', 'Rs. ${bill.subtotal.toStringAsFixed(2)}'));
    if (bill.discount > 0) {
      buffer.writeln(row2('Discount:', '-Rs. ${bill.discount.toStringAsFixed(2)}'));
    }
    buffer.writeln(row2('GRAND TOTAL:', 'Rs. ${bill.grandTotal.toStringAsFixed(2)}'));
    buffer.writeln(row2('Payment Method:', bill.paymentMethod.toUpperCase()));
    buffer.writeln(row2('Total Items / Units:', '${bill.totalItemsCount} / ${bill.totalUnitsCount}'));

    if (bill.notes != null && bill.notes!.isNotEmpty) {
      buffer.writeln(dividerLine);
      buffer.writeln('Notes: ${bill.notes}');
    }

    // 7. FOOTER
    buffer.writeln(dividerLine);
    buffer.writeln(center(AppConstants.storeThankYou));
    buffer.writeln(center(AppConstants.storeReturnPolicy));
    buffer.writeln(dividerLine);

    return buffer.toString();
  }

  /// Generates raw binary ESC/POS byte sequence for hardware thermal printers
  static Uint8List formatBillEscPos(
    Bill bill, {
    PrinterConfig config = const PrinterConfig(),
    bool isReprint = false,
  }) {
    final builder = EscPosBuilder(paperWidth: config.paperWidth);
    builder.initialize();

    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');

    // 1. Kick cash drawer if configured
    if (config.openCashDrawer) {
      builder.openCashDrawer();
    }

    // 2. Reprint header
    if (isReprint) {
      builder.textLine('*** DUPLICATE REPRINT COPY ***', align: 1, bold: true);
      builder.divider();
    }

    // 3. Store Header (Center, Large)
    builder.textLine(AppConstants.storeName, align: 1, bold: true, doubleHeight: true, doubleWidth: true);
    builder.textLine(AppConstants.storeTagline, align: 1);
    builder.textLine(AppConstants.storeAddress, align: 1);
    builder.textLine('Tel: ${AppConstants.storeMobile} | GST: ${AppConstants.storeGstin}', align: 1);
    builder.divider(char: '=');

    // 4. Meta Information
    builder.row2('Bill Number:', bill.billNumber, bold: true);
    builder.row2('Date & Time:', dateFormat.format(bill.billDate));
    builder.row2('Customer:', bill.displayCustomerName);
    if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty) {
      builder.row2('Mobile:', bill.customerMobileSnapshot!);
    }
    if (bill.cashierName != null && bill.cashierName!.isNotEmpty) {
      builder.row2('Cashier:', bill.cashierName!);
    }

    // 5. Items Header
    builder.divider();
    if (config.paperWidth == ReceiptPaperWidth.mm80) {
      builder.textLine(
        'Item Description'.padRight(22) +
            'Qty'.padLeft(5) +
            'Price'.padLeft(9) +
            'Amount'.padLeft(12),
        bold: true,
      );
    } else {
      builder.textLine(
        'Item'.padRight(14) +
            'Qty'.padLeft(4) +
            'Price'.padLeft(6) +
            'Amount'.padLeft(8),
        bold: true,
      );
    }
    builder.divider();

    // 6. Items
    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      builder.textLine('${i + 1}. ${item.productNameSnapshot}', bold: true);
      if (item.variantDescription.isNotEmpty) {
        builder.textLine('   (${item.variantDescription})');
      }

      final qtyStr = '${item.quantity}';
      final priceStr = item.unitPrice.toStringAsFixed(2);
      final totalStr = item.total.toStringAsFixed(2);

      if (config.paperWidth == ReceiptPaperWidth.mm80) {
        builder.textLine(
          ''.padRight(22) +
              qtyStr.padLeft(5) +
              priceStr.padLeft(9) +
              totalStr.padLeft(12),
        );
      } else {
        builder.textLine(
          ''.padRight(14) +
              qtyStr.padLeft(4) +
              priceStr.padLeft(6) +
              totalStr.padLeft(8),
        );
      }
    }

    // 7. Totals
    builder.divider(char: '=');
    builder.row2('Subtotal:', 'Rs. ${bill.subtotal.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      builder.row2('Discount:', '-Rs. ${bill.discount.toStringAsFixed(2)}');
    }
    builder.row2('GRAND TOTAL:', 'Rs. ${bill.grandTotal.toStringAsFixed(2)}', bold: true);
    builder.row2('Payment Method:', bill.paymentMethod.toUpperCase());
    builder.row2('Units Count:', '${bill.totalUnitsCount}');

    if (bill.notes != null && bill.notes!.isNotEmpty) {
      builder.divider();
      builder.textLine('Notes: ${bill.notes}');
    }

    // 8. Footer & Barcode
    builder.divider();
    builder.textLine(AppConstants.storeThankYou, align: 1, bold: true);
    builder.textLine(AppConstants.storeReturnPolicy, align: 1);
    builder.feed(1);
    builder.printBarcode(bill.billNumber);

    // 9. Cut & Beep
    if (config.beepOnFinish) {
      builder.beep();
    }
    if (config.autoCut) {
      builder.cut();
    }

    return builder.build();
  }

  /// Formats a barcode price-tag sticker for a Product Variant
  static String formatVariantLabelText(
    ProductVariant variant, {
    Product? product,
    LabelConfig config = const LabelConfig(),
  }) {
    final buffer = StringBuffer();
    final cols = config.preset == LabelSizePreset.roll80mm ? 48 : 32;

    String center(String s) {
      if (s.length >= cols) return s.substring(0, cols);
      final leftPad = (cols - s.length) ~/ 2;
      final rightPad = cols - s.length - leftPad;
      return (' ' * leftPad) + s + (' ' * rightPad);
    }

    if (config.showStoreName) {
      final store = config.storeNameOverride?.isNotEmpty == true
          ? config.storeNameOverride!
          : AppConstants.storeName;
      buffer.writeln(center(store));
      buffer.writeln('-' * cols);
    }

    if (config.showProductName) {
      final productName = product?.productName ?? 'Kidswear Apparel';
      buffer.writeln(center(productName));
    }

    if (config.showSizeAndColor) {
      buffer.writeln(center('Size: ${variant.size}  |  Color: ${variant.color}'));
    }

    if (config.showSku) {
      final sku = variant.sku.isNotEmpty ? variant.sku : (product?.sku ?? '');
      if (sku.isNotEmpty) {
        buffer.writeln(center('SKU: $sku'));
      }
    }

    final barcode = variant.barcode.isNotEmpty ? variant.barcode : (product?.barcode ?? variant.sku);
    if (config.showBarcode && barcode.isNotEmpty) {
      buffer.writeln(center('||| |||| ||||| |||| |||'));
      buffer.writeln(center(barcode));
    }

    final price = variant.sellingPrice ?? product?.sellingPrice ?? 0.0;
    if (config.showPrice && price > 0) {
      buffer.writeln(center('MRP: ${config.currencySymbol} ${price.toStringAsFixed(2)}'));
      buffer.writeln(center('(Incl. of all taxes)'));
    }

    return buffer.toString();
  }

  /// Formats multiple copies of labels into a single monospaced preview
  static String formatBatchLabelsText(
    List<LabelPrintItem> items, {
    LabelConfig config = const LabelConfig(),
  }) {
    final buffer = StringBuffer();
    final selectedItems = items.where((i) => i.isSelected && i.quantity > 0).toList();

    if (selectedItems.isEmpty) {
      return 'No labels selected for preview.';
    }

    for (int idx = 0; idx < selectedItems.length; idx++) {
      final item = selectedItems[idx];
      buffer.writeln('=== BATCH ITEM ${idx + 1}/${selectedItems.length} (Qty: ${item.quantity}) ===');
      buffer.writeln(formatVariantLabelText(
        item.variant,
        product: item.product,
        config: config,
      ));
      if (idx < selectedItems.length - 1) {
        buffer.writeln('\n${'*' * 32}\n');
      }
    }

    return buffer.toString();
  }

  /// Generates ESC/POS bytes for Barcode Price Tag Label
  static Uint8List formatVariantLabelEscPos(
    ProductVariant variant, {
    Product? product,
    LabelConfig config = const LabelConfig(),
  }) {
    final paperWidth = config.preset == LabelSizePreset.roll80mm
        ? ReceiptPaperWidth.mm80
        : ReceiptPaperWidth.mm58;

    final builder = EscPosBuilder(paperWidth: paperWidth);
    builder.initialize();

    if (config.showStoreName) {
      final store = config.storeNameOverride?.isNotEmpty == true
          ? config.storeNameOverride!
          : AppConstants.storeName;
      builder.textLine(store, align: 1, bold: true);
      builder.divider();
    }

    if (config.showProductName) {
      final productName = product?.productName ?? 'Kidswear Item';
      builder.textLine(productName, align: 1, bold: true);
    }

    if (config.showSizeAndColor) {
      builder.textLine('Size: ${variant.size}  |  Color: ${variant.color}', align: 1);
    }

    if (config.showSku) {
      final sku = variant.sku.isNotEmpty ? variant.sku : (product?.sku ?? '');
      if (sku.isNotEmpty) {
        builder.textLine('SKU: $sku', align: 1);
      }
    }

    final barcode = variant.barcode.isNotEmpty ? variant.barcode : (product?.barcode ?? variant.sku);
    if (config.showBarcode && barcode.isNotEmpty) {
      builder.printBarcode(barcode, height: 50, width: 2);
    }

    final price = variant.sellingPrice ?? product?.sellingPrice ?? 0.0;
    if (config.showPrice && price > 0) {
      builder.textLine(
        'MRP: ${config.currencySymbol} ${price.toStringAsFixed(2)}',
        align: 1,
        bold: true,
        doubleHeight: true,
      );
      builder.textLine('(Incl. of all taxes)', align: 1);
    }

    builder.feed(2);
    builder.cut(partial: true);

    return builder.build();
  }

  /// Generates ESC/POS bytes for multiple copies of a single variant
  static Uint8List formatMultipleVariantLabelsEscPos(
    ProductVariant variant, {
    Product? product,
    int copies = 1,
    LabelConfig config = const LabelConfig(),
  }) {
    final effectiveCopies = copies <= 0 ? 1 : copies;
    final List<int> combinedBytes = [];

    for (int i = 0; i < effectiveCopies; i++) {
      final labelBytes = formatVariantLabelEscPos(
        variant,
        product: product,
        config: config,
      );
      combinedBytes.addAll(labelBytes);
    }

    return Uint8List.fromList(combinedBytes);
  }

  /// Generates ESC/POS bytes for a batch of multiple selected variants
  static Uint8List formatBatchLabelsEscPos(
    List<LabelPrintItem> items, {
    LabelConfig config = const LabelConfig(),
  }) {
    final List<int> combinedBytes = [];
    final selectedItems = items.where((i) => i.isSelected && i.quantity > 0);

    for (final item in selectedItems) {
      for (int c = 0; c < item.quantity; c++) {
        final labelBytes = formatVariantLabelEscPos(
          item.variant,
          product: item.product,
          config: config,
        );
        combinedBytes.addAll(labelBytes);
      }
    }

    return Uint8List.fromList(combinedBytes);
  }
}
