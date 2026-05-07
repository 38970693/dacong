import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

/// 分享按钮组件
/// 用于内容详情页面，支持多平台分享
class ShareButton extends StatelessWidget {
  final String contentId;
  final String title;
  final String? summary;
  final VoidCallback? onShareRecorded;

  const ShareButton({
    super.key,
    required this.contentId,
    required this.title,
    this.summary,
    this.onShareRecorded,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _handleShare(context),
      tooltip: '分享',
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      // 构建分享内容
      final shareUrl = 'https://dacong.ai/content/$contentId';
      final shareText = summary != null
          ? '$title\n\n$summary\n\n$shareUrl'
          : '$title\n\n$shareUrl';

      // 使用 share_plus 分享
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: title,
        ),
      );

      // 记录分享（如果分享成功）
      if (result.status == ShareResultStatus.success) {
        onShareRecorded?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }
}

/// 高级分享按钮（带分享选项）
class AdvancedShareButton extends StatelessWidget {
  final String contentId;
  final String title;
  final String? summary;
  final Function(String platform)? onShare;

  const AdvancedShareButton({
    super.key,
    required this.contentId,
    required this.title,
    this.summary,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () => _showShareOptions(context),
      tooltip: '分享',
    );
  }

  void _showShareOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '分享到',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('系统分享'),
              onTap: () {
                Navigator.pop(context);
                _shareViaSystem(context, 'system');
              },
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('复制链接'),
              onTap: () {
                Navigator.pop(context);
                _copyLink(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('生成分享图片'),
              onTap: () {
                Navigator.pop(context);
                _generateShareImage(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaSystem(BuildContext context, String platform) async {
    try {
      final shareUrl = 'https://dacong.ai/content/$contentId';
      final shareText = summary != null
          ? '$title\n\n$summary\n\n$shareUrl'
          : '$title\n\n$shareUrl';

      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: title,
        ),
      );

      if (result.status == ShareResultStatus.success) {
        onShare?.call(platform);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _copyLink(BuildContext context) async {
    try {
      final shareUrl = 'https://dacong.ai/content/$contentId';

      // 复制到剪贴板
      await Clipboard.setData(ClipboardData(text: shareUrl));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('链接已复制到剪贴板')),
        );
      }

      onShare?.call('copy_link');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('复制失败: $e')),
        );
      }
    }
  }

  Future<void> _generateShareImage(BuildContext context) async {
    try {
      // TODO: 调用生成分享图片的 API
      // final imageUrl = await apiClient.generateShareImage(contentId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享图片生成功能即将上线')),
        );
      }

      onShare?.call('image');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('生成失败: $e')),
        );
      }
    }
  }
}
