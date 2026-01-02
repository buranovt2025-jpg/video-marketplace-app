import 'user.dart';
import 'product.dart';

class Video {
  final String id;
  final String sellerId;
  final String? productId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String title;
  final String? titleRu;
  final String? titleUz;
  final String? description;
  final String? descriptionRu;
  final String? descriptionUz;
  final int duration;
  final int viewCount;
  final int likeCount;
  final bool isLive;
  final bool isActive;
  final User? seller;
  final Product? product;
  final DateTime? createdAt;

  Video({
    required this.id,
    required this.sellerId,
    this.productId,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.title,
    this.titleRu,
    this.titleUz,
    this.description,
    this.descriptionRu,
    this.descriptionUz,
    this.duration = 0,
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLive = false,
    this.isActive = true,
    this.seller,
    this.product,
    this.createdAt,
  });

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

  String? getLocalizedDescription(String locale) {
    switch (locale) {
      case 'ru':
        return descriptionRu ?? description;
      case 'uz':
        return descriptionUz ?? description;
      default:
        return description;
    }
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedViewCount {
    if (viewCount >= 1000000) {
      return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    } else if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}K';
    }
    return viewCount.toString();
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      sellerId: json['sellerId'] as String,
      productId: json['productId'] as String?,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      title: json['title'] as String,
      titleRu: json['titleRu'] as String?,
      titleUz: json['titleUz'] as String?,
      description: json['description'] as String?,
      descriptionRu: json['descriptionRu'] as String?,
      descriptionUz: json['descriptionUz'] as String?,
      duration: json['duration'] as int? ?? 0,
      viewCount: json['viewCount'] as int? ?? 0,
      likeCount: json['likeCount'] as int? ?? 0,
      isLive: json['isLive'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      seller: json['seller'] != null
          ? User.fromJson(json['seller'] as Map<String, dynamic>)
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
      'sellerId': sellerId,
      'productId': productId,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'title': title,
      'titleRu': titleRu,
      'titleUz': titleUz,
      'description': description,
      'descriptionRu': descriptionRu,
      'descriptionUz': descriptionUz,
      'duration': duration,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'isLive': isLive,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
