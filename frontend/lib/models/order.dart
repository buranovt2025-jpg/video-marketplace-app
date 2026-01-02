import 'user.dart';
import 'product.dart';

enum OrderStatus {
  pending,
  confirmed,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
  disputed,
}

enum PaymentMethod { card, cash, payme, click }

enum PaymentStatus { pending, held, completed, refunded, failed }

class Order {
  final String id;
  final String orderNumber;
  final String buyerId;
  final String sellerId;
  final String? courierId;
  final String productId;
  final String? videoId;
  final int quantity;
  final double unitPrice;
  final double totalAmount;
  final double courierFee;
  final double platformCommission;
  final double sellerAmount;
  final String currency;
  final OrderStatus status;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final String shippingAddress;
  final String shippingCity;
  final String shippingPhone;
  final String? buyerNote;
  final String? sellerQrCode;
  final String? courierQrCode;
  final String? deliveryCode;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final User? buyer;
  final User? seller;
  final User? courier;
  final Product? product;
  final DateTime? createdAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.sellerId,
    this.courierId,
    required this.productId,
    this.videoId,
    required this.quantity,
    required this.unitPrice,
    required this.totalAmount,
    required this.courierFee,
    required this.platformCommission,
    required this.sellerAmount,
    this.currency = 'UZS',
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    required this.shippingCity,
    required this.shippingPhone,
    this.buyerNote,
    this.sellerQrCode,
    this.courierQrCode,
    this.deliveryCode,
    this.pickedUpAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancelReason,
    this.buyer,
    this.seller,
    this.courier,
    this.product,
    this.createdAt,
  });

  bool get canCancel =>
      status == OrderStatus.pending || status == OrderStatus.confirmed;

  bool get isCompleted => status == OrderStatus.delivered;

  bool get isCancelled => status == OrderStatus.cancelled;

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.disputed:
        return 'Disputed';
    }
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      buyerId: json['buyerId'] as String,
      sellerId: json['sellerId'] as String,
      courierId: json['courierId'] as String?,
      productId: json['productId'] as String,
      videoId: json['videoId'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      courierFee: (json['courierFee'] as num).toDouble(),
      platformCommission: (json['platformCommission'] as num).toDouble(),
      sellerAmount: (json['sellerAmount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'UZS',
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      shippingAddress: json['shippingAddress'] as String,
      shippingCity: json['shippingCity'] as String,
      shippingPhone: json['shippingPhone'] as String,
      buyerNote: json['buyerNote'] as String?,
      sellerQrCode: json['sellerQrCode'] as String?,
      courierQrCode: json['courierQrCode'] as String?,
      deliveryCode: json['deliveryCode'] as String?,
      pickedUpAt: json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      cancelReason: json['cancelReason'] as String?,
      buyer: json['buyer'] != null
          ? User.fromJson(json['buyer'] as Map<String, dynamic>)
          : null,
      seller: json['seller'] != null
          ? User.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      courier: json['courier'] != null
          ? User.fromJson(json['courier'] as Map<String, dynamic>)
          : null,
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'buyerId': buyerId,
      'sellerId': sellerId,
      'courierId': courierId,
      'productId': productId,
      'videoId': videoId,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalAmount': totalAmount,
      'courierFee': courierFee,
      'platformCommission': platformCommission,
      'sellerAmount': sellerAmount,
      'currency': currency,
      'status': status.name,
      'paymentMethod': paymentMethod.name,
      'paymentStatus': paymentStatus.name,
      'shippingAddress': shippingAddress,
      'shippingCity': shippingCity,
      'shippingPhone': shippingPhone,
      'buyerNote': buyerNote,
      'sellerQrCode': sellerQrCode,
      'courierQrCode': courierQrCode,
      'deliveryCode': deliveryCode,
      'pickedUpAt': pickedUpAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelledAt': cancelledAt?.toIso8601String(),
      'cancelReason': cancelReason,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
