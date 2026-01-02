import 'dart:convert';

class QrData {
  final String orderId;
  final String type;
  final String code;
  final int timestamp;

  QrData({
    required this.orderId,
    required this.type,
    required this.code,
    required this.timestamp,
  });

  factory QrData.fromJson(Map<String, dynamic> json) {
    return QrData(
      orderId: json['orderId'] as String,
      type: json['type'] as String,
      code: json['code'] as String,
      timestamp: json['timestamp'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'type': type,
      'code': code,
      'timestamp': timestamp,
    };
  }

  bool get isExpired {
    final maxAge = 24 * 60 * 60 * 1000;
    return DateTime.now().millisecondsSinceEpoch - timestamp > maxAge;
  }
}

class QrService {
  static final QrService _instance = QrService._internal();
  factory QrService() => _instance;
  QrService._internal();

  QrData? parseQrCode(String qrString) {
    try {
      final json = jsonDecode(qrString) as Map<String, dynamic>;
      return QrData.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  bool validateQrCode(QrData qrData, String expectedOrderId, String expectedType) {
    if (qrData.orderId != expectedOrderId) {
      return false;
    }

    if (qrData.type != expectedType) {
      return false;
    }

    if (qrData.isExpired) {
      return false;
    }

    return true;
  }

  bool isValidPickupQr(String qrString, String orderId) {
    final qrData = parseQrCode(qrString);
    if (qrData == null) return false;
    return validateQrCode(qrData, orderId, 'seller_pickup');
  }

  bool isValidDeliveryQr(String qrString, String orderId) {
    final qrData = parseQrCode(qrString);
    if (qrData == null) return false;
    return validateQrCode(qrData, orderId, 'courier_delivery');
  }
}
