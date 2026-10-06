import 'dart:convert';
import 'dart:typed_data';
import '../printer_models.dart';

/// Pure Dart ESC/POS Command Generator for POS Thermal Printers
class EscPosBuilder {
  final List<int> _bytes = [];
  final ReceiptPaperWidth paperWidth;

  EscPosBuilder({this.paperWidth = ReceiptPaperWidth.mm80});

  /// Initialize / Reset printer
  void initialize() {
    _bytes.addAll([0x1B, 0x40]); // ESC @
  }

  /// Align text: 0=Left, 1=Center, 2=Right
  void setAlign(int align) {
    _bytes.addAll([0x1B, 0x61, align]); // ESC a n
  }

  /// Set text size: normal (0x00), double height (0x01), double width (0x10), double both (0x11)
  void setTextSize({bool doubleHeight = false, bool doubleWidth = false}) {
    int flag = 0;
    if (doubleHeight) flag |= 0x01;
    if (doubleWidth) flag |= 0x10;
    _bytes.addAll([0x1D, 0x21, flag]); // GS ! n
  }

  /// Toggle bold
  void setBold(bool isBold) {
    _bytes.addAll([0x1B, 0x45, isBold ? 1 : 0]); // ESC E n
  }

  /// Toggle underline
  void setUnderline(bool isUnderline) {
    _bytes.addAll([0x1B, 0x2D, isUnderline ? 1 : 0]); // ESC - n
  }

  /// Toggle inverted colors (white on black)
  void setInverse(bool isInverse) {
    _bytes.addAll([0x1D, 0x42, isInverse ? 1 : 0]); // GS B n
  }

  /// Append ASCII / UTF-8 string followed by newline
  void textLine(String text, {int align = 0, bool bold = false, bool doubleHeight = false, bool doubleWidth = false}) {
    setAlign(align);
    setBold(bold);
    setTextSize(doubleHeight: doubleHeight, doubleWidth: doubleWidth);
    _bytes.addAll(utf8.encode(text));
    _bytes.add(0x0A); // Line feed (LF)
  }

  /// Print a horizontal divider line filling the paper width
  void divider({String char = '-'}) {
    setAlign(1);
    setBold(false);
    setTextSize(doubleHeight: false, doubleWidth: false);
    final count = paperWidth.columns;
    final line = char * count;
    _bytes.addAll(utf8.encode(line));
    _bytes.add(0x0A);
  }

  /// Print 2-column key-value row with left label and right value
  void row2(String left, String right, {bool bold = false}) {
    setAlign(0);
    setBold(bold);
    setTextSize(doubleHeight: false, doubleWidth: false);

    final totalCols = paperWidth.columns;
    final spaceLen = totalCols - left.length - right.length;
    if (spaceLen > 0) {
      final line = left + (' ' * spaceLen) + right;
      _bytes.addAll(utf8.encode(line));
    } else {
      _bytes.addAll(utf8.encode('$left $right'));
    }
    _bytes.add(0x0A);
  }

  /// Feed N lines
  void feed(int lines) {
    _bytes.addAll([0x1B, 0x64, lines]); // ESC d n
  }

  /// Paper Cut: 0=Full cut, 1=Partial cut
  void cut({bool partial = false}) {
    feed(3);
    _bytes.addAll([0x1D, 0x56, partial ? 1 : 0]); // GS V n
  }

  /// Open Cash Drawer pulse (Pin 2 / Pin 5)
  void openCashDrawer({int pin = 0}) {
    _bytes.addAll([0x1B, 0x70, pin, 25, 250]); // ESC p m t1 t2
  }

  /// Sound buzzer / beep
  void beep({int times = 1, int duration = 2}) {
    _bytes.addAll([0x1B, 0x42, times, duration]); // ESC B n t
  }

  /// Print standard Code128 Barcode
  void printBarcode(String data, {int height = 60, int width = 2}) {
    setAlign(1);
    _bytes.addAll([0x1D, 0x68, height]); // GS h (barcode height)
    _bytes.addAll([0x1D, 0x77, width]);  // GS w (barcode module width)
    _bytes.addAll([0x1D, 0x48, 2]);      // GS H (print text below barcode)

    final cleanData = data.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    final dataBytes = utf8.encode(cleanData);
    // GS k 4 (Code39)
    _bytes.addAll([0x1D, 0x6B, 4, ...dataBytes, 0x00]);
    _bytes.add(0x0A);
  }

  /// Export generated raw byte payload
  Uint8List build() {
    return Uint8List.fromList(_bytes);
  }
}
