import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/section_header.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مساء الخير 👋', style: TextStyle(color: AppColors.muted, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('وش صاير في حيّك؟', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary.withValues(alpha: .1),
              child: const Icon(LucideIcons.userRound, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('اكتشف حيّك', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                      SizedBox(height: 6),
                      Text('أماكن، خدمات، فعاليات وأخبار قريبة منك', style: TextStyle(color: Colors.white70, height: 1.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                  child: const Icon(LucideIcons.mapPinned, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'الوصول السريع'),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(icon: LucideIcons.megaphone, title: 'بلاغ', color: AppColors.danger),
            _QuickAction(icon: LucideIcons.shoppingBag, title: 'السوق', color: AppColors.primary),
            _QuickAction(icon: LucideIcons.calendarDays, title: 'فعاليات', color: AppColors.warning),
            _QuickAction(icon: LucideIcons.map, title: 'الخريطة', color: Colors.indigo),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'آخر ما يحدث في الحي', action: 'عرض الكل'),
        const SizedBox(height: 12),
        const _ActivityCard(
          icon: LucideIcons.store,
          title: 'متجر جديد في الحي',
          subtitle: 'تمت إضافة نشاط تجاري جديد بالقرب منك',
          time: 'منذ 12 دقيقة',
        ),
        const SizedBox(height: 10),
        const _ActivityCard(
          icon: LucideIcons.calendarDays,
          title: 'فعالية هذا الأسبوع',
          subtitle: 'فعالية مجتمعية قريبة منك',
          time: 'منذ ساعة',
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.title, required this.color});
  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: Column(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(17)),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 7),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.icon, required this.title, required this.subtitle, required this.time});
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .1), borderRadius: BorderRadius.circular(15)),
            child: const Icon(LucideIcons.bellRing, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ])),
          Text(time, style: const TextStyle(color: AppColors.muted, fontSize: 10)),
        ],
      ),
    );
  }
}
