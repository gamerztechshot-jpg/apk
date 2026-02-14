import 'review.dart';

class Webinar {
  final String webinarId;
  final String teacherId;
  final String title;
  final String description;
  final String thumbnail;
  final String category;
  final double price;
  final double actualPrice;
  final String videoLink;
  final DateTime startTime;
  final DateTime endTime;
  final String webinarState;
  final String? quizId;
  final String? pdfId;
  final int fakeEnrolledCount;
  final List<Review> fakeReview;
  final double ratings;
  final bool active;
  final String status;

  Webinar({
    required this.webinarId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.category,
    required this.price,
    required this.actualPrice,
    required this.videoLink,
    required this.startTime,
    required this.endTime,
    required this.webinarState,
    this.quizId,
    this.pdfId,
    required this.fakeEnrolledCount,
    required this.fakeReview,
    required this.ratings,
    required this.active,
    required this.status,
  });

  factory Webinar.fromJson(Map<String, dynamic> json) {
    return Webinar(
      webinarId: json['webinar_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      actualPrice: (json['actual_price'] ?? 0).toDouble(),
      videoLink: json['video_link'] ?? '',
      startTime: json['start_time'] != null
          ? DateTime.parse(json['start_time'])
          : DateTime.now(),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'])
          : DateTime.now(),
      webinarState: json['webinar_state'] ?? 'scheduled',
      quizId: json['quiz_id'],
      pdfId: json['pdf_id'],
      fakeEnrolledCount: json['fake_enrolled_count'] ?? 0,
      fakeReview: (json['fake_review'] as List? ?? [])
          .map((i) => Review.fromJson(i))
          .toList(),
      ratings: (json['ratings'] ?? 0).toDouble(),
      active: json['active'] ?? true,
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'webinar_id': webinarId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'category': category,
      'price': price,
      'actual_price': actualPrice,
      'video_link': videoLink,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'webinar_state': webinarState,
      'quiz_id': quizId,
      'pdf_id': pdfId,
      'fake_enrolled_count': fakeEnrolledCount,
      'fake_review': fakeReview.map((i) => i.toJson()).toList(),
      'ratings': ratings,
      'active': active,
      'status': status,
    };
  }

  // Convenience getters
  String get id => webinarId;
  int get priceInt => actualPrice.toInt(); // Use actual price for payment
  int get actualPriceInt => actualPrice.toInt();
}
