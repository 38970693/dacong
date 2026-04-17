import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';

/// 关于页面
class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = '${packageInfo.version}+${packageInfo.buildNumber}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutApp),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo 和应用名称
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.lightbulb,
                    size: 60,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'DaCong',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AI工具决策助手',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v$_version',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 功能介绍
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '关于 DaCong',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'DaCong（大聪）是一个AI工具决策助手，通过场景化推荐、详细教程和精选周报，帮助用户在3分钟内找到最适合的AI工具。',
                  ),
                  const SizedBox(height: 12),
                  const Text('核心功能：'),
                  const SizedBox(height: 8),
                  _buildFeatureItem('场景化推荐', '根据使用场景推荐最佳工具'),
                  _buildFeatureItem('详细教程', '一步步指导安装和使用'),
                  _buildFeatureItem('每周精选', '不错过重要的AI项目'),
                  _buildFeatureItem('工具对比', '快速对比多个工具的优劣'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 联系方式
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('联系我们'),
                  subtitle: const Text('support@dacong.ai'),
                  onTap: () {
                    // TODO: 打开邮件客户端
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text('官方网站'),
                  subtitle: const Text('https://dacong.ai'),
                  onTap: () {
                    // TODO: 打开浏览器
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('GitHub'),
                  subtitle: const Text('github.com/dacong-ai'),
                  onTap: () {
                    // TODO: 打开浏览器
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 法律信息
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: Text(l10n.privacyPolicy),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 跳转到隐私政策页面
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: Text(l10n.termsOfService),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // TODO: 跳转到服务条款页面
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 版权信息
          Center(
            child: Text(
              '© 2026 DaCong. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 20, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
