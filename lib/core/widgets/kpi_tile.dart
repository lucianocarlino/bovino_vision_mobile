import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Dark green KPI tile: big value, uppercase label and an optional detail line.
class KpiTile extends StatelessWidget {
  const KpiTile({super.key, required this.value, required this.label, this.detail, this.danger = false});

  final String value;
  final String label;
  final String? detail;

  /// Uses the danger text color as background, e.g. when there are active alerts.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 95),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: danger ? AppColors.dangerText : AppColors.green800,
        borderRadius: BorderRadius.circular(AppRadius.control),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (detail != null)
            Text(
              detail!,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-column grid of KPI tiles with 12 px gaps, as the web shows them on phones.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 12),
              Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox()),
            ],
          ),
        ),
      );
      if (i + 2 < tiles.length) rows.add(const SizedBox(height: 12));
    }
    return Column(children: rows);
  }
}
