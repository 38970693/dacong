import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/domain/entities/content.dart';

part 'content_model.freezed.dart';
part 'content_model.g.dart';

/// 内容模型（继承自实体，添加序列化能力）
@freezed
abstract class ContentModel with _$ContentModel {
  const factory ContentModel({
    required String id,
    required String name,
    required String vendor,
    required String description,
    String? officialWebsite,
    String? githubUrl,
    required List<String> features,
    required PriceInfoModel priceInfo,
    required AccessInfoModel accessInfo,
    required List<String> useCases,
    @Default(0) int helpfulCount,
    @Default(0) int unhelpfulCount,
    required DateTime publishedAt,
    required DateTime updatedAt,
  }) = _ContentModel;

  const ContentModel._();

  factory ContentModel.fromJson(Map<String, dynamic> json) =>
      _$ContentModelFromJson(json);

  /// 转换为领域实体
  Content toEntity() {
    return Content(
      id: id,
      name: name,
      vendor: vendor,
      description: description,
      officialWebsite: officialWebsite,
      githubUrl: githubUrl,
      features: features,
      priceInfo: priceInfo.toEntity(),
      accessInfo: accessInfo.toEntity(),
      useCases: useCases,
      helpfulCount: helpfulCount,
      unhelpfulCount: unhelpfulCount,
      publishedAt: publishedAt,
      updatedAt: updatedAt,
    );
  }
}

@freezed
abstract class PriceInfoModel with _$PriceInfoModel {
  const factory PriceInfoModel({
    required bool isFree,
    String? freeDescription,
    String? paidDescription,
    @Default([]) List<PriceTierModel> tiers,
  }) = _PriceInfoModel;

  const PriceInfoModel._();

  factory PriceInfoModel.fromJson(Map<String, dynamic> json) =>
      _$PriceInfoModelFromJson(json);

  PriceInfo toEntity() {
    return PriceInfo(
      isFree: isFree,
      freeDescription: freeDescription,
      paidDescription: paidDescription,
      tiers: tiers.map((t) => t.toEntity()).toList(),
    );
  }
}

@freezed
abstract class PriceTierModel with _$PriceTierModel {
  const factory PriceTierModel({
    required String name,
    required String price,
    required List<String> features,
  }) = _PriceTierModel;

  const PriceTierModel._();

  factory PriceTierModel.fromJson(Map<String, dynamic> json) =>
      _$PriceTierModelFromJson(json);

  PriceTier toEntity() {
    return PriceTier(
      name: name,
      price: price,
      features: features,
    );
  }
}

@freezed
abstract class AccessInfoModel with _$AccessInfoModel {
  const factory AccessInfoModel({
    required bool availableInChina,
    required bool needsVpn,
    required String difficulty,
    String? installGuideUrl,
  }) = _AccessInfoModel;

  const AccessInfoModel._();

  factory AccessInfoModel.fromJson(Map<String, dynamic> json) =>
      _$AccessInfoModelFromJson(json);

  AccessInfo toEntity() {
    return AccessInfo(
      availableInChina: availableInChina,
      needsVpn: needsVpn,
      difficulty: _parseDifficulty(difficulty),
      installGuideUrl: installGuideUrl,
    );
  }

  static InstallDifficulty _parseDifficulty(String value) {
    switch (value.toLowerCase()) {
      case 'easy':
        return InstallDifficulty.easy;
      case 'medium':
        return InstallDifficulty.medium;
      case 'hard':
        return InstallDifficulty.hard;
      default:
        return InstallDifficulty.medium;
    }
  }
}
