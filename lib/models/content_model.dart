import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String text;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.text,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      text: json['text'],
      imageUrl: json['imageUrl'],
      authorId: json['authorId'],
      authorName: json['authorName'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class ContentModel {
  final String id;
  final String? text;
  final List<String>? imageUrls;
  final String authorId;
  final String authorName;
  final String authorRole;
  final List<String> area;
  final DateTime createdAt;
  final List<CommentModel> comments;

  ContentModel({
    required this.id,
    this.text,
    this.imageUrls,
    required this.authorId,
    required this.authorName,
    required this.authorRole,
    required this.area,
    required this.createdAt,
    this.comments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'imageUrls': imageUrls,
      'authorId': authorId,
      'authorName': authorName,
      'authorRole': authorRole,
      'area': area,
      'createdAt': createdAt.toIso8601String(),
      'comments': comments.map((e) => e.toJson()).toList(),
    };
  }

  factory ContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentModel(
      id: doc.id,
      text: data['text'],
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : (data['imageUrl'] != null ? [data['imageUrl']] : null),
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorRole: data['authorRole'] ?? 'Unknown',
      area: List<String>.from(data['area'] ?? []),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      comments: (data['comments'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  ContentModel copyWith({
    String? id,
    String? text,
    List<String>? imageUrls,
    String? authorId,
    String? authorName,
    String? authorRole,
    List<String>? area,
    DateTime? createdAt,
    List<CommentModel>? comments,
  }) {
    return ContentModel(
      id: id ?? this.id,
      text: text ?? this.text,
      imageUrls: imageUrls ?? this.imageUrls,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      area: area ?? this.area,
      createdAt: createdAt ?? this.createdAt,
      comments: comments ?? this.comments,
    );
  }
}
