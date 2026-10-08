import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/home_repository.dart';

Future<void> showNotificationsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const _NotificationsSheet(),
  );
}

class _NotificationsSheet extends StatefulWidget {
  const _NotificationsSheet();

  @override
  State<_NotificationsSheet> createState() => _NotificationsSheetState();
}

class _NotificationsSheetState extends State<_NotificationsSheet> {
  final HomeRepository _repository = HomeRepository();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getNotifications();
  }

  Future<void> _markRead(Map<String, dynamic> item) async {
    final id = item['id']?.toString();
    if (id == null || item['read_at'] != null) return;
    setState(() => item['read_at'] = DateTime.now().toUtc().toIso8601String());
    try {
      await _repository.markNotificationRead(id);
    } catch (_) {
      if (mounted) {
        setState(() => item['read_at'] = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث حالة التنبيه.')),
        );
      }
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _repository.markAllNotificationsRead();
      if (mounted) setState(() => _future = _repository.getNotifications());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحديث التنبيهات.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SizedBox(
      height: height.clamp(320, 620),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('التنبيهات',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          )),
                ),
                TextButton.icon(
                  onPressed: _markAllRead,
                  icon: const Icon(LucideIcons.checkCheck, size: 17),
                  label: const Text('تحديد كمقروء'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const _NotificationState(
                      icon: LucideIcons.cloudOff,
                      message: 'تعذر تحميل التنبيهات.',
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return const _NotificationState(
                      icon: LucideIcons.bell,
                      message: 'ما عندك تنبيهات حالياً.',
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isUnread = item['read_at'] == null;
                      final createdAt = DateTime.tryParse(
                          item['created_at']?.toString() ?? '');
                      return ListTile(
                        onTap: () => _markRead(item),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isUnread
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : AppColors.background,
                          child: Icon(
                            _iconFor(item['type']?.toString()),
                            color:
                                isUnread ? AppColors.primary : AppColors.muted,
                            size: 19,
                          ),
                        ),
                        title: Text(
                          (item['title'] ?? 'تنبيه جديد').toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight:
                                isUnread ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          (item['body'] ?? '').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: isUnread
                            ? const Icon(LucideIcons.circle,
                                size: 9, color: AppColors.primary)
                            : createdAt == null
                                ? null
                                : Text(
                                    DateFormat('d/M', 'ar')
                                        .format(createdAt.toLocal()),
                                    style: const TextStyle(
                                        fontSize: 11, color: AppColors.muted),
                                  ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationState extends StatelessWidget {
  const _NotificationState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.muted, size: 34),
            const SizedBox(height: 10),
            Text(message, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      );
}

IconData _iconFor(String? type) => switch (type) {
      'emergency' => LucideIcons.triangleAlert,
      'answer' => LucideIcons.messageCircle,
      'request' => LucideIcons.handHelping,
      'story' => LucideIcons.circlePlay,
      'message' => LucideIcons.messagesSquare,
      _ => LucideIcons.bell,
    };
