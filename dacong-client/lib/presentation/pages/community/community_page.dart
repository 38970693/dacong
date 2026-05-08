// AI社区页 - Community Page
// AI使用心得分享、踩坑吐槽、工具推荐
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import '../../widgets/common/loading_error_widget.dart';
import '../../widgets/cards/post_card.dart';

// 当前话题过滤器
final _selectedTopicProvider = StateProvider<String?>((ref) => null);

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});
  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(postsProvider.notifier).loadInitial());
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
      ref.read(postsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postsProvider);
    final selectedTopic = ref.watch(_selectedTopicProvider);

    return Scaffold(
      body: Column(
        children: [
          // 话题过滤器
          _buildTopicFilter(selectedTopic),
          // 帖子列表
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(postsProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopicFilter(String? selected) {
    // 大众化话题
    final topics = [
      ('all', '全部', Colors.blue),
      ('使用心得', '使用心得', Colors.green),
      ('工具推荐', '工具推荐', Colors.orange),
      ('踩坑吐槽', '踩坑吐槽', Colors.red),
      ('AI绘图', 'AI绘图', Colors.purple),
      ('变现分享', '变现分享', Colors.teal),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: topics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (key, label, color) = topics[index];
          final isSelected = selected == key || (selected == null && key == 'all');
          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) {
              ref.read(_selectedTopicProvider.notifier).state =
                  key == 'all' ? null : key;
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

  Widget _buildBody(PostsState state) {
    if (state.isLoading && state.posts.isEmpty) {
      return const LoadingWidget();
    }
    if (state.error != null && state.posts.isEmpty) {
      return AppErrorWidget(message: state.error!,
        onRetry: () => ref.read(postsProvider.notifier).loadInitial());
    }
    if (state.posts.isEmpty) {
      return const EmptyWidget(icon: Icons.forum);
    }
    return ListView.builder(
      controller: _scrollController,
      itemCount: state.posts.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.posts.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final post = state.posts[index];
        return PostCard(
          post: post,
          onTap: () => context.push('/post/${post.id}'),
          onLike: () => ref.read(communityRepositoryProvider).toggleLike(post.id),
        );
      },
    );
  }
}
