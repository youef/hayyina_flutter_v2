import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(current.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(LucideIcons.bell)),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(current.$2, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 20),
            Text('نسخة حيّنا V2', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('نبني تجربة جديدة أسرع وأجمل من الصفر.', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
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
