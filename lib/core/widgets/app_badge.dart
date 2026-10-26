import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum BadgeTone { brand, neutral, success, danger, warning, info, earth }

/// Pill badge (full radius, 12 px medium text) with the web app's tones.
class AppBadge extends StatelessWidget {
  const AppBadge({super.key, required this.label, this.tone = BadgeTone.neutral, this.icon});

  final String label;
  final BadgeTone tone;
  final IconData? icon;

  static (Color background, Color foreground) colorsFor(BadgeTone tone) => switch (tone) {
        BadgeTone.brand => (AppColors.green100, AppColors.green600),
        BadgeTone.neutral => (AppColors.neutral100, AppColors.neutral600),
        BadgeTone.success => (AppColors.successBg, AppColors.successText),
        BadgeTone.danger => (AppColors.dangerBg, AppColors.dangerText),
        BadgeTone.warning => (AppColors.warningBg, AppColors.warningText),
        BadgeTone.info => (AppColors.infoBg, AppColors.infoText),
        BadgeTone.earth => (AppColors.brown100, AppColors.brown600),
      };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = colorsFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selectable filter chip: min height 36, full radius, green-800 fill when active.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.green800 : AppColors.white,
      shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.green800 : AppColors.neutral300)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.neutral700,
            ),
          ),
        ),
      ),
    );
  }
}
