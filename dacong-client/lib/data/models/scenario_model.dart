import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/scenario.dart';

part 'scenario_model.freezed.dart';
part 'scenario_model.g.dart';

@freezed
class ScenarioModel with _$ScenarioModel {
  const factory ScenarioModel({
    required String id,
    required String name,
    required String description,
    required String icon,
    required int order,
  }) = _ScenarioModel;

  const ScenarioModel._();

  factory ScenarioModel.fromJson(Map<String, dynamic> json) =>
      _$ScenarioModelFromJson(json);

  Scenario toEntity() {
    return Scenario(
      id: id,
      name: name,
      description: description,
      icon: icon,
      order: order,
    );
  }
}
