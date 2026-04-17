import 'package:equatable/equatable.dart';

/// 评论事件基类
abstract class CommentEvent extends Equatable {
  const CommentEvent();

  @override
  List<Object?> get props => [];
}

/// 加载评论列表
class LoadComments extends CommentEvent {
  final String contentId;
  final String? parentId;
  final int page;
  final String sort;

  const LoadComments({
    required this.contentId,
    this.parentId,
    this.page = 1,
    this.sort = 'latest',
  });

  @override
  List<Object?> get props => [contentId, parentId, page, sort];
}

/// 刷新评论列表
class RefreshComments extends CommentEvent {
  final String contentId;
  final String? parentId;
  final String sort;

  const RefreshComments({
    required this.contentId,
    this.parentId,
    this.sort = 'latest',
  });

  @override
  List<Object?> get props => [contentId, parentId, sort];
}

/// 提交评论
class SubmitComment extends CommentEvent {
  final String contentId;
  final String content;
  final String? parentId;

  const SubmitComment({
    required this.contentId,
    required this.content,
    this.parentId,
  });

  @override
  List<Object?> get props => [contentId, content, parentId];
}

/// 点赞评论
class LikeComment extends CommentEvent {
  final String commentId;

  const LikeComment(this.commentId);

  @override
  List<Object> get props => [commentId];
}

/// 取消点赞
class UnlikeComment extends CommentEvent {
  final String commentId;

  const UnlikeComment(this.commentId);

  @override
  List<Object> get props => [commentId];
}

/// 举报评论
class ReportComment extends CommentEvent {
  final String commentId;
  final String? reason;

  const ReportComment({
    required this.commentId,
    this.reason,
  });

  @override
  List<Object?> get props => [commentId, reason];
}

/// 切换排序方式
class ChangeSortOrder extends CommentEvent {
  final String sort;

  const ChangeSortOrder(this.sort);

  @override
  List<Object> get props => [sort];
}

/// 加载回复列表
class LoadReplies extends CommentEvent {
  final String contentId;
  final String parentId;
  final int page;
  final String sort;

  const LoadReplies({
    required this.contentId,
    required this.parentId,
    this.page = 1,
    this.sort = 'latest',
  });

  @override
  List<Object> get props => [contentId, parentId, page, sort];
}
