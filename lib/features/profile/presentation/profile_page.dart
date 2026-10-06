import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/supabase/supabase_client.dart';
import '../data/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final repo = ProfileRepository();
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      await repo.ensureProfile();
      profile = await repo.getCurrentProfile();
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> logout() async {
    await repo.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;
    final name = profile?['full_name']?.toString().trim().isNotEmpty == true
        ? profile!['full_name'].toString()
        : user?.userMetadata?['full_name']?.toString() ?? 'مستخدم حيّنا';
    final email = profile?['email']?.toString() ?? user?.email ?? '';

    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          Center(child: CircleAvatar(
            radius: 42,
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            child: Icon(LucideIcons.userRound, size: 38, color: Theme.of(context).colorScheme.primary),
          )),
          const SizedBox(height: 14),
          Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900))),
          const SizedBox(height: 5),
          Center(child: Text(email, style: const TextStyle(color: Color(0xFF64748B)))),
          const SizedBox(height: 28),
          _Item(icon: LucideIcons.userRound, title: 'الملف الشخصي', onTap: () {}),
          _Item(icon: LucideIcons.bell, title: 'الإشعارات', onTap: () {}),
          _Item(icon: LucideIcons.mapPin, title: 'الحي والموقع', onTap: () {}),
          _Item(icon: LucideIcons.settings, title: 'الإعدادات', onTap: () {}),
          const SizedBox(height: 12),
          _Item(icon: LucideIcons.logOut, title: 'تسجيل الخروج', danger: true, onTap: logout),
          if (loading) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.title, required this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: danger ? Colors.red : Theme.of(context).colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: danger ? Colors.red : null)),
      trailing: const Icon(LucideIcons.chevronLeft, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
