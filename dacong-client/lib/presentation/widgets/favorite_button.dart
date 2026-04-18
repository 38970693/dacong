import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/user/user_bloc.dart';
import '../blocs/user/user_event.dart';

/// 收藏按钮组件
class FavoriteButton extends StatelessWidget {
  final String contentId;
  final bool isFavorited;
  final VoidCallback? onToggle;

  const FavoriteButton({
    super.key,
    required this.contentId,
    required this.isFavorited,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isFavorited ? Icons.favorite : Icons.favorite_border,
        color: isFavorited ? Colors.red : null,
      ),
      onPressed: () {
        if (isFavorited) {
          context.read<UserBloc>().add(UserEvent.removeFavorite(contentId));
        } else {
          context.read<UserBloc>().add(UserEvent.addFavorite(contentId));
        }
        onToggle?.call();
      },
      tooltip: isFavorited ? '取消收藏' : '收藏',
    );
  }
}
