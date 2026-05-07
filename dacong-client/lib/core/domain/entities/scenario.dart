import 'package:freezed_annotation/freezed_annotation.dart';

part 'scenario.freezed.dart';

/// 场景实体（不可变）
@freezed
abstract class Scenario with _$Scenario {
  const factory Scenario({
    required String id,
    required String name,
    required String description,
    required String icon,
    required int order,
  }) = _Scenario;
}
