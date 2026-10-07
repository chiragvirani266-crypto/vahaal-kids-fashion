import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/bill_model.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../../../theme/app_colors.dart';
import '../../receipt_service.dart';
import '../formatters/thermal_receipt_formatter.dart';
import '../printer_models.dart';
import '../printer_service.dart';

class PrinterPreviewDialog extends StatefulWidget {
  final PrinterService printerService;
  final Bill? bill;
  final ProductVariant? variant;
  final Product? product;
  final bool isReprint;
  final PrinterConfig? initialConfig;
  final VoidCallback? onPrintCompleted;

  const PrinterPreviewDialog({
    super.key,
    required this.printerService,
    this.bill,
    this.variant,
    this.product,
    this.isReprint = false,
    this.initialConfig,
    this.onPrintCompleted,
  });

  @override
  State<PrinterPreviewDialog> createState() => _PrinterPreviewDialogState();
}

class _PrinterPreviewDialogState extends State<PrinterPreviewDialog> {
  late PrinterConfig _config;
  bool _isPrinting = false;
  String? _statusMessage;
  bool _showAdvancedSettings = false;
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfig ?? const PrinterConfig();
    _ipController.text = _config.ipAddress ?? '192.168.1.100';
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  String _getPreviewText() {
    if (widget.bill != null) {
      return ThermalReceiptFormatter.formatBillText(
        widget.bill!,
        paperWidth: _config.paperWidth,
        isReprint: widget.isReprint,
      );
    } else if (widget.variant != null) {
      return ThermalReceiptFormatter.formatVariantLabelText(
        widget.variant!,
        product: widget.product,
      );
    }
    return 'No document to preview.';
  }

  Future<void> _handlePrint() async {
    setState(() {
      _isPrinting = true;
      _statusMessage = 'Sending command to printer...';
    });

    final currentConfig = _config.copyWith(
      ipAddress: _ipController.text.trim(),
    );

    PrintResult result;
    if (widget.bill != null) {
      result = await widget.printerService.printBill(
        widget.bill!,
        config: currentConfig,
        isReprint: widget.isReprint,
      );
    } else if (widget.variant != null) {
      result = await widget.printerService.printLabel(
        widget.variant!,
        product: widget.product,
      );
    } else {
      result = PrintResult.failed('No item to print.');
    }

    if (mounted) {
      setState(() {
        _isPrinting = false;
        _statusMessage = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: result.isSuccess ? AppColors.success : AppColors.secondary,
          content: Row(
            children: [
              Icon(
                result.isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(result.message)),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      widget.onPrintCompleted?.call();
      if (result.isSuccess) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _copyToClipboard() async {
    final text = _getPreviewText();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Text('Receipt text copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewText = _getPreviewText();
    final isLabelMode = widget.variant != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                widget.isReprint
                    ? Icons.replay_rounded
                    : (isLabelMode ? Icons.qr_code_2_rounded : Icons.print_rounded),
                color: widget.isReprint ? AppColors.accent : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                widget.isReprint
                    ? 'Thermal Receipt (Reprint)'
                    : (isLabelMode ? 'Barcode Label Print' : 'Thermal Receipt Print'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Paper Width Selector (58mm vs 80mm)
              if (!isLabelMode) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _config = _config.copyWith(paperWidth: ReceiptPaperWidth.mm80);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _config.paperWidth == ReceiptPaperWidth.mm80
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '80mm Standard Thermal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _config.paperWidth == ReceiptPaperWidth.mm80
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _config = _config.copyWith(paperWidth: ReceiptPaperWidth.mm58);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: _config.paperWidth == ReceiptPaperWidth.mm58
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '58mm Small Thermal',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _config.paperWidth == ReceiptPaperWidth.mm58
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Advanced Hardware Printer Settings Toggle
              InkWell(
                onTap: () {
                  setState(() {
                    _showAdvancedSettings = !_showAdvancedSettings;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvancedSettings ? Icons.expand_less_rounded : Icons.settings_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showAdvancedSettings ? 'Hide Printer Settings' : 'Printer Connection Settings',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showAdvancedSettings) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      DropdownButtonFormField<PrinterConnectionType>(
                        value: _config.connectionType,
                        decoration: const InputDecoration(
                          labelText: 'Connection Channel',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: PrinterConnectionType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.label, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _config = _config.copyWith(connectionType: val);
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ipController,
                        decoration: const InputDecoration(
                          labelText: 'Printer IP (LAN / Wi-Fi)',
                          hintText: 'e.g. 192.168.1.100',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Checkbox(
                            value: _config.autoCut,
                            onChanged: (v) {
                              setState(() {
                                _config = _config.copyWith(autoCut: v ?? true);
                              });
                            },
                          ),
                          const Text('Auto Cut Paper', style: TextStyle(fontSize: 12)),
                          const Spacer(),
                          Checkbox(
                            value: _config.openCashDrawer,
                            onChanged: (v) {
                              setState(() {
                                _config = _config.copyWith(openCashDrawer: v ?? false);
                              });
                            },
                          ),
                          const Text('Open Drawer', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Visual Thermal Print Paper Rendering
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 1.2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  previewText,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 11,
                    color: Colors.black,
                    height: 1.25,
                  ),
                ),
              ),

              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // WhatsApp Share button if printing bill
        if (widget.bill != null)
          OutlinedButton.icon(
            icon: const Icon(Icons.chat_bubble_rounded, size: 15),
            label: const Text('WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366)),
            ),
            onPressed: () {
              ReceiptService.shareOnWhatsApp(
                context,
                widget.bill!,
                isReprint: widget.isReprint,
              );
            },
          ),

        // Copy Text Button
        OutlinedButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 15),
          label: const Text('Copy'),
          onPressed: _copyToClipboard,
        ),

        // Print Now Button
        ElevatedButton.icon(
          icon: _isPrinting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.print_rounded, size: 16),
          label: Text(
            _isPrinting
                ? 'Printing...'
                : (widget.isReprint ? 'Print Duplicate' : 'Print Now'),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _isPrinting ? null : _handlePrint,
        ),
      ],
    );
  }
}
