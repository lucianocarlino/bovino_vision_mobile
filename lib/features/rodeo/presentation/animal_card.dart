import 'package:flutter/material.dart';

import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/api_image.dart';
import '../../../core/widgets/app_badge.dart';
import '../domain/rodeo_logic.dart';

/// Herd list item (`TarjetaAnimal.tsx`): photo of the latest weighing with the lot on top,
/// SENASA ID, breed, last weight, GMD (with its share of the lot target) and alerts.
class AnimalCard extends StatelessWidget {
  const AnimalCard({super.key, required this.animal, required this.lot, required this.onTap});

  final Animal animal;

  /// The animal's lot, when known: its target GMD gives the "% del objetivo".
  final Lot? lot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goal = goalFraction(animal.gmdKgPerDay, lot?.gmdTarget);
    final alerts = animal.activeAlerts;
    final radius = BorderRadius.circular(AppRadius.card);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: radius,
        border: Border.all(color: AppColors.neutral200),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Photo(animal: animal),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Caption('ID SENASA'),
                              Text(
                                animal.identifier,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.neutral800),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: AppColors.neutral400),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Datum(
                            label: 'Raza',
                            value: animal.breed ?? 'Sin registrar',
                            color: AppColors.brown600,
                            weight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Datum(
                            label: 'Último peso',
                            value: animal.lastWeightKg != null ? formatKg(animal.lastWeightKg!, 1) : 'Sin pesajes',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Datum(label: 'GMD', value: animal.gmdKgPerDay != null ? formatGmd(animal.gmdKgPerDay!) : '—'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.neutral100),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (alerts > 0)
                          AppBadge(
                            label: alerts == 1 ? '1 alerta activa' : '${formatNumber(alerts)} alertas activas',
                            tone: BadgeTone.danger,
                          )
                        else
                          const AppBadge(label: 'Sin alertas activas', tone: BadgeTone.brand),
                        if (goal != null)
                          Text(
                            '${formatPercent(goal)} del objetivo',
                            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.animal});

  final Animal animal;

  @override
  Widget build(BuildContext context) {
    final imageId = animal.lastWeighingImageId;
    return SizedBox(
      height: 144,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: AppColors.green900),
          if (imageId != null)
            ApiImage(imageId: imageId)
          else
            Center(
              child: Icon(
                Icons.pets,
                size: 40,
                color: AppColors.green300.withValues(alpha: 0.6),
                semanticLabel: 'Sin foto: todavía no se pesó',
              ),
            ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.green900.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                animal.lotCode != null ? 'Lote ${animal.lotCode}' : 'Sin lote',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.neutral400),
      );
}

class _Datum extends StatelessWidget {
  const _Datum({required this.label, required this.value, this.color = AppColors.neutral800, this.weight = FontWeight.w600});

  final String label;
  final String value;
  final Color color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Caption(label),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: weight,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
