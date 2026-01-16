library;

import 'package:get/get.dart';
import 'package:tiktok_tutorial/utils/formatters.dart';

/// Formats a value as money with localized currency suffix.
///
/// Uses translation key `currency_sum` (RU/UZ/EN).
String formatMoneyWithCurrency(dynamic value, {int decimals = 0}) {
  return formatMoney(value, decimals: decimals, suffix: 'currency_sum'.tr);
}

/// Convenience for short price strings (K/M) with localized currency suffix.
String formatShortMoneyWithCurrency(num value) {
  final v = value.toDouble();
  if (v >= 1000000) {
    return '${(v / 1000000).toStringAsFixed(1)}M ${'currency_sum'.tr}';
  }
  if (v >= 1000) {
    return '${(v / 1000).toStringAsFixed(0)}K ${'currency_sum'.tr}';
  }
  return '${v.toStringAsFixed(0)} ${'currency_sum'.tr}';
}

