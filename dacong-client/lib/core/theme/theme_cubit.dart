import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeCubit() : super(ThemeMode.system);

  /// 设置亮色主题
  void setLightTheme() {
    emit(ThemeMode.light);
    _saveTheme(ThemeMode.light);
  }

  /// 设置暗色主题
  void setDarkTheme() {
    emit(ThemeMode.dark);
    _saveTheme(ThemeMode.dark);
  }

  /// 设置跟随系统主题
  void setSystemTheme() {
    emit(ThemeMode.system);
    _saveTheme(ThemeMode.system);
  }

  /// 从本地存储加载主题偏好
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);

      if (themeIndex != null) {
        final themeMode = ThemeMode.values[themeIndex];
        emit(themeMode);
      }
    } catch (e) {
      // 加载失败时使用默认主题（跟随系统）
      emit(ThemeMode.system);
    }
  }

  /// 保存主题偏好到本地存储
  Future<void> _saveTheme(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, mode.index);
    } catch (e) {
      // 保存失败时静默处理
    }
  }
}
