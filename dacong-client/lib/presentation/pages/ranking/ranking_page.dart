// AI工具排行页 - Ranking Page
// 最好用的AI工具排行，面向普通用户
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/rising_star_model.dart';
import '../../providers/models_provider.dart';
import '../../providers/rising_stars_provider.dart';
import '../../widgets/common/loading_error_widget.dart';
import '../../widgets/cards/model_card.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});
  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(() {
      ref.read(rankingProvider.notifier).loadInitial();
      ref.read(risingStarsProvider.notifier).load();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(rankingProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(rankingProvider);

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.rankOverall),
            Tab(text: l10n.rankCategory),
            const Tab(text: '飙升榜'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 综合榜
              _buildOverallList(state),
              // 分类榜
              _buildCategoryGrid(),
              // 飙升榜
              _buildRisingStars(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallList(RankingState state) {
    if (state.isLoading && state.models.isEmpty) {
      return const LoadingWidget();
    }
    if (state.error != null && state.models.isEmpty) {
      return AppErrorWidget(message: state.error!,
        onRetry: () => ref.read(rankingProvider.notifier).loadInitial());
    }
    if (state.models.isEmpty) {
      return const EmptyWidget(icon: Icons.leaderboard);
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(rankingProvider.notifier).refresh(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: state.models.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.models.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final model = state.models[index];
          return ModelCard(
            model: model,
            onTap: () => context.push('/model/${model.id}'),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      _CategoryItem(icon: Icons.smart_toy, label: 'AI对话', color: Colors.green, filter: 'chat'),
      _CategoryItem(icon: Icons.image, label: 'AI绘图', color: Colors.purple, filter: 'image'),
      _CategoryItem(icon: Icons.videocam, label: 'AI视频', color: Colors.red, filter: 'video'),
      _CategoryItem(icon: Icons.work, label: '办公效率', color: Colors.blue, filter: 'productivity'),
      _CategoryItem(icon: Icons.monetization_on, label: '免费工具', color: Colors.teal, filter: 'free'),
      _CategoryItem(icon: Icons.language, label: '国产AI', color: Colors.orange, filter: 'chinese'),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _CategoryCard(item: cat, onTap: () {
          ref.read(rankingProvider.notifier).loadInitial(category: cat.filter);
          _tabController.animateTo(0);
        });
      },
    );
  }

  Widget _buildRisingStars() {
    final state = ref.watch(risingStarsProvider);
    final notifier = ref.read(risingStarsProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              for (final period in const ['1d', '7d', '30d'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: state.period == period,
                    onSelected: (_) => notifier.load(period: period),
                  ),
                ),
            ],
          ),
        ),
        Expanded(child: _buildRisingStarsList(state)),
      ],
    );
  }

  Widget _buildRisingStarsList(RisingStarsState state) {
    if (state.isLoading && state.repos.isEmpty) {
      return const LoadingWidget();
    }
    if (state.error != null && state.repos.isEmpty) {
      return AppErrorWidget(message: state.error!,
        onRetry: () => ref.read(risingStarsProvider.notifier).load());
    }
    if (state.repos.isEmpty) {
      return const EmptyWidget(icon: Icons.trending_up);
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(risingStarsProvider.notifier).refresh(),
      child: ListView.builder(
        itemCount: state.repos.length,
        itemBuilder: (context, index) => _RisingStarCard(
          repo: state.repos[index],
          rank: index + 1,
          period: state.period,
        ),
      ),
    );
  }
}

class _RisingStarCard extends StatelessWidget {
  final RisingStar repo;
  final int rank;
  final String period;
  const _RisingStarCard({
    required this.repo,
    required this.rank,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rank <= 3 ? Colors.deepOrange : Colors.grey.shade300,
        child: Text(
          '$rank',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.white : Colors.black87,
          ),
        ),
      ),
      title: Text(
        repo.repoName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (repo.description != null && repo.description!.isNotEmpty)
            Text(repo.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            '${repo.language ?? '-'} · ★ ${repo.totalStars} · '
            '${repo.velocity.toStringAsFixed(1)}/天',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.trending_up, color: Colors.deepOrange, size: 18),
          Text(
            '+${repo.starsFor(period)}',
            style: const TextStyle(
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _CategoryItem {
  final IconData icon;
  final String label;
  final Color color;
  final String filter;
  const _CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.filter,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem item;
  final VoidCallback onTap;
  const _CategoryCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 36, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
