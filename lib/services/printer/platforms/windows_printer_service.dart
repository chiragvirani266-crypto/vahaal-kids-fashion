import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/bill_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../formatters/thermal_receipt_formatter.dart';
import '../printer_models.dart';
import '../printer_service.dart';
import '../widgets/printer_preview_dialog.dart';

class WindowsPrinterService implements PrinterService {
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

    // 1. Network Thermal / ESC-POS Direct IP:Port (9100)
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
          message: 'Invoice #${bill.billNumber} sent to Windows network printer (${effectiveConfig.ipAddress}:${effectiveConfig.port}).',
          rawBytes: rawBytes,
          formattedText: formattedText,
        );
      } catch (e) {
        return PrintResult.fallback(
          message: 'Windows network printer unreachable at ${effectiveConfig.ipAddress}: $e',
          formattedText: formattedText,
          rawBytes: rawBytes,
        );
      }
    }

    // 2. Windows Spooler / CLI command (if running on native Windows)
    if (Platform.isWindows && effectiveConfig.printerName != null) {
      try {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/receipt_${bill.billNumber}.txt');
        await tempFile.writeAsString(formattedText);

        // Windows spooler command: Out-Printer or print /d:PrinterName
        final result = await Process.run('powershell', [
          '-Command',
          'Get-Content "${tempFile.path}" | Out-Printer -Name "${effectiveConfig.printerName}"',
        ]);

        if (result.exitCode == 0) {
          return PrintResult.success(
            message: 'Invoice sent to Windows printer "${effectiveConfig.printerName}".',
            rawBytes: rawBytes,
            formattedText: formattedText,
          );
        }
      } catch (_) {
        // Fallback to preview dialog without crashing
      }
    }

    // 3. Fallback Preview
    return PrintResult.fallback(
      message: 'Receipt formatted for Windows desktop print (${effectiveConfig.paperWidth.label}).',
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
      message: 'Barcode label generated for ${variant.sku.isNotEmpty ? variant.sku : "item"}',
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
    if (Platform.isWindows) {
      try {
        final result = await Process.run('powershell', [
          '-Command',
          'Get-Printer | Select-Object -ExpandProperty Name',
        ]);
        if (result.exitCode == 0) {
          final lines = result.stdout.toString().split(RegExp(r'[\r\n]+'));
          return lines.where((s) => s.trim().isNotEmpty).toList();
        }
      } catch (_) {}
    }
    return ['Default Windows Receipt Printer', 'Receipt-80 Thermal USB', 'Receipt-58 Thermal USB'];
  }
}
