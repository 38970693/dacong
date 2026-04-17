import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../widgets/stat_card.dart';
import '../widgets/charts/line_chart.dart' as custom;
import '../widgets/charts/bar_chart.dart';
import '../widgets/charts/pie_chart.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard_stats.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedTrendDays = 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final statsAsync = ref.watch(realtimeStatsProvider);
    final trendAsync = ref.watch(trendDataProvider(_selectedTrendDays));
    final topContentAsync = ref.watch(topContentProvider(10));
    final topKeywordsAsync = ref.watch(topSearchKeywordsProvider(10));
    final pendingTasksAsync = ref.watch(pendingTasksProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text(
          '数据看板',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(realtimeStatsProvider);
              ref.invalidate(trendDataProvider);
              ref.invalidate(topContentProvider);
              ref.invalidate(topSearchKeywordsProvider);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(realtimeStatsProvider);
          ref.invalidate(trendDataProvider);
          ref.invalidate(topContentProvider);
          ref.invalidate(topSearchKeywordsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 实时概览
              _buildSectionTitle(context, '实时概览'),
              const SizedBox(height: 16),
              statsAsync.when(
                data: (stats) => _buildStatsCards(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              const SizedBox(height: 32),

              // 趋势分析
              _buildSectionTitle(context, '趋势分析'),
              const SizedBox(height: 8),
              _buildTrendSelector(),
              const SizedBox(height: 16),
              trendAsync.when(
                data: (trend) => _buildTrendChart(trend),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              const SizedBox(height: 32),

              // 待处理事项
              _buildSectionTitle(context, '待处理事项'),
              const SizedBox(height: 16),
              pendingTasksAsync.when(
                data: (tasks) => _buildPendingTasks(tasks),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorCard(error.toString()),
              ),
              const SizedBox(height: 32),

              // 内容统计
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, '内容统计'),
                        const SizedBox(height: 16),
                        statsAsync.when(
                          data: (stats) => _buildContentStats(stats),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorCard(error.toString()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, '用户统计'),
                        const SizedBox(height: 16),
                        statsAsync.when(
                          data: (stats) => _buildUserStats(stats),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorCard(error.toString()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 热门内容和搜索热词
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, '热门内容 Top 10'),
                        const SizedBox(height: 16),
                        topContentAsync.when(
                          data: (content) => _buildTopContent(content),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorCard(error.toString()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(context, '搜索热词 Top 10'),
                        const SizedBox(height: 16),
                        topKeywordsAsync.when(
                          data: (keywords) => _buildTopKeywords(keywords),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stack) => _buildErrorCard(error.toString()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStatsCards(stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: '今日DAU',
            value: stats.todayDau.toString(),
            change: stats.dauChange,
            icon: Icons.people,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: '今日PV',
            value: stats.todayPv.toString(),
            change: stats.pvChange,
            icon: Icons.visibility,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: '今日UV',
            value: stats.todayUv.toString(),
            change: stats.uvChange,
            icon: Icons.remove_red_eye,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: '新增用户',
            value: stats.newUsers.toString(),
            change: stats.newUsersChange,
            icon: Icons.person_add,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendSelector() {
    return Row(
      children: [
        _buildTrendButton('7天', 7),
        const SizedBox(width: 8),
        _buildTrendButton('30天', 30),
      ],
    );
  }

  Widget _buildTrendButton(String label, int days) {
    final isSelected = _selectedTrendDays == days;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedTrendDays = days;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? (isDark ? Colors.blue.shade900 : Colors.blue.shade50)
            : Colors.transparent,
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
        ),
      ),
      child: Text(label),
    );
  }

  Widget _buildTrendChart(trend) {
    return custom.DacongLineChart(
      title: '用户活跃趋势',
      labels: trend.labels,
      datasets: [
        custom.LineChartData(
          label: 'DAU',
          spots: trend.dauData
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
          color: Colors.blue,
        ),
        custom.LineChartData(
          label: 'PV',
          spots: trend.pvData
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
          color: Colors.green,
        ),
        custom.LineChartData(
          label: 'UV',
          spots: trend.uvData
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value))
              .toList(),
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildContentStats(stats) {
    return DacongPieChart(
      title: '内容分布',
      sections: [
        PieChartSectionData(
          value: stats.totalContent.toDouble(),
          title: '总内容',
          color: Colors.blue,
        ),
        PieChartSectionData(
          value: stats.publishedContent.toDouble(),
          title: '已发布',
          color: Colors.green,
        ),
        PieChartSectionData(
          value: stats.pendingReview.toDouble(),
          title: '待审核',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildUserStats(stats) {
    return DacongBarChart(
      title: '用户概览',
      labels: ['总用户', '今日活跃', '新增用户'],
      groups: [
        BarChartGroupData(
          x: 0,
          barRods: [
            BarChartRodData(
              toY: stats.totalUsers.toDouble(),
              color: Colors.blue,
            ),
          ],
        ),
        BarChartGroupData(
          x: 1,
          barRods: [
            BarChartRodData(
              toY: stats.todayDau.toDouble(),
              color: Colors.green,
            ),
          ],
        ),
        BarChartGroupData(
          x: 2,
          barRods: [
            BarChartRodData(
              toY: stats.newUsers.toDouble(),
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopContent(List content) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: content.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = content[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${item.views} views, ${(item.helpfulRate * 100).toStringAsFixed(0)}% helpful'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: 跳转到内容详情
            },
          );
        },
      ),
    );
  }

  Widget _buildTopKeywords(List keywords) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keywords.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        ),
        itemBuilder: (context, index) {
          final item = keywords[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item.keyword),
            trailing: Chip(
              label: Text('${item.count}'),
              backgroundColor: isDark ? Colors.blue.shade900 : Colors.blue.shade50,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPendingTasks(PendingTasks tasks) {
    return Row(
      children: [
        Expanded(
          child: _buildPendingTaskCard(
            title: '待审核内容',
            count: tasks.pendingContents,
            icon: Icons.article,
            color: Colors.orange,
            onTap: () {
              // TODO: 跳转到内容管理页面
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPendingTaskCard(
            title: '待审核评论',
            count: tasks.pendingComments,
            icon: Icons.comment,
            color: Colors.blue,
            onTap: () {
              // TODO: 跳转到评论审核页面
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPendingTaskCard(
            title: '待处理举报',
            count: tasks.pendingReports,
            icon: Icons.flag,
            color: Colors.red,
            onTap: () {
              // TODO: 跳转到举报处理页面
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildPendingTaskCard(
            title: '待处理申诉',
            count: tasks.pendingAppeals,
            icon: Icons.gavel,
            color: Colors.purple,
            onTap: () {
              // TODO: 跳转到申诉处理页面
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingTaskCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$count',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('加载失败: $error'),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey.shade400;
    if (index == 2) return Colors.brown.shade300;
    return Colors.blue;
  }
}
