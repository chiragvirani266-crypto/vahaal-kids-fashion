import 'package:flutter/material.dart';
import '../../models/bill_model.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import 'printer_models.dart';

/// Core Abstraction for Cross-Platform Thermal Printing & Barcode Label Generation
abstract class PrinterService {
  /// Prints a customer sales invoice / bill
  Future<PrintResult> printBill(
    Bill bill, {
    PrinterConfig? config,
    bool isReprint = false,
  });

  /// Prints a barcode sticker / price tag label for a product variant
  Future<PrintResult> printLabel(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  });

  /// Displays an interactive print preview and configuration modal
  void showPrintPreview(
    BuildContext context, {
    Bill? bill,
    ProductVariant? variant,
    Product? product,
    bool isReprint = false,
    PrinterConfig? initialConfig,
    VoidCallback? onPrintCompleted,
  });

  /// Checks whether a printer target is reachable
  Future<bool> isPrinterAvailable({PrinterConfig? config});

  /// Discovers network / local thermal printers
  Future<List<String>> getDiscoveredPrinters();
}
