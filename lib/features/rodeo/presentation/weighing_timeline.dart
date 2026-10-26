import 'package:flutter/material.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_image.dart';
import '../../../core/widgets/app_badge.dart';
import '../data/rodeo_api.dart';
import '../domain/rodeo_logic.dart';

const _dateColumn = 72.0;
const _columnGap = 16.0;
const _contentIndent = 24.0;

/// Vertical timeline of weighings, newest first (`LineaDePesajes.tsx`): date on the left,
/// weight, difference vs. the previous one, GMD, operator and lot on the right.
class WeighingTimeline extends StatelessWidget {
  const WeighingTimeline({super.key, required this.weighings});

  final List<Weighing> weighings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < weighings.length; index++)
          _Entry(
            weighing: weighings[index],
            // Newest first: the previous weighing is the next item.
            previous: index + 1 < weighings.length ? weighings[index + 1] : null,
            isLast: index == weighings.length - 1,
          ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.weighing, required this.previous, required this.isLast});

  final Weighing weighing;
  final Weighing? previous;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final difference = weightDifference(weighing.weightKg, previous?.weightKg);
    final gmd = weighing.gmdKgPerDay;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _dateColumn,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatShortDate(weighing.weighedAt),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                ),
                Text(
                  formatTime(weighing.weighedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: _columnGap),
        Expanded(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (!isLast)
                const Positioned(left: -0.5, top: 12, bottom: 0, width: 1, child: ColoredBox(color: AppColors.green200)),
              Positioned(
                left: -5,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.green500,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.green100, spreadRadius: 4)],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: _contentIndent, bottom: isLast ? 0 : 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                formatKg(weighing.weightKg, 1),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral800),
                              ),
                              if (difference != null)
                                Text(
                                  difference.text,
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _toneColor(difference.tone)),
                                ),
                              if (gmd != null)
                                AppBadge(
                                  label: 'GMD ${formatGmd(gmd)}',
                                  tone: gmd >= 0 ? BadgeTone.brand : BadgeTone.danger,
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dateOperatorLine(weighing.weighedAt, weighing.operatorName),
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
                          ),
                          Text(
                            weighing.lotCode != null ? 'Lote ${weighing.lotCode}' : 'Sin lote',
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 56,
                        height: 56,
                        child: ColoredBox(color: AppColors.green900, child: ApiImage(imageId: weighing.imageId)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _toneColor(DifferenceTone tone) => switch (tone) {
      DifferenceTone.gain => AppColors.success500,
      DifferenceTone.loss => AppColors.danger500,
      DifferenceTone.unchanged => AppColors.neutral500,
    };
