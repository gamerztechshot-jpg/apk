class Review {
  final String name;
  final double rating;
  final String review;

  Review({required this.name, required this.rating, required this.review});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      review: json['review'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'rating': rating, 'review': review};
  }
}
