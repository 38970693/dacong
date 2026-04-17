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
