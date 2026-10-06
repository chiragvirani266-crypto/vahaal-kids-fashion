import 'package:flutter/foundation.dart';
import '../../models/product_model.dart';
import '../../models/product_variant_model.dart';

/// Supported receipt paper widths
enum ReceiptPaperWidth {
  mm58(32, 384, '58mm (Small Thermal)'),
  mm80(48, 576, '80mm (Standard POS)');

  final int columns;
  final int dotsPerLine;
  final String label;

  const ReceiptPaperWidth(this.columns, this.dotsPerLine, this.label);
}

/// Supported printer communication channels
enum PrinterConnectionType {
  network('Network / Ethernet (LAN / Wi-Fi)'),
  windowsSpooler('Windows Print Spooler / USB'),
  bluetooth('Bluetooth Thermal'),
  usb('Direct USB / COM Port'),
  systemDefault('System Print Dialog / Fallback');

  final String label;
  const PrinterConnectionType(this.label);
}

/// Print execution status
enum PrintStatus {
  success,
  failed,
  cancelled,
  fallbackPreview,
  simulated,
}

/// Configuration settings for thermal receipt printing
class PrinterConfig {
  final ReceiptPaperWidth paperWidth;
  final PrinterConnectionType connectionType;
  final String? ipAddress;
  final int port;
  final String? printerName;
  final bool autoCut;
  final bool openCashDrawer;
  final int copies;
  final bool beepOnFinish;

  const PrinterConfig({
    this.paperWidth = ReceiptPaperWidth.mm80,
    this.connectionType = PrinterConnectionType.systemDefault,
    this.ipAddress = '192.168.1.100',
    this.port = 9100,
    this.printerName,
    this.autoCut = true,
    this.openCashDrawer = false,
    this.copies = 1,
    this.beepOnFinish = false,
  });

  PrinterConfig copyWith({
    ReceiptPaperWidth? paperWidth,
    PrinterConnectionType? connectionType,
    String? ipAddress,
    int? port,
    String? printerName,
    bool? autoCut,
    bool? openCashDrawer,
    int? copies,
    bool? beepOnFinish,
  }) {
    return PrinterConfig(
      paperWidth: paperWidth ?? this.paperWidth,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      printerName: printerName ?? this.printerName,
      autoCut: autoCut ?? this.autoCut,
      openCashDrawer: openCashDrawer ?? this.openCashDrawer,
      copies: copies ?? this.copies,
      beepOnFinish: beepOnFinish ?? this.beepOnFinish,
    );
  }

  Map<String, dynamic> toJson() => {
        'paper_width': paperWidth.name,
        'connection_type': connectionType.name,
        'ip_address': ipAddress,
        'port': port,
        'printer_name': printerName,
        'auto_cut': autoCut,
        'open_cash_drawer': openCashDrawer,
        'copies': copies,
        'beep_on_finish': beepOnFinish,
      };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) {
    return PrinterConfig(
      paperWidth: json['paper_width'] == 'mm58' ? ReceiptPaperWidth.mm58 : ReceiptPaperWidth.mm80,
      connectionType: PrinterConnectionType.values.firstWhere(
        (e) => e.name == json['connection_type'],
        orElse: () => PrinterConnectionType.systemDefault,
      ),
      ipAddress: json['ip_address'] as String? ?? '192.168.1.100',
      port: json['port'] as int? ?? 9100,
      printerName: json['printer_name'] as String?,
      autoCut: json['auto_cut'] as bool? ?? true,
      openCashDrawer: json['open_cash_drawer'] as bool? ?? false,
      copies: json['copies'] as int? ?? 1,
      beepOnFinish: json['beep_on_finish'] as bool? ?? false,
    );
  }
}

/// Presets for barcode sticker and garment price tag sizes
enum LabelSizePreset {
  standard50x25(50.0, 25.0, '50mm × 25mm (Standard 2"×1")', 'Most common garment adhesive sticker'),
  compact38x25(38.0, 25.0, '38mm × 25mm (Compact 1.5"×1")', 'Accessories, jewelry & small items'),
  large50x38(50.0, 38.0, '50mm × 38mm (Large 2"×1.5")', 'Detailed garment hang tag with size & care'),
  roll58mm(58.0, 35.0, '58mm Continuous Roll', 'Standard 2-inch thermal roll printer'),
  roll80mm(80.0, 45.0, '80mm Continuous Roll', 'Standard 3-inch POS thermal printer'),
  custom(50.0, 25.0, 'Custom Dimensions', 'User-defined width & height in mm');

  final double defaultWidthMm;
  final double defaultHeightMm;
  final String label;
  final String description;

  const LabelSizePreset(
    this.defaultWidthMm,
    this.defaultHeightMm,
    this.label,
    this.description,
  );
}

/// Configuration for barcode / price tag sticker printing
class LabelConfig {
  final LabelSizePreset preset;
  final double widthMm;
  final double heightMm;
  final bool showStoreName;
  final bool showProductName;
  final bool showBarcode;
  final bool showPrice;
  final bool showSizeAndColor;
  final bool showSku;
  final String? storeNameOverride;
  final String currencySymbol;
  final int copies;

  const LabelConfig({
    this.preset = LabelSizePreset.standard50x25,
    this.widthMm = 50.0,
    this.heightMm = 25.0,
    this.showStoreName = true,
    this.showProductName = true,
    this.showBarcode = true,
    this.showPrice = true,
    this.showSizeAndColor = true,
    this.showSku = true,
    this.storeNameOverride,
    this.currencySymbol = 'Rs.',
    this.copies = 1,
  });

  LabelConfig copyWith({
    LabelSizePreset? preset,
    double? widthMm,
    double? heightMm,
    bool? showStoreName,
    bool? showProductName,
    bool? showBarcode,
    bool? showPrice,
    bool? showSizeAndColor,
    bool? showSku,
    String? storeNameOverride,
    String? currencySymbol,
    int? copies,
  }) {
    return LabelConfig(
      preset: preset ?? this.preset,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      showStoreName: showStoreName ?? this.showStoreName,
      showProductName: showProductName ?? this.showProductName,
      showBarcode: showBarcode ?? this.showBarcode,
      showPrice: showPrice ?? this.showPrice,
      showSizeAndColor: showSizeAndColor ?? this.showSizeAndColor,
      showSku: showSku ?? this.showSku,
      storeNameOverride: storeNameOverride ?? this.storeNameOverride,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      copies: copies ?? this.copies,
    );
  }

  Map<String, dynamic> toJson() => {
        'preset': preset.name,
        'width_mm': widthMm,
        'height_mm': heightMm,
        'show_store_name': showStoreName,
        'show_product_name': showProductName,
        'show_barcode': showBarcode,
        'show_price': showPrice,
        'show_size_and_color': showSizeAndColor,
        'show_sku': showSku,
        'store_name_override': storeNameOverride,
        'currency_symbol': currencySymbol,
        'copies': copies,
      };

  factory LabelConfig.fromJson(Map<String, dynamic> json) {
    final presetName = json['preset'] as String?;
    final preset = LabelSizePreset.values.firstWhere(
      (e) => e.name == presetName,
      orElse: () => LabelSizePreset.standard50x25,
    );

    return LabelConfig(
      preset: preset,
      widthMm: (json['width_mm'] as num?)?.toDouble() ?? preset.defaultWidthMm,
      heightMm: (json['height_mm'] as num?)?.toDouble() ?? preset.defaultHeightMm,
      showStoreName: json['show_store_name'] as bool? ?? true,
      showProductName: json['show_product_name'] as bool? ?? true,
      showBarcode: json['show_barcode'] as bool? ?? true,
      showPrice: json['show_price'] as bool? ?? true,
      showSizeAndColor: json['show_size_and_color'] as bool? ?? true,
      showSku: json['show_sku'] as bool? ?? true,
      storeNameOverride: json['store_name_override'] as String?,
      currencySymbol: json['currency_symbol'] as String? ?? 'Rs.',
      copies: (json['copies'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Model representing a variant and parent product selected for label printing
class LabelPrintItem {
  final ProductVariant variant;
  final Product product;
  final int quantity;
  final bool isSelected;

  const LabelPrintItem({
    required this.variant,
    required this.product,
    this.quantity = 1,
    this.isSelected = true,
  });

  LabelPrintItem copyWith({
    ProductVariant? variant,
    Product? product,
    int? quantity,
    bool? isSelected,
  }) {
    return LabelPrintItem(
      variant: variant ?? this.variant,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }

  /// Safe display barcode
  String get effectiveBarcode {
    if (variant.barcode.isNotEmpty) return variant.barcode;
    if (product.barcode != null && product.barcode!.isNotEmpty) return product.barcode!;
    return variant.sku.isNotEmpty ? variant.sku : product.sku;
  }

  /// Safe display price
  double get effectivePrice {
    return variant.sellingPrice ?? product.sellingPrice;
  }
}

/// Outcome of a print request
class PrintResult {
  final bool isSuccess;
  final PrintStatus status;
  final String message;
  final Uint8List? rawBytes;
  final String? formattedText;
  final DateTime timestamp;

  PrintResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.rawBytes,
    this.formattedText,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory PrintResult.success({
    String message = 'Printed successfully',
    Uint8List? rawBytes,
    String? formattedText,
  }) {
    return PrintResult(
      isSuccess: true,
      status: PrintStatus.success,
      message: message,
      rawBytes: rawBytes,
      formattedText: formattedText,
    );
  }

  factory PrintResult.fallback({
    required String message,
    String? formattedText,
    Uint8List? rawBytes,
  }) {
    return PrintResult(
      isSuccess: true,
      status: PrintStatus.fallbackPreview,
      message: message,
      formattedText: formattedText,
      rawBytes: rawBytes,
    );
  }

  factory PrintResult.failed(String message) {
    return PrintResult(
      isSuccess: false,
      status: PrintStatus.failed,
      message: message,
    );
  }
}
