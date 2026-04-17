import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../blocs/content_detail/content_detail_bloc.dart';
import '../../blocs/content_detail/content_detail_event.dart';
import '../../blocs/content_detail/content_detail_state.dart';
import '../../widgets/content_detail/content_header.dart';
import '../../widgets/content_detail/content_info.dart';
import '../../widgets/content_detail/pros_cons_list.dart';
import '../../widgets/content_detail/alternatives_list.dart';
import '../../widgets/content_detail/feedback_section.dart';
import '../../widgets/content_detail/action_buttons.dart';
import '../../../core/analytics/analytics_service.dart';

/// 内容详情页
class ContentDetailPage extends StatefulWidget {
  final String contentId;

  const ContentDetailPage({
    super.key,
    required this.contentId,
  });

  @override
  State<ContentDetailPage> createState() => _ContentDetailPageState();
}

class _ContentDetailPageState extends State<ContentDetailPage> {
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    // 追踪内容查看
    _analytics.trackContentView(widget.contentId, 'ai_tool');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ContentDetailBloc>()
        ..add(ContentDetailEvent.loadContentDetail(widget.contentId)),
      child: Scaffold(
        body: BlocBuilder<ContentDetailBloc, ContentDetailState>(
          builder: (context, state) {
            return state.when(
              initial: () => const SizedBox.shrink(),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              loaded: (content, relatedContent, userFeedback, isFavorite) =>
                  _buildContent(
                context,
                content,
                relatedContent,
                userFeedback,
                isFavorite,
              ),
              error: (message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ContentDetailBloc>().add(
                              ContentDetailEvent.loadContentDetail(widget.contentId),
                            );
                      },
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
              submittingFeedback: (
                content,
                relatedContent,
                userFeedback,
                isFavorite,
              ) =>
                  _buildContent(
                context,
                content,
                relatedContent,
                userFeedback,
                isFavorite,
                isSubmitting: true,
              ),
              feedbackSubmitted: (
                content,
                relatedContent,
                userFeedback,
                isFavorite,
              ) =>
                  _buildContent(
                context,
                content,
                relatedContent,
                userFeedback,
                isFavorite,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    content,
    relatedContent,
    userFeedback,
    bool isFavorite, {
    bool isSubmitting = false,
  }) {
    return CustomScrollView(
      slivers: [
        // 顶部 AppBar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: ContentHeader(content: content),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : null,
              ),
              onPressed: () {
                // 追踪收藏
                _analytics.trackFavorite(widget.contentId, !isFavorite);
                context.read<ContentDetailBloc>().add(
                      ContentDetailEvent.toggleFavorite(widget.contentId),
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // 追踪分享
                _analytics.trackShare(widget.contentId, 'system');
                context.read<ContentDetailBloc>().add(
                      ContentDetailEvent.shareContent(widget.contentId),
                    );
              },
            ),
          ],
        ),

        // 内容区域
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基本信息
                ContentInfo(content: content),
                const SizedBox(height: 24),

                // 优缺点对比
                ProsConsList(
                  pros: content.features,
                  cons: [], // TODO: 从 content 获取缺点列表
                ),
                const SizedBox(height: 24),

                // 平替推荐
                if (relatedContent.isNotEmpty) ...[
                  Text(
                    '平替推荐',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  AlternativesList(alternatives: relatedContent),
                  const SizedBox(height: 24),
                ],

                // 用户反馈
                FeedbackSection(
                  content: content,
                  userFeedback: userFeedback,
                  isSubmitting: isSubmitting,
                  onFeedback: (type, comment) {
                    // 追踪反馈提交
                    _analytics.track('feedback_submit', properties: {
                      'content_id': widget.contentId,
                      'feedback_type': type,
                      'has_comment': comment?.isNotEmpty ?? false,
                    });
                    context.read<ContentDetailBloc>().add(
                          ContentDetailEvent.submitFeedback(
                            contentId: widget.contentId,
                            type: type,
                            comment: comment,
                          ),
                        );
                  },
                ),
                const SizedBox(height: 24),

                // 底部操作按钮
                ActionButtons(content: content),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
