import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/domain/entities/weekly.dart';
import '../../blocs/weekly/weekly_bloc.dart';

/// 周报页面
class WeeklyPage extends StatelessWidget {
  const WeeklyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本周精选'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // 查看历史周报
              context.read<WeeklyBloc>().add(const LoadWeeklyHistory());
            },
          ),
        ],
      ),
      body: BlocBuilder<WeeklyBloc, WeeklyState>(
        builder: (context, state) {
          if (state is WeeklyLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is WeeklyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<WeeklyBloc>().add(const LoadWeekly());
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (state is WeeklyLoaded) {
            return _WeeklyContent(weekly: state.weekly);
          }

          if (state is WeeklyHistoryLoaded) {
            return _WeeklyHistoryList(weeklyList: state.weeklyList);
          }

          // 初始状态，自动加载
          context.read<WeeklyBloc>().add(const LoadWeekly());
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

/// 周报内容
class _WeeklyContent extends StatelessWidget {
  final Weekly weekly;

  const _WeeklyContent({required this.weekly});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 顶部标题和日期
        SliverToBoxAdapter(
          child: _WeeklyHeader(weekly: weekly),
        ),

        // 各个板块
        ...weekly.sections.map((section) {
          return SliverToBoxAdapter(
            child: _WeeklySection(section: section),
          );
        }),

        // 分享按钮
        SliverToBoxAdapter(
          child: _ShareButton(weeklyId: weekly.id),
        ),
      ],
    );
  }
}

/// 周报头部
class _WeeklyHeader extends StatelessWidget {
  final Weekly weekly;

  const _WeeklyHeader({required this.weekly});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekly.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${weekly.weekStart} - ${weekly.weekEnd}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            weekly.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                icon: Icons.visibility,
                label: '${weekly.viewCount} 阅读',
              ),
              const SizedBox(width: 12),
              _StatChip(
                icon: Icons.thumb_up,
                label: '${weekly.helpfulCount} 有用',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 统计芯片
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 周报板块
class _WeeklySection extends StatelessWidget {
  final WeeklySection section;

  const _WeeklySection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.sectionTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...section.items.map((item) {
            return _WeeklyItemCard(item: item);
          }),
        ],
      ),
    );
  }
}

/// 周报项目卡片
class _WeeklyItemCard extends StatelessWidget {
  final WeeklyItem item;

  const _WeeklyItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // 打开 GitHub 链接
          // TODO: 实现链接跳转
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 项目名和访问方式
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _AccessBadge(access: item.access),
                ],
              ),
              const SizedBox(height: 8),

              // 一句话亮点
              Text(
                item.oneLiner,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                    ),
              ),
              const SizedBox(height: 8),

              // 为什么值得关注
              Text(
                item.whyMatters,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),

              // Star 数和增长
              Row(
                children: [
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_formatNumber(item.stars)} stars',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${_formatNumber(item.starGrowth)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
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

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// 访问方式徽章
class _AccessBadge extends StatelessWidget {
  final String access;

  const _AccessBadge({required this.access});

  @override
  Widget build(BuildContext context) {
    final isAvailable = access.contains('国内可用');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green[100] : Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        access,
        style: TextStyle(
          fontSize: 12,
          color: isAvailable ? Colors.green[900] : Colors.orange[900],
        ),
      ),
    );
  }
}

/// 分享按钮
class _ShareButton extends StatelessWidget {
  final String weeklyId;

  const _ShareButton({required this.weeklyId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton.icon(
        onPressed: () {
          context.read<WeeklyBloc>().add(ShareWeekly(weeklyId));
          // TODO: 实现分享功能（生成图卡）
        },
        icon: const Icon(Icons.share),
        label: const Text('分享周报'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// 历史周报列表
class _WeeklyHistoryList extends StatelessWidget {
  final List<Weekly> weeklyList;

  const _WeeklyHistoryList({required this.weeklyList});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: weeklyList.length,
      itemBuilder: (context, index) {
        final weekly = weeklyList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            title: Text(weekly.title),
            subtitle: Text('${weekly.weekStart} - ${weekly.weekEnd}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 查看该期周报
              context.read<WeeklyBloc>().add(const LoadWeekly());
            },
          ),
        );
      },
    );
  }
}
