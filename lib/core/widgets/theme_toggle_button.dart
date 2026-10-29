import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:visitor_management_app/core/providers/providers.dart';

class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Change appearance',
      initialValue: themeMode,
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      icon: Icon(
        isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      ),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ThemeMode.light,
          child: Text('Light mode'),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: Text('Dark mode'),
        ),
        PopupMenuItem(
          value: ThemeMode.system,
          child: Text('Use device setting'),
        ),
      ],
    );
  }
}