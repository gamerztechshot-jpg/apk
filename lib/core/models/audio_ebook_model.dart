// core/models/audio_ebook_model.dart
class AudioEbookModel {
  final int id;
  final String title;
  final String category;
  final String language;
  final String description;
  final String url;
  final List<String> images;
  final bool paid;
  final int? amount;
  final int listenersCount;
  final int readersCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  AudioEbookModel({
    required this.id,
    required this.title,
    required this.category,
    required this.language,
    required this.description,
    required this.url,
    required this.images,
    required this.paid,
    this.amount,
    required this.listenersCount,
    required this.readersCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AudioEbookModel.fromMap(Map<String, dynamic> map, String type) {
    final info = map['info'] as Map<String, dynamic>;

    return AudioEbookModel(
      id: map['id'] as int,
      title: info['title'] as String? ?? 'Untitled',
      category: info['category'] as String? ?? 'General',
      language: info['language'] as String? ?? 'English',
      description: info['description'] as String? ?? 'No description available',
      url: info['url'] as String? ?? '',
      images:
          (info['image'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      paid: info['paid'] as bool? ?? false,
      amount: info['amount'] as int?,
      listenersCount: info['listeners_count'] as int? ?? 0,
      readersCount: info['readers_count'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  String get displayImage => images.isNotEmpty ? images.first : '';
  String get type => listenersCount > 0 ? 'Audio' : 'Ebook';
  String get countText => listenersCount > 0
      ? '$listenersCount listeners'
      : '$readersCount readers';
  String get priceText =>
      paid ? (amount != null ? '₹$amount' : 'Paid') : 'Free';
}
