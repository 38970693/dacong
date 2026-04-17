/// 分析事件常量定义
///
/// 定义所有可追踪的事件类型

class AnalyticsEvents {
  // 页面事件
  static const String pageView = 'page_view';

  // 场景事件
  static const String scenarioClick = 'scenario_click';
  static const String scenarioSelect = 'scenario_select';

  // 内容事件
  static const String contentView = 'content_view';
  static const String contentClick = 'content_click';

  // 搜索事件
  static const String search = 'search';
  static const String filterChange = 'filter_change';
  static const String sortChange = 'sort_change';

  // 收藏事件
  static const String favoriteAdd = 'favorite_add';
  static const String favoriteRemove = 'favorite_remove';

  // 分享事件
  static const String share = 'share';

  // 反馈事件
  static const String feedback = 'feedback';
  static const String feedbackSubmit = 'feedback_submit';

  // 评论事件
  static const String commentSubmit = 'comment_submit';
  static const String commentLike = 'comment_like';

  // 设置事件
  static const String settingsChange = 'settings_change';
}
