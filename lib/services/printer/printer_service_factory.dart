import 'package:flutter/foundation.dart';
import 'platforms/android_printer_service.dart';
import 'platforms/fallback_printer_service.dart';
import 'platforms/ios_printer_service.dart';
import 'platforms/windows_printer_service.dart';
import 'printer_service.dart';

/// Factory for instantiating the right cross-platform PrinterService implementation
class PrinterServiceFactory {
  static PrinterService? _instance;

  /// Returns the singleton or active PrinterService for the host operating system
  static PrinterService getInstance() {
    if (_instance != null) return _instance!;

    if (kIsWeb) {
      _instance = FallbackPrinterService();
      return _instance!;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        _instance = AndroidPrinterService();
        break;
      case TargetPlatform.iOS:
        _instance = IosPrinterService();
        break;
      case TargetPlatform.windows:
        _instance = WindowsPrinterService();
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        _instance = FallbackPrinterService();
        break;
    }

    return _instance!;
  }

  /// Sets a custom or mock PrinterService instance (ideal for unit testing)
  static void setInstance(PrinterService service) {
    _instance = service;
  }

  /// Resets the cached singleton
  static void reset() {
    _instance = null;
  }
}
