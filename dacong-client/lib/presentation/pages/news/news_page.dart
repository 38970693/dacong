// AI速递页 - News Page
// AI工具动态、科技资讯、行业新闻
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/news_provider.dart';
import '../../widgets/common/loading_error_widget.dart';
import '../../widgets/cards/news_card.dart';

// 当前新闻源
final _selectedSourceProvider = StateProvider<String?>((ref) => null);

class NewsPage extends ConsumerStatefulWidget {
  const NewsPage({super.key});
  @override
  ConsumerState<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends ConsumerState<NewsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(newsProvider.notifier).loadInitial());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(newsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsProvider);
    final selectedSource = ref.watch(_selectedSourceProvider);

    return Column(
      children: [
        // 来源过滤器
        _buildSourceFilter(selectedSource),
        // 新闻列表
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(newsProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // 热搜词
                SliverToBoxAdapter(child: _buildTrendingKeywords(context)),
                // 快讯列表
                if (state.isLoading && state.news.isEmpty)
                  const SliverFillRemaining(child: LoadingWidget())
                else if (state.error != null && state.news.isEmpty)
                  SliverFillRemaining(
                    child: AppErrorWidget(
                      message: state.error!,
                      onRetry: () => ref.read(newsProvider.notifier).loadInitial(),
                    ),
                  )
                else if (state.news.isEmpty)
                  const SliverFillRemaining(child: EmptyWidget(icon: Icons.newspaper))
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= state.news.length) {
                          return state.hasMore
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()))
                              : const SizedBox.shrink();
                        }
                        final newsItem = state.news[index];
                        return NewsCard(
                          news: newsItem,
                          onTap: () => _openUrl(newsItem.url),
                        );
                      },
                      childCount: state.news.length + (state.hasMore ? 1 : 0),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourceFilter(String? selected) {
    // 大众化来源：综合 / AI资讯 / 产品动态 / 创业投资
    final sources = [
      ('all', '全部', Colors.blue),
      ('36kr', '36氪', Colors.orange),
      ('ithome', 'IT之家', Colors.purple),
      ('geekpark', '极客公园', Colors.teal),
      ('虎嗅', '虎嗅', Colors.deepOrange),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sources.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (key, label, color) = sources[index];
          final isSelected = selected == key || (selected == null && key == 'all');
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(_selectedSourceProvider.notifier).state =
                  key == 'all' ? null : key;
              ref.read(newsProvider.notifier).loadInitial(source: key == 'all' ? null : key);
            },
            backgroundColor: Colors.grey.shade100,
            selectedColor: color.withValues(alpha: 0.15),
            checkmarkColor: color,
            labelStyle: TextStyle(
              color: isSelected ? color : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected ? color : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingKeywords(BuildContext context) {
    final kwAsync = ref.watch(trendingKeywordsProvider);
    return kwAsync.when(
      data: (keywords) {
        if (keywords.isEmpty) return const SizedBox.shrink();
        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: keywords.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final kw = keywords[index];
              return ActionChip(
                label: Text('#${kw['keyword'] ?? ''}'),
                onPressed: () {},
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _openUrl(String url) {
    debugPrint('Open: $url');
  }
}
