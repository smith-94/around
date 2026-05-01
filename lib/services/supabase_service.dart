import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      // 키가 비어있어도 앱은 뜨도록(개발 편의). 실제 호출 시 실패합니다.
      // ignore: avoid_print
      print('[around] Supabase 키가 설정되지 않았습니다. lib/config/supabase_config.dart 를 확인하세요.');
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
}
