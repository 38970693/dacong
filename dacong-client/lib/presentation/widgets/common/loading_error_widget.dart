// 通用加载中 / 错误 / 空状态组件
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    ),
  );
}

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorWidget({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyWidget extends StatelessWidget {
  final String? message;
  final IconData icon;
  const EmptyWidget({super.key, this.message, this.icon = Icons.inbox});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(message ?? l10n.noData, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
