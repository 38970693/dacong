import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly.freezed.dart';

/// 周报实体（不可变）
@freezed
class Weekly with _$Weekly {
  const factory Weekly({
    required String id,
    required String title,
    required String summary,
    required String weekStart,
    required String weekEnd,
    required List<WeeklySection> sections,
    required int viewCount,
    required int helpfulCount,
    required DateTime publishedAt,
    double? helpfulRate,
  }) = _Weekly;
}

/// 周报板块
@freezed
class WeeklySection with _$WeeklySection {
  const factory WeeklySection({
    required String sectionTitle,
    required List<WeeklyItem> items,
  }) = _WeeklySection;
}

/// 周报项目
@freezed
class WeeklyItem with _$WeeklyItem {
  const factory WeeklyItem({
    required String name,
    required String oneLiner,
    required String whyMatters,
    required String githubUrl,
    required int stars,
    required int starGrowth,
    required String access,
  }) = _WeeklyItem;
}
