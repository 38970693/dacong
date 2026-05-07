import 'package:equatable/equatable.dart';

/// 评论实体
class Comment extends Equatable {
  final String id;
  final String contentId;
  final String userId;
  final String? parentId;
  final String content;
  final int likesCount;
  final int replyCount;
  final bool isLiked;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.contentId,
    required this.userId,
    this.parentId,
    required this.content,
    required this.likesCount,
    required this.replyCount,
    required this.isLiked,
    required this.createdAt,
    required this.updatedAt,
  });

  Comment copyWith({
    String? id,
    String? contentId,
    String? userId,
    String? parentId,
    String? content,
    int? likesCount,
    int? replyCount,
    bool? isLiked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Comment(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      userId: userId ?? this.userId,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      replyCount: replyCount ?? this.replyCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      contentId: json['content_id'] as String? ?? json['post_id'] as String,
      userId: json['user_id'] as String,
      parentId: json['parent_id'] as String?,
      content: json['content'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      replyCount: json['reply_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content_id': contentId,
        'user_id': userId,
        'parent_id': parentId,
        'content': content,
        'likes_count': likesCount,
        'reply_count': replyCount,
        'is_liked': isLiked,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        contentId,
        userId,
        parentId,
        content,
        likesCount,
        replyCount,
        isLiked,
        createdAt,
        updatedAt,
      ];
}
