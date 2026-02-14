// core/models/store.dart

class Store {
  final String id;
  final String nameEn;
  final String nameHi;
  final String descriptionEn;
  final String descriptionHi;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final List<String> sizes;
  final List<String> colors;
  final List<Review> reviews;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.descriptionEn,
    required this.descriptionHi,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.images = const [],
    this.category = 'General',
    this.sizes = const [],
    this.colors = const [],
    this.reviews = const [],
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameHi: json['name_hi'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      descriptionHi: json['description_hi'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      originalPrice: json['original_price'] != null
          ? (json['original_price'] as num).toDouble()
          : null,
      imageUrl: json['image_url'],
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] ?? 'General',
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((review) => Review.fromJson(review))
              .toList() ??
          [],
      isAvailable: json['is_available'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_en': nameEn,
      'name_hi': nameHi,
      'description_en': descriptionEn,
      'description_hi': descriptionHi,
      'price': price,
      'original_price': originalPrice,
      'image_url': imageUrl,
      'images': images,
      'category': category,
      'sizes': sizes,
      'colors': colors,
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Store copyWith({
    String? id,
    String? nameEn,
    String? nameHi,
    String? descriptionEn,
    String? descriptionHi,
    double? price,
    double? originalPrice,
    String? imageUrl,
    List<String>? images,
    String? category,
    List<String>? sizes,
    List<String>? colors,
    List<Review>? reviews,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Store(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      descriptionHi: descriptionHi ?? this.descriptionHi,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      category: category ?? this.category,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      reviews: reviews ?? this.reviews,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Store(id: $id, nameEn: $nameEn, nameHi: $nameHi, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Store &&
        other.id == id &&
        other.nameEn == nameEn &&
        other.nameHi == nameHi &&
        other.price == price;
  }

  @override
  int get hashCode {
    return id.hashCode ^ nameEn.hashCode ^ nameHi.hashCode ^ price.hashCode;
  }
}

class Review {
  final String id;
  final String reviewerNameEn;
  final String reviewerNameHi;
  final int rating;
  final String commentEn;
  final String commentHi;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reviewerNameEn,
    required this.reviewerNameHi,
    required this.rating,
    required this.commentEn,
    required this.commentHi,
    required this.createdAt,
  });

  // Helper getters for backward compatibility
  String get reviewerName =>
      reviewerNameEn.isNotEmpty ? reviewerNameEn : reviewerNameHi;
  String get comment => commentEn.isNotEmpty ? commentEn : commentHi;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      reviewerNameEn: json['reviewer_name_en'] ?? json['name_en'] ?? '',
      reviewerNameHi: json['reviewer_name_hi'] ?? json['name_hi'] ?? '',
      rating: json['rating'] ?? 5,
      commentEn: json['comment_en'] ?? '',
      commentHi: json['comment_hi'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_name_en': reviewerNameEn,
      'reviewer_name_hi': reviewerNameHi,
      'rating': rating,
      'comment_en': commentEn,
      'comment_hi': commentHi,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? reviewerNameEn,
    String? reviewerNameHi,
    int? rating,
    String? commentEn,
    String? commentHi,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerNameEn: reviewerNameEn ?? this.reviewerNameEn,
      reviewerNameHi: reviewerNameHi ?? this.reviewerNameHi,
      rating: rating ?? this.rating,
      commentEn: commentEn ?? this.commentEn,
      commentHi: commentHi ?? this.commentHi,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Review(id: $id, reviewerName: $reviewerName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review &&
        other.id == id &&
        other.reviewerName == reviewerName &&
        other.rating == rating;
  }

  @override
  int get hashCode {
    return id.hashCode ^ reviewerName.hashCode ^ rating.hashCode;
  }
}
