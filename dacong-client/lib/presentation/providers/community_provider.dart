// 社区 Provider - Riverpod 状态管理（帖子 + 评论 + 话题）
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/post_model.dart';
import '../../data/models/comment_model.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/community_repository.dart';

// Repository Provider
final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository.instance;
});

// ── 帖子列表 ─────────────────────────────────

class PostsState {
  final List<Post> posts;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;

  const PostsState({
    this.posts = const [],
    this.isLoading = false,
    this.error,
    this.page = 0,
    this.hasMore = true,
  });

  PostsState copyWith({
    List<Post>? posts,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
  }) {
    return PostsState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class PostsNotifier extends StateNotifier<PostsState> {
  final CommunityRepository _repo;

  PostsNotifier(this._repo) : super(const PostsState());

  Future<void> loadInitial({String? topicId}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final posts = await _repo.getPosts(topicId: topicId);
      state = PostsState(
        posts: posts,
        isLoading: false,
        page: 0,
        hasMore: posts.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({String? topicId}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);

    try {
      final nextPage = state.page + 1;
      final more = await _repo.getPosts(page: nextPage, topicId: topicId);
      state = state.copyWith(
        posts: [...state.posts, ...more],
        isLoading: false,
        page: nextPage,
        hasMore: more.length >= 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh({String? topicId}) async {
    state = const PostsState();
    await loadInitial(topicId: topicId);
  }
}

final postsProvider =
    StateNotifierProvider<PostsNotifier, PostsState>((ref) {
  return PostsNotifier(ref.watch(communityRepositoryProvider));
});

// ── 话题列表 ─────────────────────────────────

final topicsProvider = FutureProvider<List<Topic>>((ref) async {
  return ref.read(communityRepositoryProvider).getTopics();
});

// ── 选中话题过滤 ─────────────────────────────────

final selectedTopicProvider = StateProvider<Topic?>((ref) => null);

// ── 某帖子的评论 ─────────────────────────────────

final commentsProvider =
    FutureProvider.family<List<Comment>, String>((ref, postId) async {
  return ref.read(communityRepositoryProvider).getComments(postId);
});

// ── 发帖 ─────────────────────────────────

class CreatePostNotifier extends StateNotifier<AsyncValue<void>> {
  final CommunityRepository _repo;

  CreatePostNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<Post> createPost({
    required String title,
    required String content,
    required PostType postType,
    List<String> mediaUrls = const [],
    String? topicId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final post = await _repo.createPost(
        title: title,
        content: content,
        postType: postType,
        mediaUrls: mediaUrls,
        topicId: topicId,
      );
      state = const AsyncValue.data(null);
      return post;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final createPostProvider =
    StateNotifierProvider<CreatePostNotifier, AsyncValue<void>>((ref) {
  return CreatePostNotifier(ref.watch(communityRepositoryProvider));
});
