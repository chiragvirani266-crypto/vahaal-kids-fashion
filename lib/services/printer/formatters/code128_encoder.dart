/// Code 128 (Subset B) Barcode Encoder
///
/// Encodes ASCII characters (32 to 126) into standard Code 128 1D barcode module patterns.
/// Each symbol has 6 elements (alternating bar/space) totaling 11 modules, except the
/// stop symbol which has 7 elements totaling 13 modules.
class Code128Encoder {
  // 107 standard Code 128 symbol patterns (widths of bars and spaces)
  static const List<List<int>> _patterns = [
    [2, 1, 2, 2, 2, 2], // 0: ' '
    [2, 2, 2, 1, 2, 2], // 1: '!'
    [2, 2, 2, 2, 2, 1], // 2: '"'
    [1, 2, 1, 2, 2, 3], // 3: '#'
    [1, 2, 1, 3, 2, 2], // 4: '$'
    [1, 3, 1, 2, 2, 2], // 5: '%'
    [1, 2, 2, 2, 1, 3], // 6: '&'
    [1, 2, 2, 3, 1, 2], // 7: '''
    [1, 3, 2, 2, 1, 2], // 8: '('
    [2, 2, 1, 2, 1, 3], // 9: ')'
    [2, 2, 1, 3, 1, 2], // 10: '*'
    [2, 3, 1, 2, 1, 2], // 11: '+'
    [1, 1, 2, 2, 3, 2], // 12: ','
    [1, 2, 2, 1, 3, 2], // 13: '-'
    [1, 2, 2, 2, 3, 1], // 14: '.'
    [1, 1, 3, 2, 2, 2], // 15: '/'
    [1, 2, 3, 1, 2, 2], // 16: '0'
    [1, 2, 3, 2, 2, 1], // 17: '1'
    [2, 2, 3, 2, 1, 1], // 18: '2'
    [2, 2, 1, 1, 3, 2], // 19: '3'
    [2, 2, 1, 2, 3, 1], // 20: '4'
    [2, 1, 3, 2, 1, 2], // 21: '5'
    [2, 2, 3, 1, 1, 2], // 22: '6'
    [3, 1, 2, 1, 3, 1], // 23: '7'
    [3, 1, 1, 2, 2, 2], // 24: '8'
    [3, 2, 1, 1, 2, 2], // 25: '9'
    [3, 2, 1, 2, 2, 1], // 26: ':'
    [3, 1, 2, 2, 1, 2], // 27: ';'
    [3, 2, 2, 1, 1, 2], // 28: '<'
    [3, 2, 2, 2, 1, 1], // 29: '='
    [2, 1, 2, 1, 2, 3], // 30: '>'
    [2, 1, 2, 3, 2, 1], // 31: '?'
    [2, 3, 2, 1, 2, 1], // 32: '@'
    [1, 1, 1, 3, 2, 3], // 33: 'A'
    [1, 3, 1, 1, 2, 3], // 34: 'B'
    [1, 3, 1, 3, 2, 1], // 35: 'C'
    [1, 1, 2, 3, 1, 3], // 36: 'D'
    [1, 3, 2, 1, 1, 3], // 37: 'E'
    [1, 3, 2, 3, 1, 1], // 38: 'F'
    [2, 1, 1, 3, 1, 3], // 39: 'G'
    [2, 3, 1, 1, 1, 3], // 40: 'H'
    [2, 3, 1, 3, 1, 1], // 41: 'I'
    [1, 1, 2, 1, 3, 3], // 42: 'J'
    [1, 1, 2, 3, 3, 1], // 43: 'K'
    [1, 3, 2, 1, 3, 1], // 44: 'L'
    [1, 1, 3, 1, 2, 3], // 45: 'M'
    [1, 1, 3, 3, 2, 1], // 46: 'N'
    [1, 3, 3, 1, 2, 1], // 47: 'O'
    [3, 1, 3, 1, 2, 1], // 48: 'P'
    [2, 1, 1, 3, 3, 1], // 49: 'Q'
    [2, 3, 1, 1, 3, 1], // 50: 'R'
    [2, 1, 3, 1, 1, 3], // 51: 'S'
    [2, 1, 3, 3, 1, 1], // 52: 'T'
    [2, 1, 3, 1, 3, 1], // 53: 'U'
    [3, 1, 1, 1, 2, 3], // 54: 'V'
    [3, 1, 1, 3, 2, 1], // 55: 'W'
    [3, 3, 1, 1, 2, 1], // 56: 'X'
    [3, 1, 2, 1, 1, 3], // 57: 'Y'
    [3, 1, 2, 3, 1, 1], // 58: 'Z'
    [3, 3, 2, 1, 1, 1], // 59: '['
    [3, 1, 4, 1, 1, 1], // 60: '\'
    [2, 2, 1, 4, 1, 1], // 61: ']'
    [4, 3, 1, 1, 1, 1], // 62: '^'
    [1, 1, 1, 2, 2, 4], // 63: '_'
    [1, 1, 1, 4, 2, 2], // 64: '`'
    [1, 2, 1, 1, 2, 4], // 65: 'a'
    [1, 2, 1, 4, 2, 1], // 66: 'b'
    [1, 4, 1, 1, 2, 2], // 67: 'c'
    [1, 4, 1, 2, 2, 1], // 68: 'd'
    [1, 1, 2, 2, 1, 4], // 69: 'e'
    [1, 1, 2, 4, 1, 2], // 70: 'f'
    [1, 2, 2, 1, 1, 4], // 71: 'g'
    [1, 2, 2, 4, 1, 1], // 72: 'h'
    [1, 4, 2, 1, 1, 2], // 73: 'i'
    [1, 4, 2, 2, 1, 1], // 74: 'j'
    [2, 4, 1, 2, 1, 1], // 75: 'k'
    [2, 2, 1, 1, 1, 4], // 76: 'l'
    [4, 1, 3, 1, 1, 1], // 77: 'm'
    [2, 4, 1, 1, 1, 2], // 78: 'n'
    [1, 3, 4, 1, 1, 1], // 79: 'o'
    [1, 1, 1, 2, 4, 2], // 80: 'p'
    [1, 2, 1, 1, 4, 2], // 81: 'q'
    [1, 2, 1, 2, 4, 1], // 82: 'r'
    [1, 1, 4, 2, 1, 2], // 83: 's'
    [1, 2, 4, 1, 1, 2], // 84: 't'
    [1, 2, 4, 2, 1, 1], // 85: 'u'
    [4, 1, 1, 2, 1, 2], // 86: 'v'
    [4, 2, 1, 1, 1, 2], // 87: 'w'
    [4, 2, 1, 2, 1, 1], // 88: 'x'
    [2, 1, 2, 1, 4, 1], // 89: 'y'
    [2, 1, 4, 1, 2, 1], // 90: 'z'
    [4, 1, 2, 1, 2, 1], // 91: '{'
    [1, 1, 1, 1, 4, 3], // 92: '|'
    [1, 1, 1, 3, 4, 1], // 93: '}'
    [1, 3, 1, 1, 4, 1], // 94: '~'
    [1, 1, 4, 1, 1, 3], // 95: DEL
    [1, 1, 4, 3, 1, 1], // 96: FNC3
    [4, 1, 1, 1, 1, 3], // 97: FNC2
    [4, 1, 1, 3, 1, 1], // 98: SHIFT
    [1, 1, 3, 1, 4, 1], // 99: CODE C
    [1, 1, 4, 1, 3, 1], // 100: CODE B
    [3, 1, 1, 1, 4, 1], // 101: FNC4
    [4, 1, 1, 1, 3, 1], // 102: FNC1
    [2, 1, 1, 4, 1, 2], // 103: START A
    [2, 1, 1, 2, 1, 4], // 104: START B
    [2, 1, 1, 2, 3, 2], // 105: START C
    [2, 3, 3, 1, 1, 1, 2], // 106: STOP
  ];

  static const int _startB = 104;
  static const int _stop = 106;

  /// Sanitizes raw string for Code 128-B encoding
  static String sanitize(String input) {
    if (input.trim().isEmpty) return '00000000';
    // Allow ASCII chars 32 to 126
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final code = input.codeUnitAt(i);
      if (code >= 32 && code <= 126) {
        buffer.writeCharCode(code);
      } else {
        buffer.write('-');
      }
    }
    return buffer.toString().isEmpty ? '00000000' : buffer.toString();
  }

  /// Calculates the checksum symbol index for Code 128-B
  static int calculateChecksum(String text) {
    int sum = _startB;
    for (int i = 0; i < text.length; i++) {
      final val = text.codeUnitAt(i) - 32;
      sum += (i + 1) * val;
    }
    return sum % 103;
  }

  /// Returns the complete list of symbol indices [StartB, char1, char2, ..., Checksum, Stop]
  static List<int> getSymbolIndices(String rawText) {
    final text = sanitize(rawText);
    final symbols = <int>[_startB];

    for (int i = 0; i < text.length; i++) {
      symbols.add(text.codeUnitAt(i) - 32);
    }

    symbols.add(calculateChecksum(text));
    symbols.add(_stop);

    return symbols;
  }

  /// Encodes text into a boolean array of modules (true = black bar, false = white space)
  /// Includes quiet zones at both ends.
  static List<bool> encodeToModules(String rawText, {int quietZoneModules = 10}) {
    final symbols = getSymbolIndices(rawText);
    final modules = <bool>[];

    // Left quiet zone
    if (quietZoneModules > 0) {
      modules.addAll(List.filled(quietZoneModules, false));
    }

    for (final sym in symbols) {
      final pattern = _patterns[sym];
      bool isBar = true;
      for (final width in pattern) {
        modules.addAll(List.filled(width, isBar));
        isBar = !isBar;
      }
    }

    // Right quiet zone
    if (quietZoneModules > 0) {
      modules.addAll(List.filled(quietZoneModules, false));
    }

    return modules;
  }

  /// Total module count for given text
  static int calculateTotalModules(String rawText, {int quietZoneModules = 10}) {
    final text = sanitize(rawText);
    // StartB (11) + data (11 * N) + Checksum (11) + Stop (13) + (2 * quietZone)
    return 11 + (text.length * 11) + 11 + 13 + (2 * quietZoneModules);
  }
}
