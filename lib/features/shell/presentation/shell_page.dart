import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../home/presentation/home_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  static const pages = [
    ('الرئيسية', LucideIcons.house),
    ('المجتمع', LucideIcons.users),
    ('السوق', LucideIcons.store),
    ('الرسائل', LucideIcons.messageCircle),
    ('حسابي', LucideIcons.userCircle),
  ];

  @override
  Widget build(BuildContext context) {
    final current = pages[index];
    final bodies = [
      const HomePage(),
      const _PlaceholderPage(title: 'المجتمع', icon: LucideIcons.users),
      const _PlaceholderPage(title: 'السوق', icon: LucideIcons.store),
      const _PlaceholderPage(title: 'الرسائل', icon: LucideIcons.messageCircle),
      const _PlaceholderPage(title: 'حسابي', icon: LucideIcons.userCircle),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(current.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell)),
          const SizedBox(width: 8),
        ],
      ),
      body: bodies[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          for (final page in pages)
            NavigationDestination(icon: Icon(page.$2), label: page.$1),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('هذه الواجهة قيد البناء في V2'),
      ]),
    );
  }
}
