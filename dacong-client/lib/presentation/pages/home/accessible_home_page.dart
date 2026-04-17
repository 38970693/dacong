import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/recommendation/recommendation_bloc.dart';
import '../../widgets/accessible_recommendation_card.dart';
import '../../widgets/accessible_scenario_selector.dart';
import '../../../core/di/injection.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/accessibility/accessibility_utils.dart';

/// 首页 - 场景选择 + 推荐列表 (带无障碍支持)
class AccessibleHomePage extends StatelessWidget {
  const AccessibleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: '首页',
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(
            header: true,
            child: Text(l10n.homeTitle),
          ),
          actions: [
            Semantics(
              label: '搜索',
              hint: '双击打开搜索页面',
              button: true,
              child: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => context.push('/search'),
                tooltip: '搜索',
              ),
            ),
          ],
        ),
        body: BlocProvider(
          create: (_) => getIt<RecommendationBloc>(),
          child: const _AccessibleHomeContent(),
        ),
      ),
    );
  }
}

class _AccessibleHomeContent extends StatefulWidget {
  const _AccessibleHomeContent();

  @override
  State<_AccessibleHomeContent> createState() => _AccessibleHomeContentState();
}

class _AccessibleHomeContentState extends State<_AccessibleHomeContent> {
  String? _selectedScenario;
  final ScrollController _scrollController = ScrollController();
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 追踪页面浏览
    _analytics.trackPageView('home');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && _selectedScenario != null) {
      context.read<RecommendationBloc>().add(
            LoadMoreRecommendations(_selectedScenario!),
          );
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        // 场景选择器 (带无障碍支持)
        AccessibleScenarioSelector(
          selectedScenario: _selectedScenario,
          onScenarioSelected: (scenario) {
            setState(() {
              _selectedScenario = scenario;
            });
            // 追踪场景选择
            _analytics.track('scenario_select', properties: {
              'scenario_id': scenario,
            });
            // 宣布给屏幕阅读器
            AccessibilityUtils.announce(
              context,
              '已选择场景: $scenario',
            );
            context.read<RecommendationBloc>().add(
                  LoadRecommendations(scenario),
                );
          },
        ),
        const SizedBox(height: 16),
        // 推荐列表
        Expanded(
          child: BlocBuilder<RecommendationBloc, RecommendationState>(
            builder: (context, state) {
              if (state is RecommendationInitial) {
                return Semantics(
                  label: '请选择一个场景以查看推荐',
                  child: Center(
                    child: Text(l10n.pleaseSelectScenario),
                  ),
                );
              } else if (state is RecommendationLoading) {
                return Semantics(
                  label: '正在加载推荐内容',
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else if (state is RecommendationLoaded) {
                if (state.recommendations.isEmpty) {
                  return Semantics(
                    label: '暂无推荐内容',
                    child: Center(
                      child: Text(l10n.noRecommendations),
                    ),
                  );
                }
                return Semantics(
                  label: '推荐列表，共${state.recommendations.length}项',
                  child: RefreshIndicator(
                    onRefresh: () async {
                      if (_selectedScenario != null) {
                        context.read<RecommendationBloc>().add(
                              RefreshRecommendations(_selectedScenario!),
                            );
                        // 等待状态更新
                        await Future.delayed(const Duration(milliseconds: 500));
                      }
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: state.recommendations.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.recommendations.length) {
                          return Semantics(
                            label: state.isLoadingMore ? '正在加载更多' : '',
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: state.isLoadingMore
                                    ? const CircularProgressIndicator()
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          );
                        }
                        final recommendation = state.recommendations[index];
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          child: AccessibleRecommendationCard(
                            recommendation: recommendation,
                            onTap: () {
                              // 追踪内容点击
                              _analytics.track('content_click', properties: {
                                'content_id': recommendation.contentId,
                                'scenario': _selectedScenario,
                                'position': index,
                              });
                              // 宣布导航
                              AccessibilityUtils.announce(
                                context,
                                '正在打开${recommendation.toolName}详情',
                              );
                              context.push(
                                '/content/${recommendation.contentId}',
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                );
              } else if (state is RecommendationError) {
                return Semantics(
                  label: '加载失败: ${state.message}',
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        Semantics(
                          label: '重试按钮',
                          hint: '双击重新加载推荐内容',
                          button: true,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_selectedScenario != null) {
                                context.read<RecommendationBloc>().add(
                                      LoadRecommendations(_selectedScenario!),
                                    );
                                AccessibilityUtils.announce(
                                  context,
                                  '正在重新加载',
                                );
                              }
                            },
                            child: Text(l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
