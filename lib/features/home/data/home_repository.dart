import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_client.dart';

class HomeRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  Future<Map<String, dynamic>> getHeader() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return {};

    final profile = await _client
        .from('profiles')
        .select('id,display_name,username,avatar_url,is_verified,city,district')
        .eq('id', userId)
        .maybeSingle();
    final unread = await _client
        .from('notifications')
        .select('id')
        .eq('user_id', userId)
        .isFilter('read_at', null)
        .count(CountOption.exact);

    return {
      'profile': profile ?? <String, dynamic>{},
      'unread_count': unread.count,
    };
  }

  Future<List<Map<String, dynamic>>> getStories() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final follows = await _client
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    final authorIds = <String>{
      userId,
      for (final follow in follows)
        (follow['following_id'] as Object).toString(),
    }.toList();

    final rows = await _client
        .from('stories')
        .select(
          'id,author_id,type,content,image_url,bg_color,text_color,font_size,'
          'expires_at,view_count,created_at,visibility,allow_replies,allowed_user_ids',
        )
        .inFilter('author_id', authorIds)
        .gt('expires_at', DateTime.now().toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(30);

    final stories = List<Map<String, dynamic>>.from(rows);
    if (stories.isEmpty) return stories;

    final profiles = await _profilesFor(
      stories.map((story) => story['author_id'].toString()).toSet().toList(),
    );
    final storyIds = stories.map((story) => story['id'].toString()).toList();
    final views = await _client
        .from('story_views')
        .select('story_id')
        .eq('viewer_id', userId)
        .inFilter('story_id', storyIds);
    final viewedIds = views.map((view) => view['story_id'].toString()).toSet();

    for (final story in stories) {
      story['profile'] = profiles[story['author_id'].toString()];
      story['viewed'] = viewedIds.contains(story['id'].toString());
    }
    stories.sort((a, b) {
      final viewedOrder = (a['viewed'] == true ? 0 : 1).compareTo(b['viewed'] == true ? 0 : 1);
      if (viewedOrder != 0) return viewedOrder;
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    return stories;
  }

  Future<void> markStoryViewed(String storyId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;
    await _client.from('story_views').upsert(
      {'story_id': storyId, 'viewer_id': userId},
      onConflict: 'story_id,viewer_id',
      ignoreDuplicates: true,
    );
  }

  Future<List<Map<String, dynamic>>> getCommunityQuestions() async {
    final rows = await _client
        .from('questions')
        .select(
          'id,author_id,title,body,city,district,category_id,status,created_at,'
          'view_count,is_emergency,urgency_level,category,is_tool_sharing,item_type',
        )
        .or('status.is.null,status.neq.deleted')
        .order('is_emergency', ascending: false)
        .order('created_at', ascending: false)
        .limit(20);
    return _enrichQuestions(List<Map<String, dynamic>>.from(rows));
  }

  Future<List<Map<String, dynamic>>> getNearbyRequests(String? city) async {
    var query = _client
        .from('requests')
        .select(
          'id,requester_id,title,description,request_type,city,district,budget,'
          'status,created_at,scheduled_for,expires_at,is_urgent,views_count',
        )
        .eq('status', 'open')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String());
    if (city != null && city.isNotEmpty) query = query.eq('city', city);
    final rows = await query
        .order('is_urgent', ascending: false)
        .order('created_at', ascending: false)
        .limit(10);
    final requests = List<Map<String, dynamic>>.from(rows);
    final profiles = await _profilesFor(
      requests.map((row) => row['requester_id'].toString()).toSet().toList(),
    );
    for (final request in requests) {
      request['profile'] = profiles[request['requester_id'].toString()];
    }
    return requests;
  }

  Future<List<Map<String, dynamic>>> getServices(String? city) async {
    if (city == null || city.isEmpty) return [];
    final rows = await _client
        .from('services')
        .select(
          'id,provider_id,category_id,name,description,city,district,price_from,'
          'price_to,is_verified,created_at,whatsapp,available_now,listing_type,'
          'subcategory,images,cover_url,delivery_modes,details,shop_name,'
          'working_hours,price_type,category',
        )
        .eq('city', city)
        .order('available_now', ascending: false)
        .order('is_verified', ascending: false)
        .order('created_at', ascending: false)
        .limit(12);
    final services = List<Map<String, dynamic>>.from(rows);
    final profiles = await _profilesFor(
      services.map((row) => row['provider_id'].toString()).toSet().toList(),
    );
    for (final service in services) {
      service['profile'] = profiles[service['provider_id'].toString()];
    }
    return services;
  }

  Future<List<Map<String, dynamic>>> getBusinesses(String? city) async {
    if (city == null || city.isEmpty) return [];
    final rows = await _client
        .from('businesses')
        .select(
          'id,owner_id,name,description,category_id,city,district,address,'
          'is_open_now,is_verified,created_at,website,whatsapp,logo_url,cover_url',
        )
        .eq('city', city)
        .order('is_open_now', ascending: false)
        .order('is_verified', ascending: false)
        .order('created_at', ascending: false)
        .limit(10);
    final businesses = List<Map<String, dynamic>>.from(rows);
    final categoryIds = businesses
        .map((row) => row['category_id'])
        .whereType<Object>()
        .map((id) => id.toString())
        .toSet()
        .toList();
    if (categoryIds.isNotEmpty) {
      final categories = await _client
          .from('categories')
          .select('id,name')
          .inFilter('id', categoryIds);
      final names = {for (final row in categories) row['id'].toString(): row['name']};
      for (final business in businesses) {
        business['category_name'] = names[business['category_id']?.toString()];
      }
    }
    return businesses;
  }

  Future<List<Map<String, dynamic>>> getUnansweredQuestions() async {
    final rows = await _client
        .from('questions')
        .select(
          'id,author_id,title,body,created_at,is_emergency,urgency_level,view_count',
        )
        .or('status.is.null,status.neq.deleted')
        .order('created_at', ascending: false)
        .limit(30);
    final questions = List<Map<String, dynamic>>.from(rows);
    if (questions.isEmpty) return questions;

    final answers = await _client
        .from('answers')
        .select('question_id')
        .inFilter('question_id', questions.map((row) => row['id']).toList());
    final counts = <String, int>{};
    for (final answer in answers) {
      final id = answer['question_id'].toString();
      counts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
    final profiles = await _profilesFor(
      questions.map((row) => row['author_id'].toString()).toSet().toList(),
    );
    for (final question in questions) {
      question['answers_count'] = counts[question['id'].toString()] ?? 0;
      question['profile'] = profiles[question['author_id'].toString()];
    }
    questions.sort((a, b) {
      final answerOrder = (a['answers_count'] as int).compareTo(b['answers_count'] as int);
      if (answerOrder != 0) return answerOrder;
      return (b['created_at'] as String).compareTo(a['created_at'] as String);
    });
    return questions.take(10).toList();
  }

  Future<List<Map<String, dynamic>>> getEvents(String? city) async {
    if (city == null || city.isEmpty) return [];
    final rows = await _client
        .from('events')
        .select(
          'id,organizer_id,title,description,city,district,starts_at,ends_at,'
          'location_name,cover_url,status,created_at',
        )
        .eq('city', city)
        .eq('status', 'published')
        .gte('starts_at', DateTime.now().toUtc().toIso8601String())
        .order('starts_at')
        .limit(8);
    final events = List<Map<String, dynamic>>.from(rows);
    final profiles = await _profilesFor(
      events.map((row) => row['organizer_id'].toString()).toSet().toList(),
    );
    for (final event in events) {
      event['profile'] = profiles[event['organizer_id'].toString()];
    }
    return events;
  }

  Future<List<Map<String, dynamic>>> _enrichQuestions(
    List<Map<String, dynamic>> questions,
  ) async {
    if (questions.isEmpty) return questions;
    final profiles = await _profilesFor(
      questions.map((row) => row['author_id'].toString()).toSet().toList(),
    );
    final categoryIds = questions
        .map((row) => row['category_id'])
        .whereType<Object>()
        .map((id) => id.toString())
        .toSet()
        .toList();
    final categories = categoryIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _client.from('categories').select('id,name').inFilter('id', categoryIds);
    final categoryNames = {
      for (final row in categories) row['id'].toString(): row['name'],
    };
    final answerRows = await _client
        .from('answers')
        .select('question_id')
        .inFilter('question_id', questions.map((row) => row['id']).toList());
    final answerCounts = <String, int>{};
    for (final answer in answerRows) {
      final id = answer['question_id'].toString();
      answerCounts.update(id, (count) => count + 1, ifAbsent: () => 1);
    }
    for (final question in questions) {
      question['profile'] = profiles[question['author_id'].toString()];
      question['category_name'] = categoryNames[question['category_id']?.toString()];
      question['answers_count'] = answerCounts[question['id'].toString()] ?? 0;
    }
    return questions;
  }

  Future<Map<String, Map<String, dynamic>>> _profilesFor(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await _client
        .from('profiles')
        .select('id,display_name,username,avatar_url,is_verified,city,district')
        .inFilter('id', ids);
    return {
      for (final row in rows) row['id'].toString(): Map<String, dynamic>.from(row),
    };
  }
}