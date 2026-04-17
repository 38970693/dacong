import '../../domain/entities/comment.dart';

/// 评论模型
class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.contentId,
    required super.userId,
    super.parentId,
    required super.content,
    required super.likesCount,
    required super.replyCount,
    required super.isLiked,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      contentId: json['content_id'] as String,
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

  Map<String, dynamic> toJson() {
    return {
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
  }

  Comment toEntity() {
    return Comment(
      id: id,
      contentId: contentId,
      userId: userId,
      parentId: parentId,
      content: content,
      likesCount: likesCount,
      replyCount: replyCount,
      isLiked: isLiked,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
