import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/community_repository.dart';
import '../domain/post.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});
  @override State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final _repository = CommunityRepository();
  final _controller = TextEditingController();
  List<Post> _posts = const [];
  bool _loading = true;
  bool _publishing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final posts = await _repository.getPosts();
      if (mounted) setState(() => _posts = posts);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تحميل منشورات المجتمع.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _publish() async {
    if (_controller.text.trim().isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      await _repository.createPost(_controller.text);
      _controller.clear();
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نشر مشاركتك في المجتمع')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر النشر.')));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    try {
      final liked = await _repository.toggleLike(post.id, liked: post.likedByMe);
      if (!mounted) return;
      setState(() {
        _posts = [..._posts]..[index] = post.copyWith(
          likedByMe: liked,
          likes: post.likes + (liked ? 1 : -1),
        );
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر تحديث الإعجاب.')));
    }
  }

  Future<void> _comment(int index) async {
    final controller = TextEditingController();
    final value = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('أضف تعليقًا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, maxLines: 4, decoration: const InputDecoration(hintText: 'اكتب تعليقك...')),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('إرسال')),
          ],
        ),
      ),
    );
    controller.dispose();
    if (value == null || value.isEmpty) return;
    try {
      await _repository.addComment(_posts[index].id, value);
      if (!mounted) return;
      setState(() {
        final post = _posts[index];
        _posts = [..._posts]..[index] = post.copyWith(comments: post.comments + 1);
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر إضافة التعليق.')));
    }
  }

  String _time(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ' + diff.inMinutes.toString() + ' د';
    if (diff.inHours < 24) return 'منذ ' + diff.inHours.toString() + ' س';
    if (diff.inDays < 7) return 'منذ ' + diff.inDays.toString() + ' يوم';
    return DateFormat('d MMM', 'ar').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('مجتمع الحي'),
        actions: [IconButton(onPressed: _load, icon: const Icon(LucideIcons.refreshCw))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _Composer(controller: _controller, publishing: _publishing, onPublish: _publish),
            const SizedBox(height: 20),
            if (_loading)
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              _StateCard(message: _error!, onRetry: _load)
            else if (_posts.isEmpty)
              const _StateCard(message: 'ما فيه منشورات للحين. كن أول واحد يشارك أهل الحي!')
            else
              ..._posts.asMap().entries.map((entry) => _PostCard(
                post: entry.value,
                time: _time(entry.value.createdAt),
                onLike: () => _toggleLike(entry.key),
                onComment: () => _comment(entry.key),
              )),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.publishing, required this.onPublish});
  final TextEditingController controller;
  final bool publishing;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('وش عندك لأهل الحي؟', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(hintText: 'شارك خبر، سؤال، تنبيه أو فكرة...', alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: publishing ? null : onPublish,
            icon: publishing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.send),
            label: Text(publishing ? 'جارٍ النشر...' : 'نشر المشاركة'),
          ),
        ],
      ),
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.time, required this.onLike, required this.onComment});
  final Post post;
  final String time;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: .12),
                child: const Icon(LucideIcons.userRound, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                ],
              )),
            ],
          ),
          const SizedBox(height: 14),
          Text(post.content, style: const TextStyle(fontSize: 15, height: 1.6)),
          const SizedBox(height: 14),
          const Divider(height: 1),
          Row(
            children: [
              TextButton.icon(
                onPressed: onLike,
                icon: Icon(post.likedByMe ? LucideIcons.heart : LucideIcons.heart, size: 18, color: post.likedByMe ? AppColors.danger : AppColors.muted),
                label: Text(post.likes.toString()),
              ),
              TextButton.icon(
                onPressed: onComment,
                icon: const Icon(LucideIcons.messageCircle, size: 18),
                label: Text(post.comments.toString()),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ],
      ),
    ),
  );
}
