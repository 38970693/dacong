import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dacong_client/core/domain/entities/scenario.dart';
import 'package:dacong_client/core/error/failures.dart';
import 'package:dacong_client/data/repositories/scenario_repository_impl.dart';

void main() {
  late ScenarioRepositoryImpl repository;

  setUp(() {
    repository = ScenarioRepositoryImpl();
  });

  group('ScenarioRepositoryImpl', () {
    group('getAllScenarios', () {
      test('returns empty list when no scenarios exist', () async {
        final result = await repository.getAllScenarios();

        expect(result, isA<Right<Failure, List<Scenario>>>());
        result.fold(
          (failure) => fail('Should return Right'),
          (scenarios) => expect(scenarios, isEmpty),
        );
      });
    });

    group('getScenarioById', () {
      test('returns NotFoundFailure when scenario does not exist', () async {
        const testId = 'non-existent-id';
        final result = await repository.getScenarioById(testId);

        expect(result, isA<Left<Failure, Scenario>>());
        result.fold(
          (failure) {
            expect(failure, isA<NotFoundFailure>());
            expect(failure.message, contains('场景不存在'));
          },
          (scenario) => fail('Should return Left'),
        );
      });
    });
  });
}
