class Post {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final bool likedByMe;

  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.likedByMe = false,
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
      likedByMe: map['liked_by_me'] == true,
    );
  }

  Post copyWith({int? likes, int? comments, bool? likedByMe}) {
    return Post(
      id: id,
      authorId: authorId,
      authorName: authorName,
      content: content,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      likedByMe: likedByMe ?? this.likedByMe,
    );
  }
}
