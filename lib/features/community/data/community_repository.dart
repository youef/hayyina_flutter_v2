import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';
import '../domain/post.dart';

class CommunityRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<List<Post>> getPosts() async {
    final rows = await _client
        .from('posts')
        .select('id,user_id,content,created_at,profiles:profiles!posts_user_id_fkey(full_name),post_likes(user_id),post_comments(id)')
        .order('created_at', ascending: false)
        .limit(50);

    final currentUserId = _client.auth.currentUser?.id;
    return (rows as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final likes = (row['post_likes'] as List?) ?? const [];
      final comments = (row['post_comments'] as List?) ?? const [];
      row['likes_count'] = likes.length;
      row['comments_count'] = comments.length;
      row['liked_by_me'] = currentUserId != null &&
          likes.any((like) => (like as Map)['user_id']?.toString() == currentUserId);
      return Post.fromMap(row);
    }).toList();
  }

  Future<void> createPost(String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('يجب تسجيل الدخول أولاً.');
    final value = content.trim();
    if (value.isEmpty) throw const AuthException('اكتب شيئًا قبل النشر.');

    await _client.from('posts').insert({'user_id': user.id, 'content': value});
  }

  Future<bool> toggleLike(String postId, {required bool liked}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('يجب تسجيل الدخول أولاً.');

    if (liked) {
      await _client.from('post_likes').delete().eq('post_id', postId).eq('user_id', user.id);
      return false;
    }

    await _client.from('post_likes').upsert({
      'post_id': postId,
      'user_id': user.id,
    });
    return true;
  }

  Future<void> addComment(String postId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const AuthException('يجب تسجيل الدخول أولاً.');
    final value = content.trim();
    if (value.isEmpty) return;

    await _client.from('post_comments').insert({
      'post_id': postId,
      'user_id': user.id,
      'content': value,
    });
  }
}
