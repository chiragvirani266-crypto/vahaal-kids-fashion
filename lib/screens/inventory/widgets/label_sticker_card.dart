import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/product_model.dart';
import '../../../models/product_variant_model.dart';
import '../../../services/printer/printer_models.dart';
import '../../../services/printer/widgets/barcode_widget.dart';
import '../../../theme/app_colors.dart';

/// Visually authentic retail price tag and barcode sticker preview
class LabelStickerCard extends StatelessWidget {
  final ProductVariant variant;
  final Product? product;
  final LabelConfig config;
  final double scale;
  final bool showDieCutBorder;

  const LabelStickerCard({
    super.key,
    required this.variant,
    this.product,
    this.config = const LabelConfig(),
    this.scale = 1.0,
    this.showDieCutBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStoreName = config.storeNameOverride?.isNotEmpty == true
        ? config.storeNameOverride!
        : AppConstants.storeName;

    final productName = product?.productName ?? 'Kidswear Apparel';
    final sku = variant.sku.isNotEmpty ? variant.sku : (product?.sku ?? '');
    final barcode = variant.barcode.isNotEmpty ? variant.barcode : (product?.barcode ?? sku);
    final price = variant.sellingPrice ?? product?.sellingPrice ?? 0.0;

    // Calculate proportional dimensions based on mm config
    // 1 mm ~= 5.5 logical pixels for preview card scale
    final cardWidth = (config.widthMm * 5.6) * scale;
    final minCardHeight = (config.heightMm * 5.6) * scale;

    return Container(
      width: cardWidth,
      constraints: BoxConstraints(minHeight: minCardHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8 * scale),
        border: showDieCutBorder
            ? Border.all(
                color: Colors.grey.shade400,
                width: 1.2,
                strokeAlign: BorderSide.strokeAlignInside,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle corner peel indicator / cut notch
          Positioned(
            top: 4 * scale,
            right: 6 * scale,
            child: Text(
              '${config.widthMm.toInt()}×${config.heightMm.toInt()}mm',
              style: TextStyle(
                fontSize: 8 * scale,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14.0 * scale,
              vertical: 10.0 * scale,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Store Header
                if (config.showStoreName) ...[
                  Text(
                    effectiveStoreName,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 12.0 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppColors.primary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1 * scale),
                  Text(
                    AppConstants.storeTagline,
                    style: TextStyle(
                      fontSize: 8.5 * scale,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scale),
                  Container(
                    height: 1.0,
                    color: Colors.grey.shade300,
                    margin: EdgeInsets.symmetric(horizontal: 4 * scale),
                  ),
                  SizedBox(height: 5 * scale),
                ],

                // 2. Product Name
                if (config.showProductName) ...[
                  Text(
                    productName,
                    style: TextStyle(
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scale),
                ],

                // 3. Variant Attributes (Size & Color Badges)
                if (config.showSizeAndColor) ...[
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 6 * scale,
                    runSpacing: 4 * scale,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4 * scale),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Size: ${variant.size}',
                          style: TextStyle(
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6 * scale,
                          vertical: 2 * scale,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4 * scale),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'Color: ${variant.color}',
                          style: TextStyle(
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4 * scale),
                ],

                // 4. SKU Line
                if (config.showSku && sku.isNotEmpty) ...[
                  Text(
                    'SKU: $sku',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9.0 * scale,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4 * scale),
                ],

                // 5. Crisp Barcode
                if (config.showBarcode && barcode.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 2 * scale,
                    ),
                    child: BarcodeWidget(
                      data: barcode,
                      height: 34.0 * scale,
                      showText: true,
                      textStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9.5 * scale,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                ],

                // 6. Selling Price / MRP
                if (config.showPrice && price > 0) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8 * scale,
                      vertical: 3 * scale,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4 * scale),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MRP: ${config.currencySymbol} ${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13.0 * scale,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '(Inclusive of all taxes)',
                          style: TextStyle(
                            fontSize: 7.5 * scale,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
