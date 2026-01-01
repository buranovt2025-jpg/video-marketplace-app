/// Shared formatting helpers with safe parsing.
///
/// Goal: avoid runtime crashes from dynamic API payloads (String vs num vs null).
library;

num? tryNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty) return null;
    // Accept "123 456", "123,456.78", "123456"
    final normalized = s.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    if (normalized.isEmpty) return null;
    return num.tryParse(normalized);
  }
  return null;
}

double asDouble(dynamic value, {double fallback = 0}) {
  final n = tryNum(value);
  if (n == null) return fallback;
  return n.toDouble();
}

int asInt(dynamic value, {int fallback = 0}) {
  final n = tryNum(value);
  if (n == null) return fallback;
  return n.toInt();
}

String formatMoney(dynamic value, {int decimals = 0, String suffix = ''}) {
  final n = asDouble(value, fallback: 0);
  final s = n.toStringAsFixed(decimals);
  return suffix.isEmpty ? s : '$s $suffix';
}

