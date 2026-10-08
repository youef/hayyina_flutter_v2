import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/data/home_repository.dart';

enum _MarketTab { services, businesses, events }

enum _MarketFilter { all, available, delivery, images }

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final HomeRepository _repository = HomeRepository();
  late Future<_MarketData> _future;
  _MarketTab _tab = _MarketTab.services;
  _MarketFilter _filter = _MarketFilter.all;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_MarketData> _load() async {
    final header = await _repository.getHeader();
    final profile = Map<String, dynamic>.from(
      header['profile'] as Map<String, dynamic>? ?? const {},
    );
    final city = profile['city']?.toString();
    final results = await Future.wait([
      _repository.getServices(city),
      _repository.getBusinesses(city),
      _repository.getEvents(city),
    ]);
    return _MarketData(
      city: city ?? '',
      services: results[0] as List<Map<String, dynamic>>,
      businesses: results[1] as List<Map<String, dynamic>>,
      events: results[2] as List<Map<String, dynamic>>,
    );
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() => _future = future);
    try {
      await future;
    } catch (_) {}
  }

  List<Map<String, dynamic>> _visibleItems(_MarketData data) {
    final source = switch (_tab) {
      _MarketTab.services => data.services,
      _MarketTab.businesses => data.businesses,
      _MarketTab.events => data.events,
    };
    return source.where((item) {
      final searchable = [
        item['name'],
        item['title'],
        item['description'],
        item['district'],
        item['category_name'],
        item['category'],
      ].whereType<Object>().join(' ').toLowerCase();
      if (_search.trim().isNotEmpty &&
          !searchable.contains(_search.trim().toLowerCase())) {
        return false;
      }
      return switch (_filter) {
        _MarketFilter.all => true,
        _MarketFilter.available => _tab == _MarketTab.services
            ? item['available_now'] == true
            : _tab == _MarketTab.businesses && item['is_open_now'] == true,
        _MarketFilter.delivery => _tab == _MarketTab.services &&
            item['delivery_modes'].toString().toLowerCase().contains('delivery'),
        _MarketFilter.images => [
            item['cover_url'],
            item['logo_url'],
            item['images'],
          ].any((value) => value is List
              ? value.isNotEmpty
              : value != null && value.toString().isNotEmpty),
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_MarketData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _MarketMessage(
            icon: LucideIcons.cloudOff,
            title: 'تعذر تحميل السوق',
            message: 'تحقق من اتصالك ثم حاول مرة أخرى.',
            action: FilledButton.icon(
              onPressed: () => setState(() => _future = _load()),
              icon: const Icon(LucideIcons.refreshCw),
              label: const Text('إعادة المحاولة'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final items = _visibleItems(data);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _MarketHeading(city: data.city),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => setState(() => _search = value),
                decoration: InputDecoration(
                  hintText: 'ابحث عن خدمة أو متجر أو فعالية',
                  prefixIcon: const Icon(LucideIcons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<_MarketTab>(
                segments: const [
                  ButtonSegment(
                    value: _MarketTab.services,
                    label: Text('خدمات'),
                    icon: Icon(LucideIcons.wrench),
                  ),
                  ButtonSegment(
                    value: _MarketTab.businesses,
                    label: Text('متاجر'),
                    icon: Icon(LucideIcons.store),
                  ),
                  ButtonSegment(
                    value: _MarketTab.events,
                    label: Text('فعاليات'),
                    icon: Icon(LucideIcons.calendarDays),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (selection) => setState(() {
                  _tab = selection.first;
                  _filter = _MarketFilter.all;
                }),
                showSelectedIcon: false,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip(_MarketFilter.all, 'الكل'),
                    if (_tab != _MarketTab.events)
                      _filterChip(_MarketFilter.available, 'متاح الآن'),
                    if (_tab == _MarketTab.services)
                      _filterChip(_MarketFilter.delivery, 'توصيل'),
                    _filterChip(_MarketFilter.images, 'بالصور'),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    _tab.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  Text('${items.length} نتائج',
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const _MarketMessage(
                  icon: LucideIcons.searchX,
                  title: 'ما لقينا نتائج',
                  message: 'جرّب تغيير البحث أو الفلتر.',
                )
              else
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ListingCard(
                        tab: _tab,
                        item: item,
                        onTap: () => _showDetails(context, item),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }

  Widget _filterChip(_MarketFilter filter, String label) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _filter == filter,
          onSelected: (_) => setState(() => _filter = filter),
        ),
      );

  void _showDetails(BuildContext context, Map<String, dynamic> item) {
    final title = (item['name'] ?? item['title'] ?? 'تفاصيل الإعلان').toString();
    final description = (item['description'] ?? '').toString();
    final district = (item['district'] ?? '').toString();
    final location = [item['city'], if (district.isNotEmpty) 'حي $district']
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .join(' • ');
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
              if (location.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(children: [
                  const Icon(LucideIcons.mapPin, size: 18, color: AppColors.muted),
                  const SizedBox(width: 6),
                  Text(location, style: const TextStyle(color: AppColors.muted)),
                ]),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(description, style: const TextStyle(height: 1.6)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension on _MarketTab {
  String get label => switch (this) {
        _MarketTab.services => 'الخدمات القريبة',
        _MarketTab.businesses => 'متاجر الحي',
        _MarketTab.events => 'فعاليات قريبة',
      };
}

class _MarketData {
  const _MarketData({
    required this.city,
    required this.services,
    required this.businesses,
    required this.events,
  });

  final String city;
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> businesses;
  final List<Map<String, dynamic>> events;
}

class _MarketHeading extends StatelessWidget {
  const _MarketHeading({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('سوق حيّنا',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        )),
                const SizedBox(height: 4),
                Text(
                  city.isEmpty ? 'خدمات ومتاجر وفعاليات حولك' : 'اكتشف جديد $city',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(LucideIcons.store, color: AppColors.primary),
          ),
        ],
      );
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.tab,
    required this.item,
    required this.onTap,
  });

  final _MarketTab tab;
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = (item['name'] ?? item['title'] ?? 'إعلان').toString();
    final imageUrl = (item['cover_url'] ?? item['logo_url'])?.toString();
    final district = (item['district'] ?? '').toString();
    final category = (item['category_name'] ?? item['category'] ?? '').toString();
    final available = tab == _MarketTab.services
        ? item['available_now'] == true
        : item['is_open_now'] == true;
    final subtitle = switch (tab) {
      _MarketTab.services => available ? 'متاح الآن' : 'خدمة من الحي',
      _MarketTab.businesses => available ? 'مفتوح الآن' : 'دليل متاجر الحي',
      _MarketTab.events => _eventDate(item['starts_at']?.toString()),
    };

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _ListingImage(tab: tab),
                      )
                    : _ListingImage(tab: tab),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          tab == _MarketTab.events
                              ? LucideIcons.calendarDays
                              : available
                                  ? LucideIcons.circleCheck
                                  : LucideIcons.mapPin,
                          size: 14,
                          color: available ? AppColors.success : AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            [subtitle, if (district.isNotEmpty) 'حي $district']
                                .where((value) => value.isNotEmpty)
                                .join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: available ? AppColors.success : AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.tab});

  final _MarketTab tab;

  @override
  Widget build(BuildContext context) => Container(
        width: 68,
        height: 68,
        color: AppColors.primary.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Icon(
          switch (tab) {
            _MarketTab.services => LucideIcons.wrench,
            _MarketTab.businesses => LucideIcons.store,
            _MarketTab.events => LucideIcons.calendarDays,
          },
          color: AppColors.primary,
        ),
      );
}

class _MarketMessage extends StatelessWidget {
  const _MarketMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 38, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

String _eventDate(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) return 'فعالية قريبة';
  return DateFormat('d MMM', 'ar').format(date);
}