import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,###', 'uz');

  static String format(double amount, {String currency = 'UZS'}) {
    return '${_formatter.format(amount.round())} $currency';
  }

  static String formatCompact(double amount, {String currency = 'UZS'}) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $currency';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $currency';
    }
    return format(amount, currency: currency);
  }
}
