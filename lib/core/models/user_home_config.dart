// core/models/user_home_config.dart
import 'package:flutter/material.dart';

class UserHomeConfig {
  final String id;
  final String? image;
  final String? backgroundUrl;
  final Map<String, dynamic>? box1;
  final Map<String, dynamic>? box2;
  final Map<String, dynamic>? box3;
  final DateTime createdAt;

  UserHomeConfig({
    required this.id,
    this.image,
    this.backgroundUrl,
    this.box1,
    this.box2,
    this.box3,
    required this.createdAt,
  });

  factory UserHomeConfig.fromJson(Map<String, dynamic> json) {
    return UserHomeConfig(
      id: json['id'] ?? '',
      image: json['image'],
      backgroundUrl: json['background_url'],
      box1: json['box1'] as Map<String, dynamic>?,
      box2: json['box2'] as Map<String, dynamic>?,
      box3: json['box3'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'background_url': backgroundUrl,
      'box1': box1,
      'box2': box2,
      'box3': box3,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ContentBox {
  final String type; // 'ebook', 'audio', 'store_item', 'puja'
  final String? refId;
  final String? title;
  final String? description;
  final String? imageUrl;
  final ContentBoxType contentType;

  ContentBox({
    required this.type,
    this.refId,
    this.title,
    this.description,
    this.imageUrl,
    required this.contentType,
  });

  factory ContentBox.fromJson(Map<String, dynamic> json) {
    final type = json['type'] ?? '';

    final contentBox = ContentBox(
      type: type,
      refId: json['ref_id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image'],
      contentType: _getContentType(type),
    );

    return contentBox;
  }

  static ContentBoxType _getContentType(String type) {
    switch (type.toLowerCase()) {
      case 'ebook':
        return ContentBoxType.ebook;
      case 'audio':
        return ContentBoxType.audio;
      case 'store_item':
      case 'store':
        return ContentBoxType.store;
      case 'puja':
        return ContentBoxType.puja;
      default:
        return ContentBoxType.ebook;
    }
  }
}

enum ContentBoxType { ebook, audio, store, puja }

extension ContentBoxTypeExtension on ContentBoxType {
  Color get color {
    switch (this) {
      case ContentBoxType.ebook:
        return Colors.blue;
      case ContentBoxType.audio:
        return Colors.green;
      case ContentBoxType.store:
        return Colors.orange;
      case ContentBoxType.puja:
        return Colors.purple;
    }
  }

  String get displayName {
    switch (this) {
      case ContentBoxType.ebook:
        return 'E-Book';
      case ContentBoxType.audio:
        return 'Audio';
      case ContentBoxType.store:
        return 'Store';
      case ContentBoxType.puja:
        return 'Puja';
    }
  }

  IconData get icon {
    switch (this) {
      case ContentBoxType.ebook:
        return Icons.menu_book;
      case ContentBoxType.audio:
        return Icons.headphones;
      case ContentBoxType.store:
        return Icons.store;
      case ContentBoxType.puja:
        return Icons.temple_hindu;
    }
  }
}
