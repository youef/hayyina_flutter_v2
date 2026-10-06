import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../data/home_repository.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeRepository _repository = HomeRepository();
  late final Future<_HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadHome();
  }

  Future<_HomeData> _loadHome() async {
    final profile = await _repository.getHeader();
    final profileMap = Map<String, dynamic>.from(profile['profile'] as Map<String, dynamic>? ?? const {});
    final city = (profileMap['city'] ?? '').toString();

    final results = await Future.wait([
      _repository.getStories(),
      _repository.getCommunityQuestions(),
      _repository.getNearbyRequests(city),
      _repository.getServices(city),
      _repository.getBusinesses(city),
      _repository.getUnansweredQuestions(),
      _repository.getEvents(city),
    ]);

    return _HomeData(
      profile: profileMap,
      unreadCount: (profile['unread_count'] as num?)?.toInt() ?? 0,
      stories: results[0] as List<Map<String, dynamic>>,
      communityQuestions: results[1] as List<Map<String, dynamic>>,
      nearbyRequests: results[2] as List<Map<String, dynamic>>,
      services: results[3] as List<Map<String, dynamic>>,
      businesses: results[4] as List<Map<String, dynamic>>,
      questions: results[5] as List<Map<String, dynamic>>,
      events: results[6] as List<Map<String, dynamic>>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'تعذر تحميل الصفحة الرئيسية',
            onRetry: () => setState(() {
              _future = _loadHome();
            }),
          );
        }

        final data = snapshot.data ?? _HomeData.empty();
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _loadHome()),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _HeaderSection(
                profile: data.profile,
                unreadCount: data.unreadCount,
              ),
              const SizedBox(height: 18),
              _StoriesSection(stories: data.stories),
              const SizedBox(height: 18),
              _QuickActionsSection(),
              const SizedBox(height: 18),
              _CreateSection(),
              const SizedBox(height: 18),
              _SectionTitle(title: '🏘️ مجتمع الحي'),
              _QuestionFeedSection(questions: data.communityQuestions),
              const SizedBox(height: 18),
              _SectionTitle(title: '🤝 طلبات مساعدة قريبة'),
              _NearbyHelpSection(requests: data.nearbyRequests),
              const SizedBox(height: 18),
              _SectionTitle(title: '🔧 خدمات قريبة'),
              _ServicesSection(services: data.services),
              const SizedBox(height: 18),
              _SectionTitle(title: '🏪 متاجر من حولك'),
              _BusinessesSection(businesses: data.businesses),
              const SizedBox(height: 18),
              _SectionTitle(title: '❓ أسئلة تحتاج إجابة'),
              _QuestionsSection(questions: data.questions),
              const SizedBox(height: 18),
              _SectionTitle(title: '🎉 فعاليات قريبة'),
              _EventsSection(events: data.events),
            ],
          ),
        );
      },
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.profile,
    required this.unreadCount,
    required this.stories,
    required this.communityQuestions,
    required this.nearbyRequests,
    required this.services,
    required this.businesses,
    required this.questions,
    required this.events,
  });

  factory _HomeData.empty() => const _HomeData(
    profile: {},
    unreadCount: 0,
    stories: [],
    communityQuestions: [],
    nearbyRequests: [],
    services: [],
    businesses: [],
    questions: [],
    events: [],
  );

  final Map<String, dynamic> profile;
  final int unreadCount;
  final List<Map<String, dynamic>> stories;
  final List<Map<String, dynamic>> communityQuestions;
  final List<Map<String, dynamic>> nearbyRequests;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> businesses;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> events;
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.profile, required this.unreadCount});

  final Map<String, dynamic> profile;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final name = (profile['display_name'] ?? 'مستخدم').toString();
    final city = (profile['city'] ?? 'المدينة').toString();
    final district = (profile['district'] ?? '').toString();
    final avatarUrl = profile['avatar_url']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.16),
            AppColors.primary.withOpacity(0.06),
          ],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null || avatarUrl.isEmpty ? Text(name.isNotEmpty ? name.substring(0, math.min(name.length, 1)) : 'م') : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('هلا بك 👋', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  [city, district].where((value) => value.isNotEmpty).join(' / '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(LucideIcons.search),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.bell),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoriesSection extends StatelessWidget {
  const _StoriesSection({required this.stories});

  final List<Map<String, dynamic>> stories;

  @override
  Widget build(BuildContext context) {
    final items = stories.take(6).toList();
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _StoryItem(
              title: 'قصتك',
              icon: LucideIcons.plus,
              isAdd: true,
              avatarUrl: null,
              bgColor: AppColors.primary.withOpacity(0.12),
            );
          }

          final item = items[index - 1];
          final profile = Map<String, dynamic>.from(item['profile'] as Map? ?? const {});
          final displayName = (profile['display_name'] ?? 'مستخدم').toString();
          final avatarUrl = profile['avatar_url']?.toString();
          final viewed = item['viewed'] == true;

          return _StoryItem(
            title: displayName,
            icon: null,
            avatarUrl: avatarUrl,
            bgColor: viewed ? Colors.white : AppColors.primary.withOpacity(0.10),
            borderColor: viewed ? AppColors.border : AppColors.primary,
          );
        },
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  const _StoryItem({
    required this.title,
    required this.icon,
    required this.avatarUrl,
    required this.bgColor,
    this.isAdd = false,
    this.borderColor,
  });

  final String title;
  final IconData? icon;
  final String? avatarUrl;
  final Color bgColor;
  final bool isAdd;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: isAdd
                  ? null
                  : LinearGradient(
                      colors: [
                        bgColor,
                        (borderColor ?? AppColors.primary).withOpacity(0.25),
                      ],
                    ),
              color: isAdd ? AppColors.primary.withOpacity(0.12) : null,
              border: Border.all(color: borderColor ?? AppColors.border, width: isAdd ? 1 : 2),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: isAdd
                ? Icon(icon, color: AppColors.primary)
                : CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl != null && avatarUrl.isNotEmpty ? null : Text(title.characters.firstOrNull ?? 'م'),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  static const actions = [
    ('❓', 'اسأل'),
    ('🔧', 'خدمة'),
    ('🤝', 'مساعدة'),
    ('🛍️', 'السوق'),
    ('📍', 'حولك'),
    ('🎉', 'فعاليات'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final action in actions)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action.$1, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(action.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
      ],
    );
  }
}

class _CreateSection extends StatelessWidget {
  const _CreateSection();

  static const createOptions = [
    ('❓', 'اسأل'),
    ('🤝', 'أحتاج مساعدة'),
    ('🔧', 'أقدم خدمة'),
    ('📸', 'أضف قصة'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('وش تحتاج؟ 👋', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in createOptions)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option.$1, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(option.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }
}

class _QuestionFeedSection extends StatelessWidget {
  const _QuestionFeedSection({required this.questions});

  final List<Map<String, dynamic>> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const _EmptyState(message: 'لا توجد أسئلة في مجتمع الحي сейчас.');
    }

    return Column(
      children: questions.take(3).map((question) {
        final profile = Map<String, dynamic>.from(question['profile'] as Map? ?? const {});
        final title = (question['title'] ?? 'سؤال').toString();
        final district = (question['district'] ?? '').toString();
        final createdAt = question['created_at']?.toString() ?? '';
        final answersCount = (question['answers_count'] as num?)?.toInt() ?? 0;
        final views = (question['view_count'] as num?)?.toInt() ?? 0;
        final isEmergency = question['is_emergency'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: _avatarImage(profile['avatar_url']),
                      child: _avatarChild(profile['avatar_url'], profile['display_name']),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text((profile['display_name'] ?? 'مستخدم').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                              if (profile['is_verified'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(LucideIcons.badgeCheck, size: 16, color: AppColors.primary),
                              ],
                            ],
                          ),
                          Text(
                            '${_timeAgo(createdAt)} • ${district.isNotEmpty ? 'حي $district' : 'حي قريب'}',
                            style: const TextStyle(fontSize: 12, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    if (isEmergency)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('طارئ', style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w800)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(LucideIcons.messageCircle, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text('$answersCount إجابات', style: const TextStyle(color: AppColors.muted)),
                    const SizedBox(width: 18),
                    const Icon(LucideIcons.eye, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(views.toString(), style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _NearbyHelpSection extends StatelessWidget {
  const _NearbyHelpSection({required this.requests});

  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyState(message: 'لا توجد طلبات مساعدة قريبة في المدينة الحالية.');
    }

    return Column(
      children: requests.take(3).map((request) {
        final profile = Map<String, dynamic>.from(request['profile'] as Map? ?? const {});
        final title = (request['title'] ?? 'يطلب مساعدة').toString();
        final description = (request['description'] ?? '').toString();
        final district = (request['district'] ?? '').toString();
        final urgent = request['is_urgent'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: _avatarImage(profile['avatar_url']),
                      child: _avatarChild(profile['avatar_url'], profile['display_name']),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text((profile['display_name'] ?? 'مستخدم').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    if (urgent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('عاجل', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.warning)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(LucideIcons.mapPin, size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Text(district.isNotEmpty ? 'حي $district' : 'موقع قريب', style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.handHelping, size: 16),
                    label: const Text('أقدر أساعد'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services});

  final List<Map<String, dynamic>> services;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return const _EmptyState(message: 'لا توجد خدمات قريبة من موقعك الآن.');
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final service = services[index];
          final coverUrl = service['cover_url']?.toString();
          final name = (service['name'] ?? 'خدمة').toString();
          final district = (service['district'] ?? '').toString();
          final available = service['available_now'] == true;
          final provider = Map<String, dynamic>.from(service['profile'] as Map? ?? const {});

          return Container(
            width: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: coverUrl != null && coverUrl.isNotEmpty
                      ? Image.network(
                          coverUrl,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 90,
                            color: AppColors.primary.withOpacity(0.12),
                            alignment: Alignment.center,
                            child: const Icon(LucideIcons.wrench, color: AppColors.primary),
                          ),
                        )
                      : Container(
                          height: 90,
                          width: double.infinity,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(LucideIcons.wrench, color: AppColors.primary),
                        ),
                ),
                const SizedBox(height: 10),
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text((provider['is_verified'] == true ? '4.9' : '4.7'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(available ? LucideIcons.circleCheckBig : LucideIcons.clock3, size: 14, color: available ? AppColors.success : AppColors.muted),
                    const SizedBox(width: 6),
                    Text(available ? 'متاح الآن' : 'حاليًا غير متاح', style: TextStyle(color: available ? AppColors.success : AppColors.muted, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BusinessesSection extends StatelessWidget {
  const _BusinessesSection({required this.businesses});

  final List<Map<String, dynamic>> businesses;

  @override
  Widget build(BuildContext context) {
    if (businesses.isEmpty) {
      return const _EmptyState(message: 'لا توجد متاجر قريبة من موقعك.');
    }

    return Column(
      children: businesses.take(3).map((business) {
        final name = (business['name'] ?? 'متجر').toString();
        final district = (business['district'] ?? '').toString();
        final open = business['is_open_now'] == true;
        final logo = business['logo_url']?.toString();
        final category = (business['category_name'] ?? '').toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipOval(
                  child: logo != null && logo.isNotEmpty
                      ? Image.network(
                          logo,
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 42, height: 42, color: AppColors.primary.withOpacity(0.1), child: const Icon(LucideIcons.store, size: 18, color: AppColors.primary)),
                        )
                      : Container(width: 42, height: 42, color: AppColors.primary.withOpacity(0.1), child: const Icon(LucideIcons.store, size: 18, color: AppColors.primary)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(LucideIcons.star, size: 14, color: AppColors.warning),
                          const SizedBox(width: 4),
                          const Text('4.8', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(category.isNotEmpty ? '$category • حي $district' : 'حي $district', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: open ? AppColors.success.withOpacity(0.12) : AppColors.muted.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    open ? 'مفتوح الآن' : 'مغلق',
                    style: TextStyle(
                      color: open ? AppColors.success : AppColors.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuestionsSection extends StatelessWidget {
  const _QuestionsSection({required this.questions});

  final List<Map<String, dynamic>> questions;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const _EmptyState(message: 'لا توجد أسئلة تحتاج إجابة حاليًا.');
    }

    return Column(
      children: questions.take(5).map((question) {
        final title = (question['title'] ?? 'سؤال').toString();
        final answers = (question['answers_count'] as num?)?.toInt() ?? 0;
        final urgent = question['is_emergency'] == true;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: urgent ? AppColors.warning.withOpacity(0.12) : AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${answers} إجابة',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.warning : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.events});

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const _EmptyState(message: 'لا توجد فعاليات قريبة في المدينة الحالية.');
    }

    return Column(
      children: events.take(3).map((event) {
        final title = (event['title'] ?? 'فعالية').toString();
        final description = (event['description'] ?? '').toString();
        final location = (event['location_name'] ?? 'مكان الفعالية').toString();
        final startsAt = event['starts_at']?.toString();
        final coverUrl = event['cover_url']?.toString();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (coverUrl != null && coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    coverUrl,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 150, color: AppColors.primary.withOpacity(0.12)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (startsAt != null && startsAt.isNotEmpty)
                      Row(
                        children: [
                          const Icon(LucideIcons.calendarDays, size: 16, color: AppColors.muted),
                          const SizedBox(width: 6),
                          Text(_formatDate(startsAt), style: const TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(LucideIcons.mapPin, size: 16, color: AppColors.muted),
                        const SizedBox(width: 6),
                        Expanded(child: Text(location, style: const TextStyle(color: AppColors.muted))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.muted)),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 44, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider? _avatarImage(String? value) {
  final image = value?.trim();
  if (image == null || image.isEmpty) return null;
  return NetworkImage(image);
}

Widget? _avatarChild(String? value, String? fallbackName) {
  final image = value?.trim();
  if (image != null && image.isNotEmpty) return null;
  final first = (fallbackName ?? 'م').trim();
  return Text(first.isNotEmpty ? first.substring(0, 1) : 'م');
}

String _timeAgo(String iso) {
  try {
    final date = DateTime.tryParse(iso);
    if (date == null) return 'الآن';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return DateFormat('d MMM', 'ar').format(date);
  } catch (_) {
    return 'الآن';
  }
}

String _formatDate(String iso) {
  try {
    final date = DateTime.tryParse(iso);
    if (date == null) return 'قريبًا';
    return DateFormat('EEE d MMM • HH:mm', 'ar').format(date);
  } catch (_) {
    return 'قريبًا';
  }
}
