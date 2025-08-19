import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseKeys {
  // TODO: Replace with your real keys
  static const String supabaseUrl = 'https://wmroscjdhemybxznwmfg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indtcm9zY2pkaGVteWJ4em53bWZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU1MzY0OTgsImV4cCI6MjA3MTExMjQ5OH0.RaK3ROSAzD9-eeDVW28fkZGPS9i53bycJM9T88GlPRU';
}

class SupabaseInit {
  static Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseKeys.supabaseUrl,
      anonKey: SupabaseKeys.supabaseAnonKey,
      debug: true,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
