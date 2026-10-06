import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/bill_model.dart';
import '../../../services/receipt_service.dart';
import '../../../theme/app_colors.dart';

class BillSuccessModal extends StatelessWidget {
  final Bill bill;
  final VoidCallback onNewBill;

  const BillSuccessModal({
    super.key,
    required this.bill,
    required this.onNewBill,
  });

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
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                'Payment: ${bill.paymentMethod.toUpperCase()}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Items List
                      const Text(
                        'Items Summary',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...bill.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.productNameSnapshot} (${item.variantDescription})',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${AppConstants.currencySymbol}${item.total.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),

                      // Financial Summary Rows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(fontSize: 12)),
                          Text('${AppConstants.currencySymbol}${bill.subtotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      if (bill.discount > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount',
                                style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                            Text(
                              '-${AppConstants.currencySymbol}${bill.discount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total Paid',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${AppConstants.currencySymbol}${bill.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
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
                    onPressed: () => ReceiptService.showThermalReceipt(context, bill),
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
                    onPressed: () => ReceiptService.shareOnWhatsApp(context, bill),
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
