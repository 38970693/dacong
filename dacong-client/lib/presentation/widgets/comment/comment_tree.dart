import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/comment.dart';
import '../../blocs/comment/comment_bloc.dart';
import '../../blocs/comment/comment_event.dart';
import '../../blocs/comment/comment_state.dart';
import 'comment_item.dart';

/// 评论树组件 - 支持嵌套评论展示
class CommentTree extends StatefulWidget {
  final Comment comment;
  final String contentId;
  final int depth;
  final int maxDepth;

  const CommentTree({
    super.key,
    required this.comment,
    required this.contentId,
    this.depth = 0,
    this.maxDepth = 3,
  });

  @override
  State<CommentTree> createState() => _CommentTreeState();
}

class _CommentTreeState extends State<CommentTree> {
  bool _showReplies = false;
  bool _repliesLoaded = false;

  @override
  void initState() {
    super.initState();
    // 如果有回复且深度未超限，自动展开第一层
    if (widget.comment.replyCount > 0 && widget.depth == 0) {
      _showReplies = true;
      _loadReplies();
    }
  }

  void _loadReplies() {
    if (!_repliesLoaded) {
      context.read<CommentBloc>().add(LoadReplies(
            contentId: widget.contentId,
            parentId: widget.comment.id,
          ));
      _repliesLoaded = true;
    }
  }

  void _toggleReplies() {
    setState(() {
      _showReplies = !_showReplies;
    });

    if (_showReplies && !_repliesLoaded) {
      _loadReplies();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReplies = widget.comment.replyCount > 0;
    final canShowReplies = hasReplies && widget.depth < widget.maxDepth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 主评论
        CommentItem(
          comment: widget.comment,
          contentId: widget.contentId,
          depth: widget.depth,
          onReplyTap: widget.depth < widget.maxDepth ? () {} : null,
        ),

        // 回复展开/收起按钮
        if (canShowReplies)
          Padding(
            padding: EdgeInsets.only(
              left: 16.0 + (widget.depth * 32.0),
              top: 4,
              bottom: 8,
            ),
            child: InkWell(
              onTap: _toggleReplies,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showReplies
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showReplies
                          ? 'Hide ${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}'
                          : 'Show ${widget.comment.replyCount} ${widget.comment.replyCount == 1 ? 'reply' : 'replies'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 回复列表
        if (_showReplies && canShowReplies)
          Padding(
            padding: EdgeInsets.only(left: widget.depth < 2 ? 32.0 : 16.0),
            child: BlocBuilder<CommentBloc, CommentState>(
              buildWhen: (previous, current) {
                // 只在回复相关状态变化时重建
                if (current is CommentRepliesLoaded) {
                  return current.parentId == widget.comment.id;
                }
                if (current is CommentRepliesLoading) {
                  return current.parentId == widget.comment.id;
                }
                return false;
              },
              builder: (context, state) {
                if (state is CommentRepliesLoading &&
                    state.parentId == widget.comment.id) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                if (state is CommentRepliesLoaded &&
                    state.parentId == widget.comment.id) {
                  if (state.replies.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No replies yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: state.replies.map((reply) {
                      return CommentTree(
                        comment: reply,
                        contentId: widget.contentId,
                        depth: widget.depth + 1,
                        maxDepth: widget.maxDepth,
                      );
                    }).toList(),
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
