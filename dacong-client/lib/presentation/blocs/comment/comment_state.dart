import 'package:equatable/equatable.dart';
import '../../../domain/entities/comment.dart';

/// 评论状态基类
abstract class CommentState extends Equatable {
  const CommentState();

  @override
  List<Object?> get props => [];
}

/// 初始状态
class CommentInitial extends CommentState {}

/// 加载中
class CommentLoading extends CommentState {}

/// 加载成功
class CommentLoaded extends CommentState {
  final List<Comment> comments;
  final int currentPage;
  final bool hasMore;
  final String sort;

  const CommentLoaded({
    required this.comments,
    required this.currentPage,
    required this.hasMore,
    required this.sort,
  });

  @override
  List<Object> get props => [comments, currentPage, hasMore, sort];

  CommentLoaded copyWith({
    List<Comment>? comments,
    int? currentPage,
    bool? hasMore,
    String? sort,
  }) {
    return CommentLoaded(
      comments: comments ?? this.comments,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
    );
  }
}

/// 提交中
class CommentSubmitting extends CommentState {
  final List<Comment> existingComments;

  const CommentSubmitting(this.existingComments);

  @override
  List<Object> get props => [existingComments];
}

/// 提交成功
class CommentSubmitted extends CommentState {
  final Comment newComment;
  final List<Comment> allComments;

  const CommentSubmitted({
    required this.newComment,
    required this.allComments,
  });

  @override
  List<Object> get props => [newComment, allComments];
}

/// 操作成功（点赞、举报等）
class CommentActionSuccess extends CommentState {
  final String message;
  final List<Comment> comments;

  const CommentActionSuccess({
    required this.message,
    required this.comments,
  });

  @override
  List<Object> get props => [message, comments];
}

/// 错误状态
class CommentError extends CommentState {
  final String message;
  final List<Comment>? existingComments;

  const CommentError({
    required this.message,
    this.existingComments,
  });

  @override
  List<Object?> get props => [message, existingComments];
}

/// 回复加载中
class CommentRepliesLoading extends CommentState {
  final String parentId;

  const CommentRepliesLoading({required this.parentId});

  @override
  List<Object> get props => [parentId];
}

/// 回复加载成功
class CommentRepliesLoaded extends CommentState {
  final String parentId;
  final List<Comment> replies;

  const CommentRepliesLoaded({
    required this.parentId,
    required this.replies,
  });

  @override
  List<Object> get props => [parentId, replies];
}
