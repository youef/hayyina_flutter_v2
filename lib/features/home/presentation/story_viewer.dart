import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/home_repository.dart';

Future<void> showStoryViewer(
  BuildContext context, {
  required List<Map<String, dynamic>> stories,
  required int initialIndex,
}) async {
  await showDialog<void>(
    context: context,
    barrierColor: Colors.black,
    useSafeArea: false,
    builder: (_) => _StoryViewer(
      stories: stories,
      initialIndex: initialIndex,
    ),
  );
}

class _StoryViewer extends StatefulWidget {
  const _StoryViewer({required this.stories, required this.initialIndex});

  final List<Map<String, dynamic>> stories;
  final int initialIndex;

  @override
  State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer> {
  late final PageController _controller;
  final HomeRepository _repository = HomeRepository();
  final Set<String> _markedIds = {};
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: _index);
    _markViewed(_index);
  }

  Future<void> _markViewed(int index) async {
    if (index < 0 || index >= widget.stories.length) return;
    final story = widget.stories[index];
    final id = story['id']?.toString();
    if (id == null || !_markedIds.add(id)) return;
    story['viewed'] = true;
    try {
      await _repository.markStoryViewed(id);
    } catch (_) {}
  }

  void _goTo(int index) {
    if (index < 0) return;
    if (index >= widget.stories.length) {
      Navigator.of(context).pop();
      return;
    }
    _controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.stories.length,
              onPageChanged: (index) {
                setState(() => _index = index);
                _markViewed(index);
              },
              itemBuilder: (context, index) => _StoryCanvas(
                story: widget.stories[index],
                onTap: (position, width) =>
                    _goTo(position < width / 3 ? index - 1 : index + 1),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (var index = 0;
                            index < widget.stories.length;
                            index++)
                          Expanded(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsetsDirectional.only(end: 4),
                              decoration: BoxDecoration(
                                color: index <= _index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _StoryAuthor(story: widget.stories[_index]),
                        const Spacer(),
                        IconButton(
                          tooltip: 'إغلاق القصة',
                          onPressed: () => Navigator.of(context).pop(),
                          color: Colors.white,
                          icon: const Icon(LucideIcons.x),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class _StoryCanvas extends StatelessWidget {
  const _StoryCanvas({required this.story, required this.onTap});

  final Map<String, dynamic> story;
  final void Function(double position, double width) onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = story['image_url']?.toString();
    final isImage =
        story['type'] == 'image' && imageUrl != null && imageUrl.isNotEmpty;
    final background =
        _parseColor(story['bg_color']?.toString()) ?? AppColors.primaryDark;
    final textColor =
        _parseColor(story['text_color']?.toString()) ?? Colors.white;
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) =>
            onTap(details.localPosition.dx, constraints.maxWidth),
        child: Container(
          color: background,
          alignment: Alignment.center,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isImage)
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(LucideIcons.imageOff,
                        color: Colors.white, size: 48),
                  ),
                ),
              if (story['content'] != null &&
                  story['content'].toString().isNotEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 120),
                    child: Text(
                      story['content'].toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: isImage ? 24 : 34,
                        fontWeight: FontWeight.w800,
                        height: 1.5,
                        shadows: isImage
                            ? const [
                                Shadow(color: Colors.black54, blurRadius: 12)
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoryAuthor extends StatelessWidget {
  const _StoryAuthor({required this.story});

  final Map<String, dynamic> story;

  @override
  Widget build(BuildContext context) {
    final profile =
        Map<String, dynamic>.from(story['profile'] as Map? ?? const {});
    final avatar = profile['avatar_url']?.toString();
    final created = DateTime.tryParse(story['created_at']?.toString() ?? '');
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage:
              avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
          child: avatar == null || avatar.isEmpty
              ? Text(
                  (profile['display_name'] ?? 'م').toString().characters.first)
              : null,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text((profile['display_name'] ?? 'جار من الحي').toString(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            if (created != null)
              Text(DateFormat('HH:mm', 'ar').format(created.toLocal()),
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

Color? _parseColor(String? value) {
  if (value == null) return null;
  final hex = value.replaceFirst('#', '');
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final color = int.tryParse(normalized, radix: 16);
  return color == null ? null : Color(color);
}
