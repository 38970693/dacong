/// 分析服务配置

class AnalyticsConfig {
  /// 上报间隔（秒）
  static const Duration flushInterval = Duration(seconds: 30);

  /// 队列最大长度
  static const int maxQueueSize = 100;

  /// 是否启用调试日志
  static const bool enableDebugLog = true;

  /// 是否启用分析（可用于A/B测试或隐私模式）
  static const bool enabled = true;
}
