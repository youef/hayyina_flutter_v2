import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/post.dart';

class CommunityRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Post>> getPosts() async {
    final rows = await _client
        .from('posts')
        .select('id,user_id,content,created_at,profiles:profiles!posts_user_id_fkey(full_name)')
        .order('created_at', ascending: false)
        .limit(50);

    return (rows as List)
        .map((row) => Post.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<void> createPost(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('يجب تسجيل الدخول أولاً.');
    final value = content.trim();
    if (value.isEmpty) throw const AuthException('اكتب شيئًا قبل النشر.');

    await _client.from('posts').insert({
      'user_id': user.id,
      'content': value,
    });
  }
}
