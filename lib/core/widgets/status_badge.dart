import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
  });

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final normalizedStatus = status
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ');

    Color foreground;
    Color background;

    switch (normalizedStatus) {
      case 'registered':
        foreground = isDark ? AppColors.darkWarning : AppColors.warning;
        background = isDark
            ? const Color(0xFF3B301D)
            : const Color(0xFFFFF3D6);

      case 'checked in':
        foreground = isDark ? AppColors.darkSuccess : AppColors.success;
        background = isDark
            ? const Color(0xFF17382D)
            : const Color(0xFFE5F5EC);

      default:
        foreground = colors.onSurfaceVariant;
        background = colors.surfaceContainerHighest;
    }

    final label = normalizedStatus.isEmpty
        ? 'Unknown'
        : normalizedStatus
        .split(' ')
        .map(
          (word) => word.isEmpty
          ? word
          : '${word[0].toUpperCase()}${word.substring(1)}',
    )
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}