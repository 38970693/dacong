class AppConstants {
  // 环境配置
  static const Environment environment = Environment.dev;

  // Supabase 配置
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://twrxnqrisplmetbceyqm.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.placeholder',
  );

  // API 端点配置
  static String get apiBaseUrl {
    switch (environment) {
      case Environment.dev:
        return 'http://localhost:8000/api';
      case Environment.staging:
        return 'https://staging-api.dacong.com/api';
      case Environment.prod:
        return 'https://api.dacong.com/api';
    }
  }

  // API 配置
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // 缓存配置
  static const Duration cacheExpiration = Duration(minutes: 5);
  static const int maxCacheSize = 100;

  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 应用信息
  static const String appName = 'DaCong';
  static const String appVersion = '0.1.0';
  static const String appBuildNumber = '1';

  // 功能开关
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;
  static const bool enableDebugLogging = true;
}

enum Environment {
  dev,
  staging,
  prod,
}
