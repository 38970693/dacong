import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 本地数据源（单一职责：与本地存储交互）
@lazySingleton
class LocalDataSource {
  final SharedPreferences _prefs;

  // 存储键
  static const String _searchHistoryKey = 'search_history';
  static const String _favoriteContentKey = 'favorite_content';
  static const int _maxSearchHistory = 10;

  LocalDataSource(this._prefs);

  // ==================== 搜索历史 ====================

  /// 获取搜索历史
  Future<List<String>> getSearchHistory() async {
    try {
      final jsonString = _prefs.getString(_searchHistoryKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 保存搜索历史
  Future<void> saveSearchHistory(String query) async {
    try {
      final history = await getSearchHistory();

      // 移除重复项
      history.remove(query);

      // 添加到开头
      history.insert(0, query);

      // 限制数量
      if (history.length > _maxSearchHistory) {
        history.removeRange(_maxSearchHistory, history.length);
      }

      // 保存
      final jsonString = json.encode(history);
      await _prefs.setString(_searchHistoryKey, jsonString);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 删除单条搜索历史
  Future<void> deleteSearchHistoryItem(String query) async {
    try {
      final history = await getSearchHistory();
      history.remove(query);

      final jsonString = json.encode(history);
      await _prefs.setString(_searchHistoryKey, jsonString);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 清空搜索历史
  Future<void> clearSearchHistory() async {
    try {
      await _prefs.remove(_searchHistoryKey);
    } catch (e) {
      // 忽略错误
    }
  }

  // ==================== 收藏内容 ====================

  /// 获取收藏的内容 ID 列表
  Future<List<String>> getFavoriteContentIds() async {
    try {
      final jsonString = _prefs.getString(_favoriteContentKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<String>();
    } catch (e) {
      return [];
    }
  }

  /// 添加收藏
  Future<void> addFavorite(String contentId) async {
    try {
      final favorites = await getFavoriteContentIds();

      if (!favorites.contains(contentId)) {
        favorites.add(contentId);

        final jsonString = json.encode(favorites);
        await _prefs.setString(_favoriteContentKey, jsonString);
      }
    } catch (e) {
      // 忽略错误
    }
  }

  /// 移除收藏
  Future<void> removeFavorite(String contentId) async {
    try {
      final favorites = await getFavoriteContentIds();
      favorites.remove(contentId);

      final jsonString = json.encode(favorites);
      await _prefs.setString(_favoriteContentKey, jsonString);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 检查是否已收藏
  Future<bool> isFavorite(String contentId) async {
    try {
      final favorites = await getFavoriteContentIds();
      return favorites.contains(contentId);
    } catch (e) {
      return false;
    }
  }

  /// 清空收藏
  Future<void> clearFavorites() async {
    try {
      await _prefs.remove(_favoriteContentKey);
    } catch (e) {
      // 忽略错误
    }
  }

  // ==================== 热门搜索（模拟数据） ====================

  /// 获取热门搜索
  List<String> getPopularSearches() {
    return [
      'Claude',
      'Cursor',
      'DeepSeek',
      'ChatGPT',
      'Midjourney',
      'Stable Diffusion',
      'GitHub Copilot',
      'Gemini',
    ];
  }

  // ==================== 用户偏好设置 ====================

  static const String _languageKey = 'user_language';
  static const String _themeKey = 'user_theme';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _weeklyReportKey = 'weekly_report_enabled';
  static const String _toolUpdateKey = 'tool_update_enabled';

  /// 获取语言设置
  Future<String> getLanguage() async {
    return _prefs.getString(_languageKey) ?? 'zh';
  }

  /// 保存语言设置
  Future<void> saveLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  /// 获取主题设置
  Future<String> getTheme() async {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  /// 保存主题设置
  Future<void> saveTheme(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  /// 获取通知设置
  Future<bool> getNotificationsEnabled() async {
    return _prefs.getBool(_notificationsKey) ?? true;
  }

  /// 保存通知设置
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsKey, enabled);
  }

  /// 获取周报推送设置
  Future<bool> getWeeklyReportEnabled() async {
    return _prefs.getBool(_weeklyReportKey) ?? true;
  }

  /// 保存周报推送设置
  Future<void> saveWeeklyReportEnabled(bool enabled) async {
    await _prefs.setBool(_weeklyReportKey, enabled);
  }

  /// 获取工具更新通知设置
  Future<bool> getToolUpdateEnabled() async {
    return _prefs.getBool(_toolUpdateKey) ?? true;
  }

  /// 保存工具更新通知设置
  Future<void> saveToolUpdateEnabled(bool enabled) async {
    await _prefs.setBool(_toolUpdateKey, enabled);
  }

  // ==================== 浏览历史 ====================

  static const String _historyKey = 'browse_history';
  static const int _maxHistory = 50;

  /// 获取浏览历史
  Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final jsonString = _prefs.getString(_historyKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// 添加浏览历史
  Future<void> addHistory(Map<String, dynamic> item) async {
    try {
      final history = await getHistory();

      // 移除重复项（相同 contentId）
      history.removeWhere((h) => h['contentId'] == item['contentId']);

      // 添加到开头
      history.insert(0, item);

      // 限制数量
      if (history.length > _maxHistory) {
        history.removeRange(_maxHistory, history.length);
      }

      // 保存
      final jsonString = json.encode(history);
      await _prefs.setString(_historyKey, jsonString);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 删除单条浏览历史
  Future<void> deleteHistoryItem(String contentId) async {
    try {
      final history = await getHistory();
      history.removeWhere((h) => h['contentId'] == contentId);

      final jsonString = json.encode(history);
      await _prefs.setString(_historyKey, jsonString);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 清空浏览历史
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_historyKey);
    } catch (e) {
      // 忽略错误
    }
  }

  // ==================== 用户信息缓存 ====================

  static const String _userCacheKey = 'user_cache';
  static const String _userCacheTimeKey = 'user_cache_time';
  static const int _cacheValidityMinutes = 30;

  /// 获取缓存的用户信息
  Future<Map<String, dynamic>?> getCachedUser() async {
    try {
      final cacheTime = _prefs.getInt(_userCacheTimeKey);
      if (cacheTime == null) return null;

      // 检查缓存是否过期
      final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime);
      final now = DateTime.now();
      if (now.difference(cacheDateTime).inMinutes > _cacheValidityMinutes) {
        return null;
      }

      final jsonString = _prefs.getString(_userCacheKey);
      if (jsonString == null) return null;

      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 缓存用户信息
  Future<void> cacheUser(Map<String, dynamic> user) async {
    try {
      final jsonString = json.encode(user);
      await _prefs.setString(_userCacheKey, jsonString);
      await _prefs.setInt(_userCacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // 忽略错误
    }
  }

  /// 清除用户缓存
  Future<void> clearUserCache() async {
    try {
      await _prefs.remove(_userCacheKey);
      await _prefs.remove(_userCacheTimeKey);
    } catch (e) {
      // 忽略错误
    }
  }
}
