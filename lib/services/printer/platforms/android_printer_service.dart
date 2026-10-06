import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/bill_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../formatters/thermal_receipt_formatter.dart';
import '../printer_models.dart';
import '../printer_service.dart';
import '../widgets/printer_preview_dialog.dart';

class AndroidPrinterService implements PrinterService {
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

    // If connection type is network thermal printer
    if (effectiveConfig.connectionType == PrinterConnectionType.network &&
        effectiveConfig.ipAddress != null &&
        effectiveConfig.ipAddress!.isNotEmpty) {
      try {
        final socket = await Socket.connect(
          effectiveConfig.ipAddress!,
          effectiveConfig.port,
          timeout: const Duration(seconds: 4),
        );
        socket.add(rawBytes);
        await socket.flush();
        await socket.close();

        return PrintResult.success(
          message: 'Invoice #${bill.billNumber} sent to Android thermal printer (${effectiveConfig.ipAddress}:${effectiveConfig.port}).',
          rawBytes: rawBytes,
          formattedText: formattedText,
        );
      } catch (e) {
        // Fallback gracefully without breaking billing flow
        return PrintResult.fallback(
          message: 'Android printer unreachable at ${effectiveConfig.ipAddress}: $e',
          formattedText: formattedText,
          rawBytes: rawBytes,
        );
      }
    }

    // Default fallback
    return PrintResult.fallback(
      message: 'Receipt formatted for Android thermal print (${effectiveConfig.paperWidth.label}).',
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
      message: 'Barcode sticker formatted for ${variant.sku.isNotEmpty ? variant.sku : "variant"}',
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
  Future<bool> isPrinterAvailable({PrinterConfig? config}) async {
    if (config?.connectionType == PrinterConnectionType.network &&
        config?.ipAddress != null) {
      try {
        final socket = await Socket.connect(
          config!.ipAddress!,
          config.port,
          timeout: const Duration(seconds: 2),
        );
        await socket.close();
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<List<String>> getDiscoveredPrinters() async {
    return ['Network Thermal POS (9100)', 'Android System Print Spooler'];
  }
}
