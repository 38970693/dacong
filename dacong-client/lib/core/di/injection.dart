import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/api_client.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();

/// 依赖注入配置模块
@module
abstract class AppModule {
  @lazySingleton
  Dio provideDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
  }

  @lazySingleton
  SupabaseClient provideSupabaseClient() {
    return Supabase.instance.client;
  }

  @preResolve
  Future<SharedPreferences> provideSharedPreferences() {
    return SharedPreferences.getInstance();
  }
}
