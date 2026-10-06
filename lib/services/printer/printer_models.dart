import 'package:flutter/foundation.dart';

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

/// Configuration for barcode / price tag sticker printing
class LabelConfig {
  final double widthMm;
  final double heightMm;
  final bool showStoreName;
  final bool showBarcode;
  final bool showPrice;
  final bool showSizeAndColor;
  final int copies;

  const LabelConfig({
    this.widthMm = 50.0,
    this.heightMm = 25.0,
    this.showStoreName = true,
    this.showBarcode = true,
    this.showPrice = true,
    this.showSizeAndColor = true,
    this.copies = 1,
  });
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
