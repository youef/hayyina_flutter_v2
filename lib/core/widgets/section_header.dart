import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Spacer(),
        if (action != null)
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.chevronLeft, size: 16),
            label: Text(action!),
          ),
      ],
    );
  }
}
