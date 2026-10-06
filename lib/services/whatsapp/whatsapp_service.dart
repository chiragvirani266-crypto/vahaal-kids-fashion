import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../models/bill_model.dart';
import '../../theme/app_colors.dart';
import '../pdf/bill_pdf_generator.dart';

/// Status of the WhatsApp sharing operation
enum WhatsAppShareStatus {
  successDirect,
  successShareSheet,
  fallbackModal,
  failed,
}

/// Result object returned by WhatsAppService
class WhatsAppShareResult {
  final bool isSuccess;
  final WhatsAppShareStatus status;
  final String message;
  final String? shareText;
  final File? pdfFile;

  const WhatsAppShareResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.shareText,
    this.pdfFile,
  });

  factory WhatsAppShareResult.direct({
    required String message,
    required String shareText,
    File? pdfFile,
  }) =>
      WhatsAppShareResult(
        isSuccess: true,
        status: WhatsAppShareStatus.successDirect,
        message: message,
        shareText: shareText,
        pdfFile: pdfFile,
      );

  factory WhatsAppShareResult.shareSheet({
    required String message,
    required String shareText,
    File? pdfFile,
  }) =>
      WhatsAppShareResult(
        isSuccess: true,
        status: WhatsAppShareStatus.successShareSheet,
        message: message,
        shareText: shareText,
        pdfFile: pdfFile,
      );

  factory WhatsAppShareResult.fallback({
    required String message,
    String? shareText,
    File? pdfFile,
  }) =>
      WhatsAppShareResult(
        isSuccess: true,
        status: WhatsAppShareStatus.fallbackModal,
        message: message,
        shareText: shareText,
        pdfFile: pdfFile,
      );

  factory WhatsAppShareResult.failed({
    required String message,
    String? shareText,
  }) =>
      WhatsAppShareResult(
        isSuccess: false,
        status: WhatsAppShareStatus.failed,
        message: message,
        shareText: shareText,
      );
}

/// Abstract contract for WhatsApp Bill & PDF Sharing
abstract class WhatsAppService {
  /// Prepares the formatted WhatsApp text message for the bill
  String formatWhatsAppMessage(Bill bill);

  /// Generates the clean PDF invoice bytes
  Future<Uint8List> generateBillPdf(Bill bill);

  /// Saves the PDF invoice locally and returns the File handle
  Future<File?> saveBillPdf(Bill bill);

  /// Normalizes and formats mobile number with country code
  String formatPhoneNumber(String? rawPhone);

  /// Checks if WhatsApp deep link can be handled
  Future<bool> isWhatsAppSupported(String? mobile);

  /// Shares the bill via WhatsApp directly or via native share sheet
  Future<WhatsAppShareResult> shareBill({
    required BuildContext context,
    required Bill bill,
    bool attachPdf = false,
  });

  /// Displays the interactive share options / fallback modal dialog
  void showShareModal(
    BuildContext context,
    Bill bill, {
    VoidCallback? onShareCompleted,
  });
}

/// Standard Implementation of WhatsAppService
class StandardWhatsAppService implements WhatsAppService {
  @override
  String formatWhatsAppMessage(Bill bill) {
    final rawName = bill.displayCustomerName.trim();
    final customerName = (rawName.isNotEmpty && rawName != 'Walk-in Customer')
        ? rawName
        : 'Customer';
    final storeName = AppConstants.storeName;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);
    final currencyFormat = NumberFormat('#,##,##0.00', 'en_IN');
    final formattedAmount = 'Rs. ${currencyFormat.format(bill.grandTotal)}';

    final buffer = StringBuffer();
    buffer.writeln('Hello $customerName,');
    buffer.writeln();
    buffer.writeln('Thank you for shopping with $storeName.');
    buffer.writeln();
    buffer.writeln('Bill No: ${bill.billNumber}');
    buffer.writeln('Date: $formattedDate');
    buffer.writeln('Amount: $formattedAmount');
    buffer.writeln();
    buffer.writeln('*Purchased Items:*');
    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      final variantDesc = item.variantDescription.isNotEmpty ? ' (${item.variantDescription})' : '';
      buffer.writeln(
        '${i + 1}. ${item.productNameSnapshot}$variantDesc x ${item.quantity} = Rs. ${item.total.toStringAsFixed(2)}',
      );
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: Rs. ${bill.subtotal.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      buffer.writeln('Discount: -Rs. ${bill.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('*Grand Total: Rs. ${bill.grandTotal.toStringAsFixed(2)}*');
    buffer.writeln('Payment Mode: ${bill.paymentMethod.toUpperCase()}');
    buffer.writeln();
    buffer.writeln('Thank you! Have a wonderful day!');

    return buffer.toString();
  }

  @override
  Future<Uint8List> generateBillPdf(Bill bill) {
    return BillPdfGenerator.generate(bill);
  }

  @override
  Future<File?> saveBillPdf(Bill bill) async {
    try {
      final pdfBytes = await generateBillPdf(bill);
      final tempDir = await getTemporaryDirectory();
      final sanitizedBillNo = bill.billNumber.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
      final file = File('${tempDir.path}/Vahaal_Bill_$sanitizedBillNo.pdf');
      await file.writeAsBytes(pdfBytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  String formatPhoneNumber(String? rawPhone) {
    if (rawPhone == null || rawPhone.trim().isEmpty) return '';
    final digits = rawPhone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';

    // Standard 10-digit Indian mobile number
    if (digits.length == 10) {
      return '91$digits';
    }
    return digits;
  }

  @override
  Future<bool> isWhatsAppSupported(String? mobile) async {
    final formattedMobile = formatPhoneNumber(mobile);
    final urlStr = formattedMobile.isNotEmpty
        ? 'https://wa.me/$formattedMobile'
        : 'https://api.whatsapp.com/send';
    try {
      return await canLaunchUrl(Uri.parse(urlStr));
    } catch (_) {
      return false;
    }
  }

  @override
  Future<WhatsAppShareResult> shareBill({
    required BuildContext context,
    required Bill bill,
    bool attachPdf = false,
  }) async {
    final messageText = formatWhatsAppMessage(bill);
    final mobile = formatPhoneNumber(bill.customerMobileSnapshot);

    // 1. Sharing with PDF Document
    if (attachPdf) {
      try {
        final pdfFile = await saveBillPdf(bill);
        if (pdfFile != null && await pdfFile.exists()) {
          // Use native share sheet so the user can select WhatsApp with PDF attachment
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile(pdfFile.path, mimeType: 'application/pdf', name: 'Invoice_${bill.billNumber}.pdf')],
              text: messageText,
              subject: 'Tax Invoice #${bill.billNumber} - ${AppConstants.storeName}',
            ),
          );

          return WhatsAppShareResult.shareSheet(
            message: 'Invoice PDF prepared for WhatsApp share.',
            shareText: messageText,
            pdfFile: pdfFile,
          );
        }
      } catch (e) {
        // Fall back gracefully to direct text share if PDF file creation fails
      }
    }

    // 2. Direct WhatsApp text link with prefilled mobile number
    final encodedMessage = Uri.encodeComponent(messageText);
    String urlStr;
    if (mobile.isNotEmpty) {
      urlStr = 'https://wa.me/$mobile?text=$encodedMessage';
    } else {
      urlStr = 'https://api.whatsapp.com/send?text=$encodedMessage';
    }

    final uri = Uri.parse(urlStr);

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return WhatsAppShareResult.direct(
          message: mobile.isNotEmpty
              ? 'Opening WhatsApp chat with +$mobile...'
              : 'Opening WhatsApp...',
          shareText: messageText,
        );
      }
    } catch (_) {
      // Fall through to friendly fallback
    }

    // 3. Fallback when direct WhatsApp is unavailable
    if (context.mounted) {
      showShareModal(context, bill);
    }

    return WhatsAppShareResult.fallback(
      message: 'WhatsApp could not be opened directly. Displayed share options.',
      shareText: messageText,
    );
  }

  @override
  void showShareModal(
    BuildContext context,
    Bill bill, {
    VoidCallback? onShareCompleted,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _WhatsAppFallbackModal(
        bill: bill,
        service: this,
        onShareCompleted: onShareCompleted,
      ),
    );
  }
}

/// Factory & Service Locator for WhatsAppService
class WhatsAppServiceFactory {
  static WhatsAppService? _instance;

  static WhatsAppService getInstance() {
    _instance ??= StandardWhatsAppService();
    return _instance!;
  }

  static void setInstance(WhatsAppService service) {
    _instance = service;
  }

  static void reset() {
    _instance = null;
  }
}

/// User-friendly Fallback and Share Options Modal
class _WhatsAppFallbackModal extends StatefulWidget {
  final Bill bill;
  final WhatsAppService service;
  final VoidCallback? onShareCompleted;

  const _WhatsAppFallbackModal({
    required this.bill,
    required this.service,
    this.onShareCompleted,
  });

  @override
  State<_WhatsAppFallbackModal> createState() => _WhatsAppFallbackModalState();
}

class _WhatsAppFallbackModalState extends State<_WhatsAppFallbackModal> {
  bool _isGeneratingPdf = false;

  @override
  Widget build(BuildContext context) {
    final message = widget.service.formatWhatsAppMessage(widget.bill);
    final mobile = widget.bill.customerMobileSnapshot ?? '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'WhatsApp Bill Sharing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (mobile.isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.phone_iphone_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      'Customer Mobile: $mobile',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const Text(
                'WhatsApp Message Content:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 12, height: 1.3),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'If WhatsApp did not launch automatically, choose an option below:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Copy Text Button
        TextButton.icon(
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text('Copy Text'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: message));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.success,
                content: Text('WhatsApp message text copied to clipboard!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        // Direct WhatsApp Button if mobile number available
        if (mobile.isNotEmpty)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366)),
            ),
            icon: const Icon(Icons.chat_outlined, size: 18),
            label: const Text('Direct Chat'),
            onPressed: () {
              widget.service.shareBill(context: context, bill: widget.bill, attachPdf: false);
            },
          ),

        // Native Share Sheet with PDF
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
          ),
          icon: _isGeneratingPdf
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.share_rounded, size: 18),
          label: const Text('Share PDF & Bill'),
          onPressed: _isGeneratingPdf
              ? null
              : () async {
                  setState(() => _isGeneratingPdf = true);
                  final pdfFile = await widget.service.saveBillPdf(widget.bill);
                  setState(() => _isGeneratingPdf = false);

                  if (pdfFile != null && await pdfFile.exists()) {
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(pdfFile.path, mimeType: 'application/pdf', name: 'Invoice_${widget.bill.billNumber}.pdf')],
                        text: message,
                        subject: 'Bill #${widget.bill.billNumber}',
                      ),
                    );
                  } else {
                    await SharePlus.instance.share(
                      ShareParams(
                        text: message,
                        subject: 'Bill #${widget.bill.billNumber}',
                      ),
                    );
                  }

                  if (context.mounted) {
                    Navigator.of(context).pop();
                    widget.onShareCompleted?.call();
                  }
                },
        ),

        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
