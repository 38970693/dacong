import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/domain/usecases/get_content_detail.dart';
import '../../../core/domain/usecases/submit_feedback.dart';
import '../../../core/domain/repositories/i_content_repository.dart';
import '../../../core/domain/repositories/i_feedback_repository.dart';
import '../../../core/domain/entities/feedback.dart';
import '../../../core/domain/entities/content.dart';
import 'content_detail_event.dart';
import 'content_detail_state.dart';

/// ContentDetail BLoC
@injectable
class ContentDetailBloc extends Bloc<ContentDetailEvent, ContentDetailState> {
  final GetContentDetail _getContentDetail;
  final SubmitFeedback _submitFeedback;
  final IContentRepository _contentRepository;
  final IFeedbackRepository _feedbackRepository;

  ContentDetailBloc(
    this._getContentDetail,
    this._submitFeedback,
    this._contentRepository,
    this._feedbackRepository,
  ) : super(const ContentDetailState.initial()) {
    on<LoadContentDetail>(_onLoadContentDetail);
    on<SubmitFeedbackEvent>(_onSubmitFeedback);
    on<ToggleFavorite>(_onToggleFavorite);
    on<ShareContent>(_onShareContent);
  }

  Future<void> _onLoadContentDetail(
    LoadContentDetail event,
    Emitter<ContentDetailState> emit,
  ) async {
    emit(const ContentDetailState.loading());

    // 并行获取内容详情、相关推荐和用户反馈
    final contentResult = await _getContentDetail(event.contentId);
    final relatedResult = await _contentRepository.getRelatedContent(
      event.contentId,
      limit: 3,
    );
    final feedbackResult = await _feedbackRepository.getUserFeedback(
      event.contentId,
    );

    contentResult.fold(
      (failure) => emit(ContentDetailState.error(failure.message)),
      (content) {
        relatedResult.fold(
          (failure) => emit(ContentDetailState.error(failure.message)),
          (relatedContent) {
            feedbackResult.fold(
              (failure) => emit(ContentDetailState.error(failure.message)),
              (userFeedback) {
                emit(ContentDetailState.loaded(
                  content: content,
                  relatedContent: relatedContent,
                  userFeedback: userFeedback,
                  isFavorite: false, // TODO: 从本地存储获取收藏状态
                ));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onSubmitFeedback(
    SubmitFeedbackEvent event,
    Emitter<ContentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentDetailLoaded) return;

    emit(ContentDetailState.submittingFeedback(
      content: currentState.content,
      relatedContent: currentState.relatedContent,
      userFeedback: currentState.userFeedback,
      isFavorite: currentState.isFavorite,
    ));

    final result = await _submitFeedback(
      contentId: event.contentId,
      type: event.type,
      comment: event.comment,
    );

    result.fold(
      (failure) => emit(ContentDetailState.error(failure.message)),
      (feedback) {
        // 更新内容的有用/无用计数
        final updatedContent = currentState.content.copyWith(
          helpfulCount: event.type == FeedbackType.helpful
              ? currentState.content.helpfulCount + 1
              : currentState.content.helpfulCount,
          unhelpfulCount: event.type == FeedbackType.unhelpful
              ? currentState.content.unhelpfulCount + 1
              : currentState.content.unhelpfulCount,
        );

        emit(ContentDetailState.feedbackSubmitted(
          content: updatedContent,
          relatedContent: currentState.relatedContent,
          userFeedback: feedback,
          isFavorite: currentState.isFavorite,
        ));

        // 短暂显示成功状态后返回 loaded 状态
        Future.delayed(const Duration(seconds: 1), () {
          if (!emit.isDone) {
            emit(ContentDetailState.loaded(
              content: updatedContent,
              relatedContent: currentState.relatedContent,
              userFeedback: feedback,
              isFavorite: currentState.isFavorite,
            ));
          }
        });
      },
    );
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<ContentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentDetailLoaded) return;

    // TODO: 实现收藏功能（本地存储或远程API）
    final newFavoriteState = !currentState.isFavorite;

    emit(ContentDetailState.loaded(
      content: currentState.content,
      relatedContent: currentState.relatedContent,
      userFeedback: currentState.userFeedback,
      isFavorite: newFavoriteState,
    ));
  }

  Future<void> _onShareContent(
    ShareContent event,
    Emitter<ContentDetailState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ContentDetailLoaded) return;

    final content = currentState.content;

    // 生成分享文本
    final shareText = _generateShareText(content);

    try {
      // 调用系统分享
      await Share.share(
        shareText,
        subject: content.name,
      );
    } catch (e) {
      // 分享失败时不需要改变状态，只是静默失败
      // 用户会看到系统的分享对话框关闭
    }
  }

  String _generateShareText(Content content) {
    final buffer = StringBuffer();

    // 标题
    buffer.writeln('【${content.name}】');
    buffer.writeln();

    // 描述
    buffer.writeln(content.description);
    buffer.writeln();

    // 价格信息
    if (content.priceInfo.isFree) {
      buffer.writeln('💰 免费使用');
    } else if (content.priceInfo.paidDescription != null) {
      buffer.writeln('💰 ${content.priceInfo.paidDescription}');
    }

    // 国内可用性
    if (content.accessInfo.availableInChina) {
      buffer.writeln('🌏 国内可用');
    } else if (content.accessInfo.needsVpn) {
      buffer.writeln('🌏 需要VPN访问');
    }

    buffer.writeln();

    // 链接
    buffer.writeln('查看详情：https://dacong.app/content/${content.id}');

    return buffer.toString();
  }
}
