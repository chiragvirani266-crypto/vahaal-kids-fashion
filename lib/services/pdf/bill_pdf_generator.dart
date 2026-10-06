import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/constants/app_constants.dart';
import '../../models/bill_model.dart';

/// Professional PDF Invoice Document Generator for Vahaal Kids Fashion
class BillPdfGenerator {
  static Future<Uint8List> generate(Bill bill, {bool isReprint = false}) async {
    final pdf = pw.Document(
      title: 'Invoice_${bill.billNumber}',
      author: AppConstants.storeName,
    );

    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(bill.billDate);

    // Color definitions
    const primaryColor = PdfColor.fromInt(0xFF1E3A8A); // Royal Navy
    const secondaryColor = PdfColor.fromInt(0xFF0F766E); // Teal
    const darkTextColor = PdfColor.fromInt(0xFF1E293B);
    const mutedTextColor = PdfColor.fromInt(0xFF64748B);
    const borderColor = PdfColor.fromInt(0xFFCBD5E1);
    const lightBg = PdfColor.fromInt(0xFFF8FAFC);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. REPRINT WATERMARK
              if (isReprint)
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFFEF3C7),
                    border: pw.Border.all(color: PdfColor.fromInt(0xFFF59E0B)),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      '*** DUPLICATE REPRINT COPY ***',
                      style: pw.TextStyle(
                        color: PdfColor.fromInt(0xFFB45309),
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),

              // 2. STORE HEADER & INVOICE TITLE
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.storeName,
                        style: pw.TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        AppConstants.storeTagline,
                        style: const pw.TextStyle(
                          color: mutedTextColor,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        AppConstants.storeAddress,
                        style: const pw.TextStyle(fontSize: 9, color: darkTextColor),
                      ),
                      pw.Text(
                        'Mobile: ${AppConstants.storeMobile} | GSTIN: ${AppConstants.storeGstin}',
                        style: const pw.TextStyle(fontSize: 9, color: darkTextColor),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: secondaryColor,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Bill No: ${bill.billNumber}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                      pw.Text(
                        'Date: $formattedDate',
                        style: const pw.TextStyle(fontSize: 9, color: mutedTextColor),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 10),

              // 3. BILL TO & TRANSACTION META
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'BILL TO:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: mutedTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          bill.displayCustomerName,
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        if (bill.customerMobileSnapshot != null &&
                            bill.customerMobileSnapshot!.isNotEmpty)
                          pw.Text(
                            'Mobile: ${bill.customerMobileSnapshot}',
                            style: const pw.TextStyle(fontSize: 9, color: darkTextColor),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'PAYMENT DETAILS:',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: mutedTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Mode: ${bill.paymentMethod.toUpperCase()}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: darkTextColor,
                          ),
                        ),
                        if (bill.cashierName != null && bill.cashierName!.isNotEmpty)
                          pw.Text(
                            'Cashier: ${bill.cashierName}',
                            style: const pw.TextStyle(fontSize: 9, color: mutedTextColor),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // 4. ITEMS TABLE
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: const pw.BorderSide(color: borderColor, width: 0.5),
                  bottom: const pw.BorderSide(color: borderColor, width: 1),
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),  // #
                  1: const pw.FlexColumnWidth(4),     // Item
                  2: const pw.FlexColumnWidth(2.5),   // Variant (Size/Color)
                  3: const pw.FixedColumnWidth(36),  // Qty
                  4: const pw.FlexColumnWidth(2),     // Price
                  5: const pw.FlexColumnWidth(2.2),   // Amount
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFF1F5F9),
                    ),
                    children: [
                      _buildTableHeaderCell('#', align: pw.TextAlign.center),
                      _buildTableHeaderCell('Item Description'),
                      _buildTableHeaderCell('Size / Color'),
                      _buildTableHeaderCell('Qty', align: pw.TextAlign.center),
                      _buildTableHeaderCell('Unit Price', align: pw.TextAlign.right),
                      _buildTableHeaderCell('Total', align: pw.TextAlign.right),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(bill.items.length, (index) {
                    final item = bill.items[index];
                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}', align: pw.TextAlign.center),
                        _buildTableCell(item.productNameSnapshot, bold: true),
                        _buildTableCell(
                          item.variantDescription.isNotEmpty ? item.variantDescription : '-',
                        ),
                        _buildTableCell('${item.quantity}', align: pw.TextAlign.center),
                        _buildTableCell(
                          'Rs. ${item.unitPrice.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                        ),
                        _buildTableCell(
                          'Rs. ${item.total.toStringAsFixed(2)}',
                          align: pw.TextAlign.right,
                          bold: true,
                        ),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 14),

              // 5. TOTALS SECTION
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Notes & Units on Left
                  pw.Expanded(
                    flex: 5,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Total Units Count: ${bill.totalUnitsCount} pcs across ${bill.totalItemsCount} items',
                          style: const pw.TextStyle(fontSize: 9, color: mutedTextColor),
                        ),
                        if (bill.notes != null && bill.notes!.isNotEmpty) ...[
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Notes: ${bill.notes}',
                            style: const pw.TextStyle(fontSize: 8.5, color: darkTextColor),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Financial Breakdown on Right
                  pw.Expanded(
                    flex: 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: lightBg,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: borderColor, width: 0.8),
                      ),
                      child: pw.Column(
                        children: [
                          _buildTotalRow('Subtotal:', 'Rs. ${bill.subtotal.toStringAsFixed(2)}'),
                          if (bill.discount > 0) ...[
                            pw.SizedBox(height: 4),
                            _buildTotalRow(
                              'Discount:',
                              '-Rs. ${bill.discount.toStringAsFixed(2)}',
                              color: PdfColor.fromInt(0xFF16A34A),
                            ),
                          ],
                          pw.SizedBox(height: 6),
                          pw.Divider(color: borderColor, thickness: 0.8),
                          pw.SizedBox(height: 4),
                          _buildTotalRow(
                            'GRAND TOTAL:',
                            'Rs. ${bill.grandTotal.toStringAsFixed(2)}',
                            bold: true,
                            fontSize: 12,
                            color: primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // 6. FOOTER
              pw.Divider(color: borderColor, thickness: 1),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        AppConstants.storeThankYou,
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: darkTextColor,
                        ),
                      ),
                      pw.Text(
                        AppConstants.storeReturnPolicy,
                        style: const pw.TextStyle(fontSize: 8, color: mutedTextColor),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Computer generated invoice | Vahaal Kids Fashion',
                    style: const pw.TextStyle(fontSize: 7.5, color: mutedTextColor),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableHeaderCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: const PdfColor.fromInt(0xFF334155),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: const PdfColor.fromInt(0xFF1E293B),
        ),
      ),
    );
  }

  static pw.Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
    double fontSize = 9.5,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? const PdfColor.fromInt(0xFF475569),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color ?? const PdfColor.fromInt(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
