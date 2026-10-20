/// Utility to convert integer numbers to Eastern Arabic numerals (٠-٩)
class ArabicNumberConverter {
  ArabicNumberConverter._();

  static const List<String> _arabicDigits = [
    '٠',
    '١',
    '٢',
    '٣',
    '٤',
    '٥',
    '٦',
    '٧',
    '٨',
    '٩',
  ];

  static String convert(int number) {
    return number.toString().split('').map((char) {
      final digit = int.tryParse(char);
      return digit != null ? _arabicDigits[digit] : char;
    }).join();
  }
}
