// 语言本地化 Provider
// Android/iOS 跟随系统语言，Web 支持 localStorage 手动切换
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── 存储抽象 ─────────────────────────────────

abstract class LocaleStorage {
  Future<String?> read();
  Future<void> write(String locale);
}

class SharedPrefsLocaleStorage implements LocaleStorage {
  @override
  Future<String?> read() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('dacong_locale');
  }

  @override
  Future<void> write(String locale) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('dacong_locale', locale);
  }
}

// ── 语言状态管理器 ─────────────────────────────────

class LocaleNotifier extends ChangeNotifier {
  final LocaleStorage _storage;
  Locale _locale;

  LocaleNotifier(this._storage) : _locale = const Locale('en');

  Locale get locale => _locale;

  /// 初始化：Web 优先读 localStorage，无则跟随系统
  Future<void> init() async {
    final saved = await _storage.read();
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      _locale = _systemLocale();
    }
    notifyListeners();
  }

  Locale _systemLocale() {
    // 使用 WidgetsBinding 访问系统语言
    final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
    if (systemLocale.languageCode == 'zh') {
      return const Locale('zh');
    }
    return const Locale('en');
  }

  /// 用户手动切换语言（Web 端调用）
  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    await _storage.write(languageCode);
    notifyListeners();
  }
}

// ── Provider ─────────────────────────────────

final localeStorageProvider = Provider<LocaleStorage>((ref) {
  return SharedPrefsLocaleStorage();
});

final localeProvider = ChangeNotifierProvider<LocaleNotifier>((ref) {
  final notifier = LocaleNotifier(ref.watch(localeStorageProvider));
  notifier.init();
  return notifier;
});
