// DaCong 应用常量
// 所有硬编码配置值统一在此管理
class AppConstants {
  AppConstants._();

  // API
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://twrxnqrisplmetbceyqm.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR3cnhucXJpc3BsbWV0YmNleXFtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjAzNTcsImV4cCI6MjA5MTgzNjM1N30.GQm3JUk2jkHf_boqj_vTRusWqvhEN55lLG3tdPYnohw',
  );

  static const bool debugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );

  // 分页
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // 缓存时间（分钟）
  static const int rankingCacheMinutes = 5;
  static const int newsCacheMinutes = 3;

  // 日期格式
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
}
