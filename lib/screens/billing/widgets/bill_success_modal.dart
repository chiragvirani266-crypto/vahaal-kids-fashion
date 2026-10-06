import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/bill_model.dart';
import '../../../theme/app_colors.dart';

class BillSuccessModal extends StatelessWidget {
  final Bill bill;
  final VoidCallback onNewBill;

  const BillSuccessModal({
    super.key,
    required this.bill,
    required this.onNewBill,
  });

  Future<void> _shareOnWhatsApp(BuildContext context) async {
    final mobile = bill.customerMobileSnapshot?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    final StringBuffer buffer = StringBuffer();
    buffer.writeln('🛍️ *VAHAAL KIDS FASHION*');
    buffer.writeln('Children\'s Apparel Store (0-12Y)');
    buffer.writeln('--------------------------------');
    buffer.writeln('🧾 *Invoice:* ${bill.billNumber}');
    buffer.writeln('📅 *Date:* $formattedDate');
    buffer.writeln('👤 *Customer:* ${bill.displayCustomerName}');
    buffer.writeln('--------------------------------');
    buffer.writeln('*ITEMS:*');

    for (int i = 0; i < bill.items.length; i++) {
      final item = bill.items[i];
      buffer.writeln(
        '${i + 1}. ${item.productNameSnapshot} (${item.variantDescription}) x ${item.quantity} = ₹${item.total.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ₹${bill.subtotal.toStringAsFixed(2)}');
    if (bill.discount > 0) {
      buffer.writeln('Discount: -₹${bill.discount.toStringAsFixed(2)}');
    }
    buffer.writeln('*Grand Total: ₹${bill.grandTotal.toStringAsFixed(2)}*');
    buffer.writeln('Payment: ${bill.paymentMethod.toUpperCase()}');
    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for shopping with Vahaal Kids! ✨');
    buffer.writeln('Visit again soon!');

    final message = Uri.encodeComponent(buffer.toString());

    String urlStr;
    if (mobile.isNotEmpty) {
      final formattedMobile = mobile.length == 10 ? '91$mobile' : mobile;
      urlStr = 'https://wa.me/$formattedMobile?text=$message';
    } else {
      urlStr = 'https://api.whatsapp.com/send?text=$message';
    }

    final uri = Uri.parse(urlStr);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch WhatsApp.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching WhatsApp: $e')),
        );
      }
    }
  }

  void _showPrintPreview(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.print_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Thermal Receipt Print Preview'),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      'VAHAAL KIDS FASHION',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    const Text(
                      'Children\'s Store (Ages 0-12Y)',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black),
                    ),
                    const Text(
                      '--------------------------------',
                      style: TextStyle(fontFamily: 'Courier', color: Colors.black),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Bill: ${bill.billNumber}',
                            style: const TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                        Text(
                          DateFormat('dd/MM/yy HH:mm').format(bill.billDate),
                          style: const TextStyle(
                              fontFamily: 'Courier', fontSize: 11, color: Colors.black),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cust: ${bill.displayCustomerName}',
                            style: const TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                        Text('Mob: ${bill.displayCustomerMobile}',
                            style: const TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                      ],
                    ),
                    const Text(
                      '--------------------------------',
                      style: TextStyle(fontFamily: 'Courier', color: Colors.black),
                    ),
                    ...bill.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productNameSnapshot} (${item.sizeSnapshot}) x${item.quantity}',
                                  style: const TextStyle(
                                      fontFamily: 'Courier', fontSize: 11, color: Colors.black),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '₹${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontFamily: 'Courier', fontSize: 11, color: Colors.black),
                              ),
                            ],
                          ),
                        )),
                    const Text(
                      '--------------------------------',
                      style: TextStyle(fontFamily: 'Courier', color: Colors.black),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SUBTOTAL:',
                            style: TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                        Text('₹${bill.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                      ],
                    ),
                    if (bill.discount > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DISCOUNT:',
                              style: TextStyle(
                                  fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                          Text('-₹${bill.discount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GRAND TOTAL:',
                            style: TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black)),
                        Text('₹${bill.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.black)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('PAID VIA:',
                            style: TextStyle(
                                fontFamily: 'Courier', fontSize: 11, color: Colors.black)),
                        Text(bill.paymentMethod.toUpperCase(),
                            style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.black)),
                      ],
                    ),
                    const Text(
                      '================================',
                      style: TextStyle(fontFamily: 'Courier', color: Colors.black),
                    ),
                    const Text(
                      'Thank You For Shopping With Us!',
                      style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.success,
                  content: Text('Print job sent for Bill ${bill.billNumber}'),
                ),
              );
            },
            icon: const Icon(Icons.print_rounded, size: 18),
            label: const Text('Send to POS Printer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 520,
        constraints: const BoxConstraints(maxHeight: 680),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Success Header Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 42),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sale Completed Successfully!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimaryLight,
              ),
            ),
            Text(
              'Bill No: ${bill.billNumber}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable Invoice Summary Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer and Date Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Customer',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                              Text(
                                bill.displayCustomerName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              if (bill.customerMobileSnapshot != null &&
                                  bill.customerMobileSnapshot!.isNotEmpty)
                                Text(
                                  bill.customerMobileSnapshot!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Date & Time',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMutedLight)),
                              Text(
                                dateFormat.format(bill.billDate),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Pay: ${bill.paymentMethod.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Items Table
                      const Text(
                        'Item Details',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...bill.items.map((item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productNameSnapshot,
                                        style: const TextStyle(
                                            fontSize: 12, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${item.sizeSnapshot} / ${item.colorSnapshot}',
                                        style: const TextStyle(
                                            fontSize: 10, color: AppColors.textMutedLight),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'x${item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '₹${item.total.toStringAsFixed(2)}',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const Divider(height: 20),

                      // Totals
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 12)),
                          Text('₹${bill.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (bill.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount:',
                                style: TextStyle(fontSize: 12, color: AppColors.success)),
                            Text('-₹${bill.discount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${bill.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons: Print, WhatsApp, New Bill
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPrintPreview(context),
                    icon: const Icon(Icons.print_rounded, size: 18),
                    label: const Text('Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _shareOnWhatsApp(context),
                    icon: const Icon(Icons.chat_rounded, size: 18),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onNewBill();
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New Bill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
