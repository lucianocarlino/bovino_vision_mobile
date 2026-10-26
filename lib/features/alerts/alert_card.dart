import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/data/herd_api.dart';
import '../../core/data/herd_models.dart';
import '../../core/format/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import 'alert_texts.dart';

/// Alert card: type icon, animal, time, description, link to the animal and resolve action.
class AlertCard extends StatefulWidget {
  const AlertCard({super.key, required this.alert, required this.canResolve, required this.onResolved});

  final Alert alert;

  /// Resolving writes to the herd, so the parent passes `rodeo_gestionar`.
  final bool canResolve;

  /// Called once the alert is resolved, so the parent can drop the card.
  final ValueChanged<String> onResolved;

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool _resolving = false;
  String? _error;

  Future<void> _resolve() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      await context.read<HerdApi>().resolveAlert(widget.alert.id);
      widget.onResolved(widget.alert.id);
    } on ApiException catch (error) {
      // 409: someone else already resolved it, so the card has nothing left to show.
      if (error.isConflict) return widget.onResolved(widget.alert.id);
      if (mounted) {
        setState(() {
          _error = error.message;
          _resolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final level = PriorityLevel.of(alert.priority);
    final (iconBackground, iconColor) = AppBadge.colorsFor(level.tone);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: iconBackground, borderRadius: BorderRadius.circular(11)),
                child: Icon(
                  alert.type == AlertType.weightLoss ? Icons.trending_down : Icons.remove,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          alert.animalIdentifier,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                        ),
                        Text(formatAgo(alert.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      describeAlert(alert),
                      style: const TextStyle(fontSize: 12, height: 1.65, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppBadge(label: level.label, tone: level.tone),
            ],
          ),
          const SizedBox(height: 8),
          // Wraps instead of overflowing on narrow phones or with large system fonts.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () => context.go(AppRoutes.animal(alert.animalId)),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right, size: 18),
                label: const Text('Ver ficha'),
                style: TextButton.styleFrom(foregroundColor: AppColors.neutral500, minimumSize: const Size(0, 44)),
              ),
              if (widget.canResolve)
                AppButton(
                  label: _resolving ? 'Resolviendo…' : 'Resolver',
                  icon: Icons.check,
                  variant: AppButtonVariant.secondary,
                  onPressed: _resolving ? null : _resolve,
                ),
            ],
          ),
          if (_error != null)
            Text(
              'No pudimos resolver la alerta. $_error',
              style: const TextStyle(fontSize: 12, color: AppColors.dangerText),
            ),
        ],
      ),
    );
  }
}
