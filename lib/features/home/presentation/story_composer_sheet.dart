import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/home_repository.dart';

Future<bool> showStoryComposer(BuildContext context) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _StoryComposerSheet(),
    ) ??
    false;

class _StoryComposerSheet extends StatefulWidget {
  const _StoryComposerSheet();

  @override
  State<_StoryComposerSheet> createState() => _StoryComposerSheetState();
}

class _StoryComposerSheetState extends State<_StoryComposerSheet> {
  static const _colors = [
    Color(0xFF0B7774),
    Color(0xFF1D4E89),
    Color(0xFF8D3B65),
    Color(0xFF9A5B16),
    Color(0xFF344054),
  ];

  final _controller = TextEditingController();
  final _picker = ImagePicker();
  final _repository = HomeRepository();
  XFile? _image;
  Uint8List? _previewBytes;
  Color _background = _colors.first;
  bool _publishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _image = image;
            _previewBytes = bytes;
          });
        }
      }
    } catch (_) {
      if (mounted) _showMessage('تعذر فتح ألبوم الصور.');
    }
  }

  Future<void> _publish() async {
    if (_publishing || (_controller.text.trim().isEmpty && _image == null)) {
      return;
    }
    setState(() => _publishing = true);
    try {
      await _repository.createStory(
        content: _controller.text,
        backgroundColor:
            '#${_background.toARGB32().toRadixString(16).substring(2)}',
        image: _image,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        final message = error is StateError
            ? error.message
            : 'تعذر نشر القصة. تأكد من إعداد مساحة القصص في Supabase.';
        _showMessage(message.toString());
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('قصة جديدة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          )),
                ),
                IconButton(
                  tooltip: 'اختيار صورة',
                  onPressed: _publishing ? null : _pickImage,
                  icon: const Icon(LucideIcons.imagePlus),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 190, maxHeight: 360),
              decoration: BoxDecoration(
                color: _background,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  if (_image != null)
                    if (_previewBytes != null)
                      Image.memory(_previewBytes!, fit: BoxFit.cover),
                  if (_image != null)
                    ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: TextField(
                        controller: _controller,
                        maxLength: 300,
                        maxLines: 5,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: _image == null
                              ? 'وش ودك تشارك جيرانك؟'
                              : 'أضف تعليقاً للصورة',
                          hintStyle: const TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                          counterStyle: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  if (_image != null)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: IconButton.filledTonal(
                        tooltip: 'إزالة الصورة',
                        onPressed: () => setState(() {
                          _image = null;
                          _previewBytes = null;
                        }),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Text('الخلفية',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 12),
                for (final color in _colors)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 10),
                    child: InkWell(
                      onTap: () => setState(() => _background = color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _background == color
                                ? AppColors.ink
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _publishing ? null : _publish,
              icon: _publishing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.send),
              label: Text(_publishing ? 'جارٍ النشر...' : 'نشر لمدة 24 ساعة'),
            ),
          ],
        ),
      ),
    );
  }
}
