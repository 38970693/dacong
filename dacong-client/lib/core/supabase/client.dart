// Supabase 客户端（保留，供后续扩展）
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/constants.dart';

class SupabaseClient {
  SupabaseClient._();
  static final _instance = SupabaseClient._();
  static SupabaseClient get instance => _instance;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    _initialized = true;
  }

  SupabaseClient get client => this;
}
