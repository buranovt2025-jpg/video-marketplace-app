import 'user.dart';

class Product {
  final String id;
  final String sellerId;
  final String title;
  final String? titleRu;
  final String? titleUz;
  final String description;
  final String? descriptionRu;
  final String? descriptionUz;
  final double price;
  final double? originalPrice;
  final String currency;
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final List<String> images;
  final bool isActive;
  final double rating;
  final int reviewCount;
  final User? seller;
  final DateTime? createdAt;

  Product({
    required this.id,
    required this.sellerId,
    required this.title,
    this.titleRu,
    this.titleUz,
    required this.description,
    this.descriptionRu,
    this.descriptionUz,
    required this.price,
    this.originalPrice,
    this.currency = 'UZS',
    required this.category,
    this.sizes = const [],
    this.colors = const [],
    this.stock = 0,
    this.images = const [],
    this.isActive = true,
    this.rating = 0,
    this.reviewCount = 0,
    this.seller,
    this.createdAt,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > price;
  
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice! * 100);
  }

  String getLocalizedTitle(String locale) {
    switch (locale) {
      case 'ru':
        return titleRu ?? title;
      case 'uz':
        return titleUz ?? title;
      default:
        return title;
    }
  }

  String getLocalizedDescription(String locale) {
    switch (locale) {
      case 'ru':
        return descriptionRu ?? description;
      case 'uz':
        return descriptionUz ?? description;
      default:
        return description;
    }
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      title: json['title'] as String,
      titleRu: json['titleRu'] as String?,
      titleUz: json['titleUz'] as String?,
      description: json['description'] as String,
      descriptionRu: json['descriptionRu'] as String?,
      descriptionUz: json['descriptionUz'] as String?,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null
          ? (json['originalPrice'] as num).toDouble()
          : null,
      currency: json['currency'] as String? ?? 'UZS',
      category: json['category'] as String,
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>() ?? [],
      colors: (json['colors'] as List<dynamic>?)?.cast<String>() ?? [],
      stock: json['stock'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      isActive: json['isActive'] as bool? ?? true,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      seller: json['seller'] != null
          ? User.fromJson(json['seller'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'title': title,
      'titleRu': titleRu,
      'titleUz': titleUz,
      'description': description,
      'descriptionRu': descriptionRu,
      'descriptionUz': descriptionUz,
      'price': price,
      'originalPrice': originalPrice,
      'currency': currency,
      'category': category,
      'sizes': sizes,
      'colors': colors,
      'stock': stock,
      'images': images,
      'isActive': isActive,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
