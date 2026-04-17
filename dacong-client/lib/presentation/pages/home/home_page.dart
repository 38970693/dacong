import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../blocs/recommendation/recommendation_bloc.dart';
import '../../widgets/recommendation_card.dart';
import '../../widgets/scenario_selector.dart';
import '../../../core/di/injection.dart';
import '../../../core/analytics/analytics_service.dart';

/// 首页 - 场景选择 + 推荐列表
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: BlocProvider(
        create: (_) => getIt<RecommendationBloc>(),
        child: const _HomeContent(),
      ),
    );
  }
}

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
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
        // 场景选择器
        ScenarioSelector(
          selectedScenario: _selectedScenario,
          onScenarioSelected: (scenario) {
            setState(() {
              _selectedScenario = scenario;
            });
            // 追踪场景选择
            _analytics.track('scenario_select', properties: {
              'scenario_id': scenario,
            });
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
                return Center(
                  child: Text(l10n.pleaseSelectScenario),
                );
              } else if (state is RecommendationLoading) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              } else if (state is RecommendationLoaded) {
                if (state.recommendations.isEmpty) {
                  return Center(
                    child: Text(l10n.noRecommendations),
                  );
                }
                return RefreshIndicator(
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
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: state.isLoadingMore
                                ? const CircularProgressIndicator()
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final recommendation = state.recommendations[index];
                      return AnimatedOpacity(
                        opacity: 1.0,
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        child: RecommendationCard(
                          recommendation: recommendation,
                          onTap: () {
                            // 追踪内容点击
                            _analytics.track('content_click', properties: {
                              'content_id': recommendation.contentId,
                              'scenario': _selectedScenario,
                              'position': index,
                            });
                            context.push(
                              '/content/${recommendation.contentId}',
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              } else if (state is RecommendationError) {
                return Center(
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
                      ElevatedButton(
                        onPressed: () {
                          if (_selectedScenario != null) {
                            context.read<RecommendationBloc>().add(
                                  LoadRecommendations(_selectedScenario!),
                                );
                          }
                        },
                        child: Text(l10n.retry),
                      ),
                    ],
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
