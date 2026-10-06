import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bill_model.dart';
import '../theme/app_colors.dart';

class ReceiptService {
  /// Formats the bill into a text invoice formatted for WhatsApp or clipboard
  static String formatBillText(Bill bill, {bool isReprint = false}) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🛍️ *VAHAAL KIDS FASHION*');
    buffer.writeln('Children\'s Apparel Store (0-12Y)');
    if (isReprint) {
      buffer.writeln('⚠️ *[REPRINTED DUPLICATE INVOICE]*');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('🧾 *Invoice:* ${bill.billNumber}');
    buffer.writeln('📅 *Date:* $formattedDate');
    buffer.writeln('👤 *Customer:* ${bill.displayCustomerName}');
    if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty) {
      buffer.writeln('📱 *Mobile:* ${bill.customerMobileSnapshot}');
    }
    if (bill.cashierName != null && bill.cashierName!.isNotEmpty) {
      buffer.writeln('👨‍💼 *Cashier:* ${bill.cashierName}');
    }
    buffer.writeln('--------------------------------');
    buffer.writeln('*PURCHASED ITEMS:*');

    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      buffer.writeln(
        '${i + 1}. *${item.productNameSnapshot}*',
      );
      buffer.writeln(
        '   Variant: ${item.variantDescription}',
      );
      buffer.writeln(
        '   Qty: ${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)} = ₹${item.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ₹${bill.subtotal.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      buffer.writeln('Discount: -₹${bill.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('*Grand Total: ₹${bill.grandTotal.toStringAsFixed(2)}*');
    buffer.writeln('Payment Method: ${bill.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('✨ Thank you for choosing Vahaal Kids Fashion!');
    buffer.writeln('Visit again soon!');

    return buffer.toString();
  }

  /// Direct WhatsApp share with customer phone number prefilled
  static Future<void> shareOnWhatsApp(
    BuildContext context,
    Bill bill, {
    bool isReprint = false,
  }) async {
    final mobile = bill.customerMobileSnapshot?.replaceAll(RegExp(r'[^\d]'), '') ?? '';
    final messageText = formatBillText(bill, isReprint: isReprint);
    final encodedMessage = Uri.encodeComponent(messageText);

    String urlStr;
    if (mobile.isNotEmpty) {
      final formattedMobile = mobile.length == 10 ? '91$mobile' : mobile;
      urlStr = 'https://wa.me/$formattedMobile?text=$encodedMessage';
    } else {
      urlStr = 'https://api.whatsapp.com/send?text=$encodedMessage';
    }

    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.error,
              content: Text('Could not open WhatsApp on this device.'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Error launching WhatsApp: $e'),
          ),
        );
      }
    }
  }

  /// Copies bill text to clipboard
  static Future<void> copyToClipboard(BuildContext context, Bill bill, {bool isReprint = false}) async {
    final text = formatBillText(bill, isReprint: isReprint);
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Bill text copied to clipboard'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Opens the Thermal Receipt Print Preview modal dialog
  static void showThermalReceipt(
    BuildContext context,
    Bill bill, {
    bool isReprint = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _ThermalReceiptDialog(bill: bill, isReprint: isReprint),
    );
  }
}

class _ThermalReceiptDialog extends StatelessWidget {
  final Bill bill;
  final bool isReprint;

  const _ThermalReceiptDialog({
    required this.bill,
    required this.isReprint,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isReprint ? Icons.replay_rounded : Icons.print_rounded,
                color: isReprint ? AppColors.accent : AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isReprint ? 'Thermal Receipt (Reprint)' : 'Thermal Receipt Print',
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
        width: 380,
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade400, width: 1.2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isReprint) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '*** REPRINTED DUPLICATE COPY ***',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.brown,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Text(
                  'VAHAAL KIDS FASHION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Premium Children\'s Store (Ages 0-12Y)',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black),
                ),
                const Text(
                  '================================',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', color: Colors.black, letterSpacing: -1),
                ),
                const SizedBox(height: 4),
                _receiptRow('Bill No:', bill.billNumber),
                _receiptRow('Date:', formattedDate),
                _receiptRow('Customer:', bill.displayCustomerName),
                if (bill.customerMobileSnapshot != null && bill.customerMobileSnapshot!.isNotEmpty)
                  _receiptRow('Mobile:', bill.customerMobileSnapshot!),
                if (bill.cashierName != null && bill.cashierName!.isNotEmpty)
                  _receiptRow('Cashier:', bill.cashierName!),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', color: Colors.black, letterSpacing: -1),
                ),
                const Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Item Description',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        'Qty',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Price',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', color: Colors.black, letterSpacing: -1),
                ),
                ...bill.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productNameSnapshot,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                ' ${item.variantDescription}',
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 9,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${item.quantity}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.unitPrice.toStringAsFixed(0),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item.total.toStringAsFixed(0),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const Text(
                  '================================',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', color: Colors.black, letterSpacing: -1),
                ),
                _receiptRow('Subtotal:', 'Rs. ${bill.subtotal.toStringAsFixed(2)}'),
                if (bill.discount > 0)
                  _receiptRow('Discount:', '-Rs. ${bill.discount.toStringAsFixed(2)}'),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'GRAND TOTAL:',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black,
                      ),
                    ),
                    Text(
                      'Rs. ${bill.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                _receiptRow('Payment Method:', bill.paymentMethod.toUpperCase()),
                _receiptRow('Total Units:', '${bill.totalUnitsCount}'),
                const Text(
                  '--------------------------------',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', color: Colors.black, letterSpacing: -1),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thank you for shopping!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  'Exchange within 7 days with bill.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Courier', fontSize: 9, color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.share_rounded, size: 16),
          label: const Text('WhatsApp'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF25D366),
            side: const BorderSide(color: Color(0xFF25D366)),
          ),
          onPressed: () {
            ReceiptService.shareOnWhatsApp(context, bill, isReprint: isReprint);
          },
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.print_rounded, size: 16),
          label: Text(isReprint ? 'Print Duplicate' : 'Print Now'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.success,
                content: Text(
                  'Sending receipt for #${bill.billNumber} to thermal printer...',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 10,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 10,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
