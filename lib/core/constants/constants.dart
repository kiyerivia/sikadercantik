import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String _defaultSupabaseUrl =
      'https://iyznzyqhsbjgtvxgiewe.supabase.co';
  static const String _defaultSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml5em56eXFoc2JqZ3R2eGdpZXdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcxMTQzMzUsImV4cCI6MjA5MjY5MDMzNX0.JaaXQd9n8uJPZwO-WQ7m06Kvf1Rw35itu07MAAOBKyQ';

  static String get supabaseUrl {
    try {
      final url = dotenv.maybeGet('SUPABASE_URL');
      if (url != null && url.isNotEmpty) return url;
    } catch (_) {}
    return const String.fromEnvironment('SUPABASE_URL',
        defaultValue: _defaultSupabaseUrl);
  }

  static String get supabaseAnonKey {
    try {
      final key = dotenv.maybeGet('SUPABASE_ANON_KEY');
      if (key != null && key.isNotEmpty) return key;
    } catch (_) {}
    return const String.fromEnvironment('SUPABASE_ANON_KEY',
        defaultValue: _defaultSupabaseAnonKey);
  }
}
