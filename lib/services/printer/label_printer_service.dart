import 'dart:io';
import 'dart:typed_data';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';
import 'formatters/code128_encoder.dart';
import 'formatters/thermal_receipt_formatter.dart';
import 'printer_models.dart';
import 'printer_service_factory.dart';

/// Clean Service Abstraction for Barcode & Garment Price Tag Printing
abstract class LabelPrinterService {
  /// Generate monospaced preview text for a single variant label
  String formatLabelText(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  });

  /// Generate monospaced preview text for a batch of multiple selected variants
  String formatBatchLabelsText(
    List<LabelPrintItem> items, {
    LabelConfig? config,
  });

  /// Generate raw ESC/POS bytes for a single label
  Uint8List formatLabelEscPos(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  });

  /// Generate raw ESC/POS bytes for multiple copies of a label
  Uint8List formatMultipleLabelsEscPos(
    ProductVariant variant, {
    Product? product,
    int copies = 1,
    LabelConfig? config,
  });

  /// Generate raw ESC/POS bytes for a batch of multiple selected variants
  Uint8List formatBatchLabelsEscPos(
    List<LabelPrintItem> items, {
    LabelConfig? config,
  });

  /// Generates 1D barcode binary modules (true = bar, false = space) using Code 128
  List<bool> generateBarcodeModules(String data, {int quietZone = 10});

  /// Prints a single label for a variant
  Future<PrintResult> printSingleLabel(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
    PrinterConfig? printerConfig,
  });

  /// Prints multiple copies of a single variant label
  Future<PrintResult> printMultipleLabels(
    ProductVariant variant, {
    Product? product,
    int quantity = 1,
    LabelConfig? config,
    PrinterConfig? printerConfig,
  });

  /// Prints batch labels across multiple selected variants with their respective quantities
  Future<PrintResult> printBatchLabels(
    List<LabelPrintItem> items, {
    LabelConfig? config,
    PrinterConfig? printerConfig,
  });

  /// Checks if printer is available/reachable
  Future<bool> isPrinterAvailable({PrinterConfig? config});
}

/// Standard Implementation of LabelPrinterService
class StandardLabelPrinterService implements LabelPrinterService {
  @override
  String formatLabelText(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  }) {
    return ThermalReceiptFormatter.formatVariantLabelText(
      variant,
      product: product,
      config: config ?? const LabelConfig(),
    );
  }

  @override
  String formatBatchLabelsText(
    List<LabelPrintItem> items, {
    LabelConfig? config,
  }) {
    return ThermalReceiptFormatter.formatBatchLabelsText(
      items,
      config: config ?? const LabelConfig(),
    );
  }

  @override
  Uint8List formatLabelEscPos(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
  }) {
    return ThermalReceiptFormatter.formatVariantLabelEscPos(
      variant,
      product: product,
      config: config ?? const LabelConfig(),
    );
  }

  @override
  Uint8List formatMultipleLabelsEscPos(
    ProductVariant variant, {
    Product? product,
    int copies = 1,
    LabelConfig? config,
  }) {
    return ThermalReceiptFormatter.formatMultipleVariantLabelsEscPos(
      variant,
      product: product,
      copies: copies,
      config: config ?? const LabelConfig(),
    );
  }

  @override
  Uint8List formatBatchLabelsEscPos(
    List<LabelPrintItem> items, {
    LabelConfig? config,
  }) {
    return ThermalReceiptFormatter.formatBatchLabelsEscPos(
      items,
      config: config ?? const LabelConfig(),
    );
  }

  @override
  List<bool> generateBarcodeModules(String data, {int quietZone = 10}) {
    return Code128Encoder.encodeToModules(data, quietZoneModules: quietZone);
  }

  @override
  Future<PrintResult> printSingleLabel(
    ProductVariant variant, {
    Product? product,
    LabelConfig? config,
    PrinterConfig? printerConfig,
  }) {
    return printMultipleLabels(
      variant,
      product: product,
      quantity: 1,
      config: config,
      printerConfig: printerConfig,
    );
  }

  @override
  Future<PrintResult> printMultipleLabels(
    ProductVariant variant, {
    Product? product,
    int quantity = 1,
    LabelConfig? config,
    PrinterConfig? printerConfig,
  }) async {
    final effectiveQuantity = quantity <= 0 ? 1 : quantity;
    final effectiveConfig = config ?? const LabelConfig();
    final effectivePrinterConfig = printerConfig ?? const PrinterConfig();

    final item = LabelPrintItem(
      variant: variant,
      product: product ??
          Product(
            id: variant.productId,
            sku: variant.sku,
            productName: 'Product Item',
            category: 'Garments',
            gender: 'Unisex',
            purchasePrice: 0,
            sellingPrice: variant.sellingPrice ?? 0,
          ),
      quantity: effectiveQuantity,
      isSelected: true,
    );

    return printBatchLabels(
      [item],
      config: effectiveConfig,
      printerConfig: effectivePrinterConfig,
    );
  }

  @override
  Future<PrintResult> printBatchLabels(
    List<LabelPrintItem> items, {
    LabelConfig? config,
    PrinterConfig? printerConfig,
  }) async {
    final effectiveConfig = config ?? const LabelConfig();
    final effectivePrinterConfig = printerConfig ?? const PrinterConfig();

    final selectedItems = items.where((i) => i.isSelected && i.quantity > 0).toList();
    if (selectedItems.isEmpty) {
      return PrintResult.failed('No labels selected for printing.');
    }

    final totalLabels = selectedItems.fold<int>(0, (sum, i) => sum + i.quantity);
    final batchBytes = formatBatchLabelsEscPos(selectedItems, config: effectiveConfig);
    final previewText = formatBatchLabelsText(selectedItems, config: effectiveConfig);

    // 1. Direct Network Socket Print (Ethernet / Wi-Fi Thermal Printer)
    if (effectivePrinterConfig.connectionType == PrinterConnectionType.network &&
        effectivePrinterConfig.ipAddress != null &&
        effectivePrinterConfig.ipAddress!.isNotEmpty) {
      try {
        final socket = await Socket.connect(
          effectivePrinterConfig.ipAddress!,
          effectivePrinterConfig.port,
          timeout: const Duration(seconds: 4),
        );
        socket.add(batchBytes);
        await socket.flush();
        await socket.close();

        return PrintResult.success(
          message: 'Printed $totalLabels barcode labels across ${selectedItems.length} variant(s) on ${effectivePrinterConfig.ipAddress}:${effectivePrinterConfig.port}.',
          rawBytes: batchBytes,
          formattedText: previewText,
        );
      } catch (e) {
        return PrintResult.fallback(
          message: 'Printer unreachable at ${effectivePrinterConfig.ipAddress}: $e',
          formattedText: previewText,
          rawBytes: batchBytes,
        );
      }
    }

    // 2. Windows Spooler / Platform Printer
    if (Platform.isWindows &&
        effectivePrinterConfig.connectionType == PrinterConnectionType.windowsSpooler) {
      final printerService = PrinterServiceFactory.getInstance();
      final sampleVariant = selectedItems.first.variant;
      final result = await printerService.printLabel(
        sampleVariant,
        product: selectedItems.first.product,
        config: effectiveConfig,
      );

      return PrintResult(
        isSuccess: result.isSuccess,
        status: result.status,
        message: 'Spooling $totalLabels barcode labels across ${selectedItems.length} variant(s) to Windows printer.',
        rawBytes: batchBytes,
        formattedText: previewText,
      );
    }

    // 3. System Default / Fallback Mode
    return PrintResult.fallback(
      message: 'Generated $totalLabels barcode labels across ${selectedItems.length} variant(s). Ready for thermal printing / export.',
      rawBytes: batchBytes,
      formattedText: previewText,
    );
  }

  @override
  Future<bool> isPrinterAvailable({PrinterConfig? config}) async {
    final cfg = config ?? const PrinterConfig();
    if (cfg.connectionType == PrinterConnectionType.network &&
        cfg.ipAddress != null &&
        cfg.ipAddress!.isNotEmpty) {
      try {
        final socket = await Socket.connect(
          cfg.ipAddress!,
          cfg.port,
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
}

/// Factory & Service Locator for LabelPrinterService
class LabelPrinterServiceFactory {
  static LabelPrinterService? _instance;

  static LabelPrinterService getInstance() {
    _instance ??= StandardLabelPrinterService();
    return _instance!;
  }

  static void setInstance(LabelPrinterService service) {
    _instance = service;
  }

  static void reset() {
    _instance = null;
  }
}
