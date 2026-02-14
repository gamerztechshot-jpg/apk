// core/models/puja_model.dart
import 'dart:convert';

class PujaModel {
  final int id;
  final PujaBasic pujaBasic;
  final PujaBasic pujaBasicHi;
  final String category; // Added category field
  final DateTime? eventDate;
  final DateTime? bookingClosesAt;
  final DateTime? date; // Your actual database column
  final int devoteeCount;
  final List<String> devoteeImages;
  final List<String> pujaImages; // New field for puja images
  final PujaContent content;
  final PujaContent contentHi;
  final TempleDetails templeDetails;
  final TempleDetails templeDetailsHi;
  final List<PujaPackage> packages;
  final List<PujaPackage> packagesHi;
  final List<PujaReview> reviews;
  final List<PujaReview> reviewsHi;
  final DateTime createdAt;

  PujaModel({
    required this.id,
    required this.pujaBasic,
    required this.pujaBasicHi,
    required this.category,
    this.eventDate,
    this.bookingClosesAt,
    this.date,
    required this.devoteeCount,
    required this.devoteeImages,
    required this.pujaImages,
    required this.content,
    required this.contentHi,
    required this.templeDetails,
    required this.templeDetailsHi,
    required this.packages,
    required this.packagesHi,
    required this.reviews,
    required this.reviewsHi,
    required this.createdAt,
  });

  factory PujaModel.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    List<String> _parseImages(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v.map((e) => e.toString()).toList();
      }
      if (v is String) {
        // Try to decode JSON array from text column, else comma-separated
        try {
          final decoded = jsonDecode(v);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // Not JSON, fall back to comma-separated string
        }
        return v
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    }

    return PujaModel(
      id: json['id'],
      pujaBasic: PujaBasic.fromJson(json['puja_basic'] ?? const {}),
      pujaBasicHi: PujaBasic.fromJson(json['puja_basic_hi'] ?? const {}),
      category: json['category'] ?? '',
      eventDate: _parseDate(json['event_date']),
      bookingClosesAt: _parseDate(json['booking_closes_at']),
      date: _parseDate(json['date']),
      devoteeCount: (json['devotee_count'] ?? 0) as int,
      devoteeImages: _parseImages(json['devotee_images']),
      pujaImages: _parseImages(json['puja_images']),
      content: PujaContent.fromJson(json['content'] ?? const {}),
      contentHi: PujaContent.fromJson(json['content_hi'] ?? const {}),
      templeDetails: TempleDetails.fromJson(json['temple_details'] ?? const {}),
      templeDetailsHi: TempleDetails.fromJson(
        json['temple_details_hi'] ?? const {},
      ),
      packages: ((json['packages'] ?? []) as List)
          .map((pkg) => PujaPackage.fromJson(pkg))
          .toList(),
      packagesHi: ((json['packages_hi'] ?? []) as List)
          .map((pkg) => PujaPackage.fromJson(pkg))
          .toList(),
      reviews: ((json['reviews'] ?? []) as List)
          .map((review) => PujaReview.fromJson(review))
          .toList(),
      reviewsHi: ((json['reviews_hi'] ?? []) as List)
          .map((review) => PujaReview.fromJson(review))
          .toList(),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puja_basic': pujaBasic.toJson(),
      'puja_basic_hi': pujaBasicHi.toJson(),
      'category': category,
      'event_date': eventDate?.toIso8601String().split('T')[0],
      'booking_closes_at': bookingClosesAt?.toIso8601String(),
      'date': date?.toIso8601String().split('T')[0],
      'devotee_count': devoteeCount,
      'devotee_images': devoteeImages,
      'puja_images': pujaImages,
      'content': content.toJson(),
      'content_hi': contentHi.toJson(),
      'temple_details': templeDetails.toJson(),
      'temple_details_hi': templeDetailsHi.toJson(),
      'packages': packages.map((pkg) => pkg.toJson()).toList(),
      'packages_hi': packagesHi.map((pkg) => pkg.toJson()).toList(),
      'reviews': reviews.map((review) => review.toJson()).toList(),
      'reviews_hi': reviewsHi.map((review) => review.toJson()).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class PujaBasic {
  final String name;
  final String title;
  final String shortDescription;
  final String location;
  final String? panditId; // Added pandit_id field

  PujaBasic({
    required this.name,
    required this.title,
    required this.shortDescription,
    required this.location,
    this.panditId,
  });

  factory PujaBasic.fromJson(Map<String, dynamic> json) {
    return PujaBasic(
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      shortDescription: json['short_description'] ?? '',
      location: json['location'] ?? '',
      panditId: json['pandit_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'short_description': shortDescription,
      'location': location,
      'pandit_id': panditId,
    };
  }
}

class PujaContent {
  final String aboutPuja;
  final String benefits;
  final String process;

  PujaContent({
    required this.aboutPuja,
    required this.benefits,
    required this.process,
  });

  factory PujaContent.fromJson(Map<String, dynamic> json) {
    return PujaContent(
      aboutPuja: json['about_puja'] ?? '',
      benefits: json['benefits'] ?? '',
      process: json['process'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'about_puja': aboutPuja, 'benefits': benefits, 'process': process};
  }
}

class TempleDetails {
  final String heading;
  final String url;
  final String description;

  TempleDetails({
    required this.heading,
    required this.url,
    required this.description,
  });

  factory TempleDetails.fromJson(Map<String, dynamic> json) {
    return TempleDetails(
      heading: json['heading'] ?? '',
      url: json['url'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'heading': heading, 'url': url, 'description': description};
  }
}

class PujaPackage {
  final String name;
  final int price;
  final String description;
  final String url;

  PujaPackage({
    required this.name,
    required this.price,
    required this.description,
    required this.url,
  });

  factory PujaPackage.fromJson(Map<String, dynamic> json) {
    return PujaPackage(
      name: json['name'] ?? '',
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'url': url,
    };
  }
}

class PujaReview {
  final String name;
  final String url;
  final String reviewText;

  PujaReview({required this.name, required this.url, required this.reviewText});

  factory PujaReview.fromJson(Map<String, dynamic> json) {
    return PujaReview(
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      reviewText: json['review_text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'url': url, 'review_text': reviewText};
  }
}
