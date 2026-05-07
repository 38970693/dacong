import 'package:freezed_annotation/freezed_annotation.dart';

part 'content.freezed.dart';

/// 内容实体（不可变）
@freezed
abstract class Content with _$Content {
  const factory Content({
    required String id,
    required String name,
    required String vendor,
    required String description,
    required String? officialWebsite,
    required String? githubUrl,
    required List<String> features,
    required PriceInfo priceInfo,
    required AccessInfo accessInfo,
    required List<String> useCases,
    required int helpfulCount,
    required int unhelpfulCount,
    required DateTime publishedAt,
    required DateTime updatedAt,
  }) = _Content;

  const Content._();

  /// 有用率
  double get helpfulRate {
    final total = helpfulCount + unhelpfulCount;
    if (total == 0) return 0.0;
    return helpfulCount / total;
  }
}

/// 价格信息
@freezed
abstract class PriceInfo with _$PriceInfo {
  const factory PriceInfo({
    required bool isFree,
    required String? freeDescription,
    required String? paidDescription,
    required List<PriceTier> tiers,
  }) = _PriceInfo;
}

/// 价格档位
@freezed
abstract class PriceTier with _$PriceTier {
  const factory PriceTier({
    required String name,
    required String price,
    required List<String> features,
  }) = _PriceTier;
}

/// 访问信息
@freezed
abstract class AccessInfo with _$AccessInfo {
  const factory AccessInfo({
    required bool availableInChina,
    required bool needsVpn,
    required InstallDifficulty difficulty,
    required String? installGuideUrl,
  }) = _AccessInfo;
}

/// 安装难度
enum InstallDifficulty {
  easy,    // 简单
  medium,  // 中等
  hard,    // 困难
}
