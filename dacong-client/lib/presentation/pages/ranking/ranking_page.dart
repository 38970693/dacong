// AI工具排行页 - Ranking Page
// 最好用的AI工具排行，面向普通用户
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/models_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(rankingProvider.notifier).loadInitial());
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
