import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/usecases/comment/get_comments.dart';
import '../../../domain/usecases/comment/submit_comment.dart' as usecases;
import '../../../domain/usecases/comment/like_comment.dart' as usecases;
import '../../../domain/usecases/comment/unlike_comment.dart' as usecases;
import '../../../domain/usecases/comment/report_comment.dart' as usecases;
import 'comment_event.dart';
import 'comment_state.dart';

/// 评论 BLoC
class CommentBloc extends Bloc<CommentEvent, CommentState> {
  final GetComments getComments;
  final usecases.SubmitComment submitComment;
  final usecases.LikeComment likeComment;
  final usecases.UnlikeComment unlikeComment;
  final usecases.ReportComment reportComment;

  String? _currentContentId;
  String? _currentParentId;

  CommentBloc({
    required this.getComments,
    required this.submitComment,
    required this.likeComment,
    required this.unlikeComment,
    required this.reportComment,
  }) : super(CommentInitial()) {
    on<LoadComments>(_onLoadComments);
    on<RefreshComments>(_onRefreshComments);
    on<SubmitComment>(_onSubmitComment);
    on<LikeComment>(_onLikeComment);
    on<UnlikeComment>(_onUnlikeComment);
    on<ReportComment>(_onReportComment);
    on<ChangeSortOrder>(_onChangeSortOrder);
    on<LoadReplies>(_onLoadReplies);
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<CommentState> emit,
  ) async {
    _currentContentId = event.contentId;
    _currentParentId = event.parentId;

    // 如果是第一页，显示加载状态
    if (event.page == 1) {
      emit(CommentLoading());
    }

    final result = await getComments(
      contentId: event.contentId,
      parentId: event.parentId,
      page: event.page,
      sort: event.sort,
    );

    result.fold(
      (failure) => emit(CommentError(message: failure.message)),
      (comments) {
        // 如果是加载更多，合并评论列表
        List<Comment> allComments = comments;
        if (state is CommentLoaded && event.page > 1) {
          final currentState = state as CommentLoaded;
          allComments = [...currentState.comments, ...comments];
        }

        emit(CommentLoaded(
          comments: allComments,
          currentPage: event.page,
          hasMore: comments.length >= 20,
          sort: event.sort,
        ));
      },
    );
  }

  Future<void> _onRefreshComments(
    RefreshComments event,
    Emitter<CommentState> emit,
  ) async {
    _currentContentId = event.contentId;
    _currentParentId = event.parentId;

    final result = await getComments(
      contentId: event.contentId,
      parentId: event.parentId,
      page: 1,
      sort: event.sort,
    );

    result.fold(
      (failure) => emit(CommentError(message: failure.message)),
      (comments) => emit(CommentLoaded(
        comments: comments,
        currentPage: 1,
        hasMore: comments.length >= 20,
        sort: event.sort,
      )),
    );
  }

  Future<void> _onSubmitComment(
    SubmitComment event,
    Emitter<CommentState> emit,
  ) async {
    // 保存当前评论列表
    List<Comment> existingComments = [];
    if (state is CommentLoaded) {
      existingComments = (state as CommentLoaded).comments;
    }

    emit(CommentSubmitting(existingComments));

    final result = await submitComment(
      contentId: event.contentId,
      content: event.content,
      parentId: event.parentId,
    );

    result.fold(
      (failure) => emit(CommentError(
        message: failure.message,
        existingComments: existingComments,
      )),
      (newComment) {
        // 将新评论添加到列表顶部
        final allComments = <Comment>[newComment, ...existingComments];
        emit(CommentSubmitted(
          newComment: newComment,
          allComments: allComments,
        ));

        // 自动转换为 Loaded 状态
        emit(CommentLoaded(
          comments: allComments,
          currentPage: 1,
          hasMore: true,
          sort: 'latest',
        ));
      },
    );
  }

  Future<void> _onLikeComment(
    LikeComment event,
    Emitter<CommentState> emit,
  ) async {
    if (state is! CommentLoaded) return;

    final currentState = state as CommentLoaded;
    final comments = currentState.comments;

    // 乐观更新：立即更新 UI
    final updatedComments = comments.map((comment) {
      if (comment.id == event.commentId) {
        return comment.copyWith(
          isLiked: true,
          likesCount: comment.likesCount + 1,
        );
      }
      return comment;
    }).toList();

    emit(currentState.copyWith(comments: updatedComments));

    // 执行实际的点赞操作
    final result = await likeComment(event.commentId);

    result.fold(
      (failure) {
        // 失败时回滚
        emit(currentState.copyWith(comments: comments));
        emit(CommentError(
          message: failure.message,
          existingComments: comments,
        ));
      },
      (_) {
        // 成功，保持当前状态
      },
    );
  }

  Future<void> _onUnlikeComment(
    UnlikeComment event,
    Emitter<CommentState> emit,
  ) async {
    if (state is! CommentLoaded) return;

    final currentState = state as CommentLoaded;
    final comments = currentState.comments;

    // 乐观更新：立即更新 UI
    final updatedComments = comments.map((comment) {
      if (comment.id == event.commentId) {
        return comment.copyWith(
          isLiked: false,
          likesCount: comment.likesCount > 0 ? comment.likesCount - 1 : 0,
        );
      }
      return comment;
    }).toList();

    emit(currentState.copyWith(comments: updatedComments));

    // 执行实际的取消点赞操作
    final result = await unlikeComment(event.commentId);

    result.fold(
      (failure) {
        // 失败时回滚
        emit(currentState.copyWith(comments: comments));
        emit(CommentError(
          message: failure.message,
          existingComments: comments,
        ));
      },
      (_) {
        // 成功，保持当前状态
      },
    );
  }

  Future<void> _onReportComment(
    ReportComment event,
    Emitter<CommentState> emit,
  ) async {
    if (state is! CommentLoaded) return;

    final currentState = state as CommentLoaded;

    final result = await reportComment(
      commentId: event.commentId,
      reason: event.reason,
    );

    result.fold(
      (failure) => emit(CommentError(
        message: failure.message,
        existingComments: currentState.comments,
      )),
      (_) {
        emit(CommentActionSuccess(
          message: 'Comment reported successfully',
          comments: currentState.comments,
        ));

        // 自动转换回 Loaded 状态
        emit(currentState);
      },
    );
  }

  Future<void> _onChangeSortOrder(
    ChangeSortOrder event,
    Emitter<CommentState> emit,
  ) async {
    if (_currentContentId == null) return;

    emit(CommentLoading());

    final result = await getComments(
      contentId: _currentContentId!,
      parentId: _currentParentId,
      page: 1,
      sort: event.sort,
    );

    result.fold(
      (failure) => emit(CommentError(message: failure.message)),
      (comments) => emit(CommentLoaded(
        comments: comments,
        currentPage: 1,
        hasMore: comments.length >= 20,
        sort: event.sort,
      )),
    );
  }

  Future<void> _onLoadReplies(
    LoadReplies event,
    Emitter<CommentState> emit,
  ) async {
    emit(CommentRepliesLoading(parentId: event.parentId));

    final result = await getComments(
      contentId: event.contentId,
      parentId: event.parentId,
      page: event.page,
      sort: event.sort,
    );

    result.fold(
      (failure) => emit(CommentError(message: failure.message)),
      (replies) => emit(CommentRepliesLoaded(
        parentId: event.parentId,
        replies: replies,
      )),
    );
  }
}
