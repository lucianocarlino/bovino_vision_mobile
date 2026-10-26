import 'package:flutter/material.dart';

import '../../../../core/data/herd_models.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/api_image.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/page_header.dart';
import '../capture_flow_controller.dart';
import '../capture_summary.dart';

/// Step 4: the estimated weight with its data sheet, or the reason the estimation failed.
class ResultStep extends StatelessWidget {
  const ResultStep({
    super.key,
    required this.result,
    required this.animal,
    required this.loading,
    required this.online,
    required this.error,
    required this.onConfirm,
    required this.onNextAnimal,
    required this.onAnotherPhoto,
  });

  final CaptureResult result;

  /// The weighed animal, for the breed, sex and age that the weighing itself does not carry.
  final Animal? animal;
  final bool loading;
  final bool online;
  final String? error;
  final VoidCallback onConfirm;

  /// "Tomar otra": leaves the animal and starts the next capture of the session.
  final VoidCallback onNextAnimal;

  /// "Tomar otra foto": back to the photo step of the same animal.
  final VoidCallback onAnotherPhoto;

  @override
  Widget build(BuildContext context) {
    final weighing = result.weighing;
    if (weighing == null) return _Failed(result: result, onNextAnimal: onNextAnimal);

    final confirmed = result.capture.isConfirmed;
    final now = DateTime.now();
    final decimals = weighing.weightKg == weighing.weightKg.roundToDouble() ? 0 : 1;
    final alert = weighing.alert;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Resultado del pesaje',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.neutral800),
              ),
            ),
            AppBadge(label: confirmed ? 'Confirmado' : 'Listo', tone: BadgeTone.brand),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: AppColors.green900,
              child: ApiImage(imageId: weighing.imageId),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'PESO ESTIMADO',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.1, color: AppColors.green600),
        ),
        Text.rich(
          TextSpan(
            style: const TextStyle(color: AppColors.neutral800),
            children: [
              TextSpan(
                text: formatNumber(weighing.weightKg, decimals),
                style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w700, letterSpacing: -1.5, height: 1.1),
              ),
              const TextSpan(
                text: ' kg',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.neutral500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.neutral200)),
          ),
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              for (final row in resultSheet(weighing, animal, now))
                InfoRow(
                  label: row.label,
                  value: row.value,
                  valueColor: switch (row.tone) {
                    RowTone.positive => AppColors.green600,
                    RowTone.negative => AppColors.dangerText,
                    null => null,
                  },
                ),
            ],
          ),
        ),
        if (weighing.previous == null) ...[
          const SizedBox(height: 16),
          const Notice(message: 'Es el primer pesaje de este animal: todavía no hay un peso anterior para comparar.'),
        ],
        if (alert != null) ...[
          const SizedBox(height: 16),
          Notice(message: describeAlert(alert), tone: NoticeTone.danger),
        ],
        const SizedBox(height: 24),
        if (confirmed)
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 20, color: AppColors.green600),
              SizedBox(width: 8),
              Text(
                'Resultado confirmado',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.green600),
              ),
            ],
          )
        else
          AppButton(
            label: 'Confirmar y enviar',
            icon: Icons.send_outlined,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: loading || !online ? null : onConfirm,
          ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Tomar otra',
          icon: Icons.photo_camera_outlined,
          variant: AppButtonVariant.secondary,
          size: AppButtonSize.lg,
          expand: true,
          onPressed: loading ? null : onNextAnimal,
        ),
        if (error != null) ...[const SizedBox(height: 12), Notice(message: error!, tone: NoticeTone.danger)],
        const SizedBox(height: 12),
        const Notice(
          message: 'La medición ya está guardada en el historial del animal. Confirmarla solo registra tu revisión.',
          tone: NoticeTone.success,
        ),
        if (!confirmed) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'Tomar otra foto',
            icon: Icons.restart_alt,
            variant: AppButtonVariant.ghost,
            expand: true,
            onPressed: loading ? null : onAnotherPhoto,
          ),
        ],
      ],
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.result, required this.onNextAnimal});

  final CaptureResult result;
  final VoidCallback onNextAnimal;

  @override
  Widget build(BuildContext context) {
    final reason = result.capture.failureReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Notice(
          title: 'No se pudo estimar el peso',
          message: [
            if (reason != null && reason.isNotEmpty) reason,
            'Registrá una nueva captura para volver a intentarlo.',
          ].join('\n'),
          tone: NoticeTone.danger,
        ),
        const SizedBox(height: 24),
        AppButton(label: 'Pesar otro animal', size: AppButtonSize.lg, expand: true, onPressed: onNextAnimal),
      ],
    );
  }
}
