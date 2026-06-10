import 'package:vitta_mobile/core/utils/firestore_date_parser.dart';

class InformationPost {
  const InformationPost({
    required this.id,
    required this.title,
    required this.content,
    this.source,
    this.category,
    this.createdAt,
  });

  final String id;
  final String title;
  final String content;
  final String? source;
  final String? category;
  final DateTime? createdAt;

  factory InformationPost.fromMap(Map<String, dynamic> map) {
    return InformationPost(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      source: map['source'] as String?,
      category: map['category'] as String?,
      createdAt: dateTimeFromMap(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'source': source,
      'category': category,
      'createdAt': createdAt,
    };
  }

  InformationPost copyWith({
    String? id,
    String? title,
    String? content,
    String? source,
    String? category,
    DateTime? createdAt,
  }) {
    return InformationPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      source: source ?? this.source,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
