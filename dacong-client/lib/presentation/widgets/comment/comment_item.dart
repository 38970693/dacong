import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../domain/entities/comment.dart';
import '../../blocs/comment/comment_bloc.dart';
import '../../blocs/comment/comment_event.dart';

/// 单条评论组件
class CommentItem extends StatefulWidget {
  final Comment comment;
  final String contentId;
  final int depth;
  final VoidCallback? onReplyTap;

  const CommentItem({
    super.key,
    required this.comment,
    required this.contentId,
    this.depth = 0,
    this.onReplyTap,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _showReplyInput = false;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  void _toggleReplyInput() {
    setState(() {
      _showReplyInput = !_showReplyInput;
    });
    if (_showReplyInput) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _replyFocusNode.requestFocus();
      });
    }
  }

  void _submitReply() {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    context.read<CommentBloc>().add(SubmitComment(
          contentId: widget.contentId,
          content: content,
          parentId: widget.comment.id,
        ));

    _replyController.clear();
    setState(() {
      _showReplyInput = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply submitted')),
    );
  }

  void _toggleLike() {
    if (widget.comment.isLiked) {
      context.read<CommentBloc>().add(UnlikeComment(widget.comment.id));
    } else {
      context.read<CommentBloc>().add(LikeComment(widget.comment.id));
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report Comment'),
        content: const Text('Are you sure you want to report this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CommentBloc>().add(ReportComment(
                    commentId: widget.comment.id,
                    reason: 'User reported',
                  ));
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Comment reported'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: 12,
        left: 16.0 + (widget.depth * 0.0),
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息和时间
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[300],
                child: Text(
                  widget.comment.userId.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User ${widget.comment.userId.substring(0, 8)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      timeago.format(widget.comment.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, size: 20),
                onPressed: _showReportDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 评论内容
          Text(
            widget.comment.content,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 12),

          // 操作按钮
          Row(
            children: [
              // 点赞按钮
              InkWell(
                onTap: _toggleLike,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        widget.comment.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: widget.comment.isLiked ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.comment.likesCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.comment.isLiked ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 回复按钮
              if (widget.comment.parentId == null && widget.onReplyTap != null)
                InkWell(
                  onTap: _toggleReplyInput,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.reply, size: 18, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // 回复输入框
          if (_showReplyInput)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      focusNode: _replyFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Write a reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitReply(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _submitReply,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
