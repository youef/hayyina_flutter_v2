import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<AuthResponse> signIn({required String email, required String password}) =>
      _client.auth.signInWithPassword(email: email.trim(), password: password);

  Future<AuthResponse> signUp({required String email, required String password, required String name}) =>
      _client.auth.signUp(email: email.trim(), password: password, data: {'full_name': name.trim()});

  Future<void> signOut() => _client.auth.signOut();
}
