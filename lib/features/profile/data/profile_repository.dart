import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';

class ProfileRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final row = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    return row;
  }

  Future<void> ensureProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    await _client.from('profiles').upsert({
      'id': user.id,
      'full_name': user.userMetadata?['full_name'] ?? '',
      'email': user.email,
    });
  }

  Future<void> signOut() => _client.auth.signOut();
}
