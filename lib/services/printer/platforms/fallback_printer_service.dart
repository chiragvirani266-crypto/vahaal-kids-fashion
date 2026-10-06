import 'package:flutter/material.dart';
import '../../../models/bill_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../formatters/thermal_receipt_formatter.dart';
import '../printer_models.dart';
import '../printer_service.dart';
import '../widgets/printer_preview_dialog.dart';

class FallbackPrinterService implements PrinterService {
  @override
  Future<PrintResult> printBill(
    Bill bill, {
    PrinterConfig? config,
    bool isReprint = false,
  }) async {
    final effectiveConfig = config ?? const PrinterConfig();
    final rawBytes = ThermalReceiptFormatter.formatBillEscPos(
      bill,
      config: effectiveConfig,
      isReprint: isReprint,
    );
    final formattedText = ThermalReceiptFormatter.formatBillText(
      bill,
      paperWidth: effectiveConfig.paperWidth,
      isReprint: isReprint,
    );

    return PrintResult.fallback(
      message: 'Receipt ready in print preview (${effectiveConfig.paperWidth.label}).',
      formattedText: formattedText,
      rawBytes: rawBytes,
    );
  }

  @override
  Future<PrintResult> printLabel(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  }) async {
    final effectiveConfig = config ?? const LabelConfig();
    final rawBytes = ThermalReceiptFormatter.formatVariantLabelEscPos(
      variant,
      product: product,
      config: effectiveConfig,
    );
    final formattedText = ThermalReceiptFormatter.formatVariantLabelText(
      variant,
      product: product,
      config: effectiveConfig,
    );

    return PrintResult.success(
      message: 'Barcode sticker formatted (${variant.displayName})',
      rawBytes: rawBytes,
      formattedText: formattedText,
    );
  }

  @override
  void showPrintPreview(
    BuildContext context, {
    Bill? bill,
    ProductVariant? variant,
    Product? product,
    bool isReprint = false,
    PrinterConfig? initialConfig,
    VoidCallback? onPrintCompleted,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PrinterPreviewDialog(
        printerService: this,
        bill: bill,
        variant: variant,
        product: product,
        isReprint: isReprint,
        initialConfig: initialConfig,
        onPrintCompleted: onPrintCompleted,
      ),
    );
  }

  @override
  Future<bool> isPrinterAvailable({PrinterConfig? config}) async => true;

  @override
  Future<List<String>> getDiscoveredPrinters() async {
    return ['Virtual Thermal POS Emulator', 'System Preview'];
  }
}
