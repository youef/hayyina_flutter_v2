class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    return Post(
      id: map['id'].toString(),
      authorId: map['user_id'].toString(),
      authorName: (profile?['full_name'] as String?)?.trim().isNotEmpty == true
          ? profile!['full_name'] as String
          : 'عضو في الحي',
      content: (map['content'] as String?)?.trim() ?? '',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      likes: (map['likes_count'] as num?)?.toInt() ?? 0,
      comments: (map['comments_count'] as num?)?.toInt() ?? 0,
    );
  }
}
