import 'package:flutter/material.dart';
import '../formatters/code128_encoder.dart';

/// Renders a crisp vector Code 128-B 1D barcode on canvas
class BarcodeWidget extends StatelessWidget {
  final String data;
  final double height;
  final double? width;
  final bool showText;
  final TextStyle? textStyle;
  final Color barColor;
  final Color backgroundColor;

  const BarcodeWidget({
    super.key,
    required this.data,
    this.height = 42.0,
    this.width,
    this.showText = true,
    this.textStyle,
    this.barColor = Colors.black,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final cleanData = data.trim().isNotEmpty ? data.trim() : '00000000';
    final modules = Code128Encoder.encodeToModules(cleanData, quietZoneModules: 6);

    return Container(
      color: backgroundColor,
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: CustomPaint(
              painter: _BarcodePainter(
                modules: modules,
                barColor: barColor,
              ),
            ),
          ),
          if (showText) ...[
            const SizedBox(height: 3),
            Text(
              cleanData,
              style: textStyle ??
                  const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.0,
                    color: Colors.black87,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final List<bool> modules;
  final Color barColor;

  _BarcodePainter({
    required this.modules,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (modules.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final totalModules = modules.length;
    final moduleWidth = size.width / totalModules;

    for (int i = 0; i < totalModules; i++) {
      if (modules[i]) {
        // Draw black bar
        final left = i * moduleWidth;
        final rect = Rect.fromLTWH(left, 0, moduleWidth + 0.1, size.height);
        canvas.drawRect(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) {
    return oldDelegate.modules != modules || oldDelegate.barColor != barColor;
  }
}
