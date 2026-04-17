import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dacong_client/core/theme/theme_cubit.dart';

void main() {
  group('ThemeCubit', () {
    late ThemeCubit themeCubit;

    setUp(() {
      themeCubit = ThemeCubit();
    });

    tearDown(() {
      themeCubit.close();
    });

    test('初始状态应该是 ThemeMode.system', () {
      expect(themeCubit.state, ThemeMode.system);
    });

    test('setLightTheme 应该切换到亮色主题', () {
      themeCubit.setLightTheme();
      expect(themeCubit.state, ThemeMode.light);
    });

    test('setDarkTheme 应该切换到暗色主题', () {
      themeCubit.setDarkTheme();
      expect(themeCubit.state, ThemeMode.dark);
    });

    test('setSystemTheme 应该切换到跟随系统主题', () {
      themeCubit.setLightTheme();
      themeCubit.setSystemTheme();
      expect(themeCubit.state, ThemeMode.system);
    });

    test('主题切换应该按顺序工作', () async {
      final states = <ThemeMode>[];

      themeCubit.stream.listen(states.add);

      themeCubit.setLightTheme();
      themeCubit.setDarkTheme();
      themeCubit.setSystemTheme();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, [
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.system,
      ]);
    });
  });
}
