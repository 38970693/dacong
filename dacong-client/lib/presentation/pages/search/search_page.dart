import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/di/injection.dart';
import '../../blocs/search/search_bloc.dart';
import '../../widgets/content_card.dart';
import '../../widgets/empty_state.dart';
import '../../../core/analytics/analytics_service.dart';

/// 搜索页面
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SearchBloc>(),
      child: const _SearchPageContent(),
    );
  }
}

class _SearchPageContent extends StatefulWidget {
  const _SearchPageContent();

  @override
  State<_SearchPageContent> createState() => _SearchPageContentState();
}

class _SearchPageContentState extends State<_SearchPageContent> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _analytics = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // 追踪页面浏览
    _analytics.trackPageView('search');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<SearchBloc>().add(const SearchLoadMore());
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _SearchBar(controller: _searchController),
          ),
        ),
      ),
      body: Column(
        children: [
          const _FilterBar(),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return const _SearchSuggestions();
                } else if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is SearchLoaded) {
                  return _SearchResults(
                    results: state.results,
                    scrollController: _scrollController,
                    isLoadingMore: state.isLoadingMore,
                  );
                } else if (state is SearchEmpty) {
                  return EmptyState(
                    icon: Icons.search_off,
                    title: '未找到结果',
                    message: '试试其他关键词',
                  );
                } else if (state is SearchError) {
                  return EmptyState(
                    icon: Icons.error_outline,
                    title: '搜索失败',
                    message: state.message,
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索框
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService();

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: '搜索 AI 工具...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            controller.clear();
            context.read<SearchBloc>().add(const SearchCleared());
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (query) {
        // 追踪搜索
        if (query.isNotEmpty) {
          context.read<SearchBloc>().add(SearchQueryChanged(query));
        }
      },
      onSubmitted: (query) {
        if (query.isNotEmpty) {
          final bloc = context.read<SearchBloc>();
          final state = bloc.state;
          int resultCount = 0;
          if (state is SearchLoaded) {
            resultCount = state.results.length;
          }
          analytics.trackSearch(query, resultCount);
        }
      },
    );
  }
}

/// 筛选栏
class _FilterBar extends StatelessWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService();

    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is! SearchLoaded) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 场景筛选
                _FilterChip(
                  label: '场景',
                  selected: state.scenario != null,
                  onTap: () => _showScenarioFilter(context, analytics),
                ),
                const SizedBox(width: 8),
                // 价格筛选
                _FilterChip(
                  label: state.isFree == true ? '免费' : '价格',
                  selected: state.isFree != null,
                  onTap: () => _showPriceFilter(context, state.isFree, analytics),
                ),
                const SizedBox(width: 8),
                // 访问方式筛选
                _FilterChip(
                  label: state.availableInChina == true ? '国内可用' : '访问方式',
                  selected: state.availableInChina != null,
                  onTap: () => _showAccessFilter(context, state.availableInChina, analytics),
                ),
                const SizedBox(width: 16),
                // 排序
                _SortButton(currentSort: state.sortType, analytics: analytics),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showScenarioFilter(BuildContext context, AnalyticsService analytics) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ScenarioFilterSheet(analytics: analytics),
    );
  }

  void _showPriceFilter(BuildContext context, bool? currentValue, AnalyticsService analytics) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _PriceFilterSheet(currentValue: currentValue, analytics: analytics),
    );
  }

  void _showAccessFilter(BuildContext context, bool? currentValue, AnalyticsService analytics) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AccessFilterSheet(currentValue: currentValue, analytics: analytics),
    );
  }
}

/// 筛选芯片
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

/// 排序按钮
class _SortButton extends StatelessWidget {
  final SearchSortType currentSort;
  final AnalyticsService analytics;

  const _SortButton({required this.currentSort, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SearchSortType>(
      icon: const Icon(Icons.sort),
      onSelected: (sortType) {
        // 追踪排序变化
        analytics.trackSortChange(sortType.toString(), 'desc');
        context.read<SearchBloc>().add(SearchSortChanged(sortType));
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: SearchSortType.relevance,
          child: Row(
            children: [
              if (currentSort == SearchSortType.relevance)
                const Icon(Icons.check, size: 20),
              const SizedBox(width: 8),
              const Text('相关度'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SearchSortType.rating,
          child: Row(
            children: [
              if (currentSort == SearchSortType.rating)
                const Icon(Icons.check, size: 20),
              const SizedBox(width: 8),
              const Text('评分'),
            ],
          ),
        ),
        PopupMenuItem(
          value: SearchSortType.viewCount,
          child: Row(
            children: [
              if (currentSort == SearchSortType.viewCount)
                const Icon(Icons.check, size: 20),
              const SizedBox(width: 8),
              const Text('浏览量'),
            ],
          ),
        ),
      ],
    );
  }
}

/// 场景筛选面板
class _ScenarioFilterSheet extends StatelessWidget {
  final AnalyticsService analytics;
  final List<String> scenarios = [
    'coding',
    'video',
    'image',
    'chat',
    'writing',
    'data',
  ];

  final Map<String, String> scenarioNames = {
    'coding': '写代码',
    'video': '做视频',
    'image': '做图片',
    'chat': '日常对话',
    'writing': '写作',
    'data': '数据分析',
  };

  _ScenarioFilterSheet({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择场景',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...scenarios.map((scenario) => ListTile(
                title: Text(scenarioNames[scenario] ?? scenario),
                onTap: () {
                  // 追踪筛选变化
                  analytics.trackFilterChange({'scenario': scenario});
                  context.read<SearchBloc>().add(
                        SearchFilterChanged(scenario: scenario),
                      );
                  Navigator.pop(context);
                },
              )),
          ListTile(
            title: const Text('全部'),
            onTap: () {
              analytics.trackFilterChange({'scenario': null});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(scenario: null),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// 价格筛选面板
class _PriceFilterSheet extends StatelessWidget {
  final bool? currentValue;
  final AnalyticsService analytics;

  const _PriceFilterSheet({this.currentValue, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '价格',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('免费'),
            trailing: currentValue == true ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'is_free': true});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(isFree: true),
                  );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('付费'),
            trailing: currentValue == false ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'is_free': false});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(isFree: false),
                  );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('全部'),
            trailing: currentValue == null ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'is_free': null});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(isFree: null),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// 访问方式筛选面板
class _AccessFilterSheet extends StatelessWidget {
  final bool? currentValue;
  final AnalyticsService analytics;

  const _AccessFilterSheet({this.currentValue, required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '访问方式',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('国内可用'),
            trailing: currentValue == true ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'available_in_china': true});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(availableInChina: true),
                  );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('需翻墙'),
            trailing: currentValue == false ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'available_in_china': false});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(availableInChina: false),
                  );
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('全部'),
            trailing: currentValue == null ? const Icon(Icons.check) : null,
            onTap: () {
              analytics.trackFilterChange({'available_in_china': null});
              context.read<SearchBloc>().add(
                    const SearchFilterChanged(availableInChina: null),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

/// 搜索建议
class _SearchSuggestions extends StatelessWidget {
  const _SearchSuggestions();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is! SearchInitial) return const SizedBox.shrink();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 搜索历史
              if (state.searchHistory.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '搜索历史',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<SearchBloc>().add(const ClearSearchHistory());
                      },
                      child: const Text('清空'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...state.searchHistory.map((query) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          context
                              .read<SearchBloc>()
                              .add(DeleteSearchHistoryItem(query));
                        },
                      ),
                      onTap: () {
                        context.read<SearchBloc>().add(SearchQueryChanged(query));
                      },
                    )),
                const SizedBox(height: 24),
              ],
              // 热门搜索
              const Text(
                '热门搜索',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: state.popularSearches
                    .map((label) => _SuggestionChip(label: label))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 建议芯片
class _SuggestionChip extends StatelessWidget {
  final String label;

  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        context.read<SearchBloc>().add(SearchQueryChanged(label));
      },
    );
  }
}

/// 搜索结果列表
class _SearchResults extends StatelessWidget {
  final List results;
  final ScrollController scrollController;
  final bool isLoadingMore;

  const _SearchResults({
    required this.results,
    required this.scrollController,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: results.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= results.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final content = results[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ContentCard(content: content),
        );
      },
    );
  }
}
