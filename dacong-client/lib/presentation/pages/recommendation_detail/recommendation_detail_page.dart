import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/di/injection.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../blocs/recommendation/recommendation_bloc.dart';
import '../../widgets/recommendation_card.dart';

/// 推荐内容详情页
class RecommendationDetailPage extends StatefulWidget {
  final String contentId;

  const RecommendationDetailPage({
    super.key,
    required this.contentId,
  });

  @override
  State<RecommendationDetailPage> createState() =>
      _RecommendationDetailPageState();
}

class _RecommendationDetailPageState extends State<RecommendationDetailPage> {
  final _analytics = AnalyticsService();
  bool _isHelpful = false;
  bool _isUnhelpful = false;
  bool _feedbackSubmitted = false;

  @override
  void initState() {
    super.initState();
    _analytics.trackPageView('recommendation_detail');
    _analytics.track('content_view', properties: {
      'content_id': widget.contentId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (_) => getIt<RecommendationBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('推荐详情'),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _handleShare(context),
            ),
          ],
        ),
        body: BlocBuilder<RecommendationBloc, RecommendationState>(
          builder: (context, state) {
            // 模拟加载推荐详情（实际应该从API获取）
            // 这里简化处理，直接显示内容
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContentSection(context, l10n),
                  const Divider(height: 32),
                  _buildFeedbackSection(context, l10n),
                  const Divider(height: 32),
                  _buildRelatedRecommendations(context, l10n, state),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, AppLocalizations l10n) {
    // 这里应该从API获取完整的内容详情
    // 暂时使用占位内容
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 工具名称和评分
          Row(
            children: [
              Expanded(
                child: Text(
                  '工具详情',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              _buildRatingChip(4.8),
            ],
          ),
          const SizedBox(height: 16),

          // 一句话描述
          Text(
            '这是一个强大的AI工具，帮助你提高工作效率',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          const SizedBox(height: 24),

          // 优点
          _buildSection(
            context,
            '优点',
            [
              '功能强大，易于使用',
              '性价比高',
              '社区活跃，文档完善',
            ],
            Colors.green,
            Icons.check_circle_outline,
          ),
          const SizedBox(height: 16),

          // 缺点
          _buildSection(
            context,
            '缺点',
            [
              '学习曲线较陡',
              '部分功能需要付费',
            ],
            Colors.orange,
            Icons.warning_amber_outlined,
          ),
          const SizedBox(height: 16),

          // 适合人群
          _buildInfoRow(
            context,
            Icons.people,
            '适合人群',
            '专业开发者、技术团队',
          ),
          const SizedBox(height: 8),

          // 价格
          _buildInfoRow(
            context,
            Icons.attach_money,
            '价格',
            r'¥99/月 或 $20/月',
          ),
          const SizedBox(height: 8),

          // 国内可用性
          _buildInfoRow(
            context,
            Icons.public,
            '国内可用性',
            '需要VPN访问',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '这个推荐对你有帮助吗？',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _feedbackSubmitted
                      ? null
                      : () => _handleFeedback(true),
                  icon: Icon(
                    _isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
                    color: _isHelpful ? Colors.green : null,
                  ),
                  label: Text(
                    '有帮助',
                    style: TextStyle(
                      color: _isHelpful ? Colors.green : null,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: _isHelpful ? Colors.green : Colors.grey,
                      width: _isHelpful ? 2 : 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _feedbackSubmitted
                      ? null
                      : () => _handleFeedback(false),
                  icon: Icon(
                    _isUnhelpful
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    color: _isUnhelpful ? Colors.red : null,
                  ),
                  label: Text(
                    '没帮助',
                    style: TextStyle(
                      color: _isUnhelpful ? Colors.red : null,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(
                      color: _isUnhelpful ? Colors.red : Colors.grey,
                      width: _isUnhelpful ? 2 : 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_feedbackSubmitted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '感谢你的反馈！',
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelatedRecommendations(
    BuildContext context,
    AppLocalizations l10n,
    RecommendationState state,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '相关推荐',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (state is RecommendationLoaded &&
              state.recommendations.isNotEmpty) ...[
            ...state.recommendations.take(3).map((recommendation) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RecommendationCard(
                  recommendation: recommendation,
                  onTap: () {
                    _analytics.track('related_content_click', properties: {
                      'from_content_id': widget.contentId,
                      'to_content_id': recommendation.id,
                    });
                    context.push(
                      '/recommendation/${recommendation.id}',
                    );
                  },
                ),
              );
            }),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  '暂无相关推荐',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingChip(double rating) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 20, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<String> items,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 28, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? Colors.grey[700]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color ?? Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }

  void _handleFeedback(bool isHelpful) {
    setState(() {
      _isHelpful = isHelpful;
      _isUnhelpful = !isHelpful;
      _feedbackSubmitted = true;
    });

    _analytics.track('feedback_submit', properties: {
      'content_id': widget.contentId,
      'is_helpful': isHelpful,
    });

    // 调用API提交反馈（待实现）
  }

  Future<void> _handleShare(BuildContext context) async {
    _analytics.track('content_share', properties: {
      'content_id': widget.contentId,
    });

    // 生成分享文本
    final shareText = _generateShareText();

    try {
      // 调用系统分享
      await Share.share(
        shareText,
        subject: '工具推荐',
      );
    } catch (e) {
      // 分享失败，显示错误提示
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('分享失败，请稍后重试'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _generateShareText() {
    final buffer = StringBuffer();

    // 标题
    buffer.writeln('【工具推荐】');
    buffer.writeln();

    // 描述
    buffer.writeln('这是一个强大的AI工具，帮助你提高工作效率');
    buffer.writeln();

    // 优点
    buffer.writeln('✅ 优点：');
    buffer.writeln('• 功能强大，易于使用');
    buffer.writeln('• 性价比高');
    buffer.writeln('• 社区活跃，文档完善');
    buffer.writeln();

    // 价格
    buffer.writeln('💰 价格：¥99/月 或 \$20/月');
    buffer.writeln();

    // 链接
    buffer.writeln('查看详情：https://dacong.app/recommendation/${widget.contentId}');

    return buffer.toString();
  }
}
