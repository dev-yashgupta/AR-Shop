import 'package:intl/intl.dart';

class AppHelpers {
  static String formatPrice(double price) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(price);
  }

  static String getDiscountString(double price, double? discountPrice) {
    if (discountPrice == null) return '';
    final percentage = (((price - discountPrice) / price) * 100).round();
    return '$percentage% OFF';
  }
}
