import 'review.dart';

class Lesson {
  final String title;
  final String? description;
  final String? link;
  final String? quizId;
  final String? pdfId;

  Lesson({
    required this.title,
    this.description,
    this.link,
    this.quizId,
    this.pdfId,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      title: json['title'] ?? '',
      description: json['description'],
      link: json['link'],
      quizId: json['quiz_id'],
      pdfId: json['pdf_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'quiz_id': quizId,
      'pdf_id': pdfId,
    };
  }
}

class Course {
  final String courseId;
  final String teacherId;
  final String title;
  final String description;
  final String thumbnail;
  final String category;
  final double price;
  final double actualPrice;
  final List<Lesson> playlist;
  final int fakeEnrolledCount;
  final List<Review> fakeReview;
  final double ratings;
  final bool active;
  final String status;
  final DateTime createdAt;

  Course({
    required this.courseId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.category,
    required this.price,
    required this.actualPrice,
    required this.playlist,
    required this.fakeEnrolledCount,
    required this.fakeReview,
    required this.ratings,
    required this.active,
    required this.status,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'] ?? '',
      teacherId: json['teacher_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      category: json['category'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      actualPrice: (json['actual_price'] ?? 0).toDouble(),
      playlist: (json['playlist'] as List? ?? [])
          .map((i) => Lesson.fromJson(i))
          .toList(),
      fakeEnrolledCount: json['fake_enrolled_count'] ?? 0,
      fakeReview: (json['fake_review'] as List? ?? [])
          .map((i) => Review.fromJson(i))
          .toList(),
      ratings: (json['ratings'] ?? 0).toDouble(),
      active: json['active'] ?? true,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'teacher_id': teacherId,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'category': category,
      'price': price,
      'actual_price': actualPrice,
      'playlist': playlist.map((i) => i.toJson()).toList(),
      'fake_enrolled_count': fakeEnrolledCount,
      'fake_review': fakeReview.map((i) => i.toJson()).toList(),
      'ratings': ratings,
      'active': active,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get instructor => 'Karmasu Instructor';

  // Convenience getters
  String get id => courseId;
  List<Lesson> get lessons => playlist;
  int get priceInt => actualPrice.toInt(); // Use actual price for payment
  int get actualPriceInt => actualPrice.toInt();
}
