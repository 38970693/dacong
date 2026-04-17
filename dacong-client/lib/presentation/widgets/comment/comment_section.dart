import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/comment/comment_bloc.dart';
import '../../blocs/comment/comment_event.dart';
import '../../blocs/comment/comment_state.dart';
import 'comment_tree.dart';
import 'comment_input.dart';

/// 评论区组件
class CommentSection extends StatefulWidget {
  final String contentId;
  final String? parentId;

  const CommentSection({
    super.key,
    required this.contentId,
    this.parentId,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final ScrollController _scrollController = ScrollController();
  String _currentSort = 'latest';

  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadComments() {
    context.read<CommentBloc>().add(LoadComments(
          contentId: widget.contentId,
          parentId: widget.parentId,
          sort: _currentSort,
        ));
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      final state = context.read<CommentBloc>().state;
      if (state is CommentLoaded && state.hasMore) {
        context.read<CommentBloc>().add(LoadComments(
              contentId: widget.contentId,
              parentId: widget.parentId,
              page: state.currentPage + 1,
              sort: state.sort,
            ));
      }
    }
  }

  void _changeSortOrder(String sort) {
    setState(() {
      _currentSort = sort;
    });
    context.read<CommentBloc>().add(ChangeSortOrder(sort));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 评论输入框
        CommentInput(
          contentId: widget.contentId,
          parentId: widget.parentId,
          onSubmitted: () {
            // 提交后滚动到顶部
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          },
        ),
        const SizedBox(height: 16),

        // 排序选项
        _buildSortOptions(),
        const SizedBox(height: 16),

        // 评论列表
        Expanded(
          child: BlocBuilder<CommentBloc, CommentState>(
            builder: (context, state) {
              if (state is CommentLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is CommentError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadComments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (state is CommentLoaded) {
                if (state.comments.isEmpty) {
                  return const Center(
                    child: Text('No comments yet. Be the first to comment!'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<CommentBloc>().add(RefreshComments(
                          contentId: widget.contentId,
                          parentId: widget.parentId,
                          sort: state.sort,
                        ));
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    itemCount: state.comments.length + (state.hasMore ? 1 : 0),
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      if (index >= state.comments.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final comment = state.comments[index];
                      return CommentTree(
                        comment: comment,
                        contentId: widget.contentId,
                      );
                    },
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

  Widget _buildSortOptions() {
    return Row(
      children: [
        const Text(
          'Sort by:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 12),
        ChoiceChip(
          label: const Text('Latest'),
          selected: _currentSort == 'latest',
          onSelected: (selected) {
            if (selected) _changeSortOrder('latest');
          },
        ),
        const SizedBox(width: 8),
        ChoiceChip(
          label: const Text('Popular'),
          selected: _currentSort == 'popular',
          onSelected: (selected) {
            if (selected) _changeSortOrder('popular');
          },
        ),
      ],
    );
  }
}
