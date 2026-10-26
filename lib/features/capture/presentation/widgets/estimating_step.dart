import 'package:flutter/material.dart';

import '../../../../core/data/herd_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feedback.dart';
import '../../data/capture_models.dart';
import '../capture_summary.dart';
import 'step_title.dart';

/// Step 3: checklist of the estimation, driven by the polled capture state.
class EstimatingStep extends StatelessWidget {
  const EstimatingStep({
    super.key,
    required this.animal,
    required this.capture,
    required this.error,
    required this.onRetry,
  });

  final Animal animal;
  final Capture? capture;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final lastFailure = capture?.failureReason;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TagLine(identifier: animal.identifier),
        const SizedBox(height: 16),
        const Text(
          'Estimando peso…',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.neutral800),
        ),
        const SizedBox(height: 4),
        const Text('No cierres la aplicación.', style: TextStyle(fontSize: 14, color: AppColors.neutral500)),
        const SizedBox(height: 24),
        for (final step in estimationSteps(capture)) ...[_StepRow(step: step), const SizedBox(height: 12)],
        if (lastFailure != null && lastFailure.isNotEmpty) ...[
          const SizedBox(height: 12),
          Notice(message: 'Último intento: $lastFailure. Se reintenta automáticamente.', tone: NoticeTone.warning),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          Notice(message: 'No se pudo consultar el estado: $error', tone: NoticeTone.danger),
          const SizedBox(height: 12),
          AppButton(
            label: 'Volver a consultar',
            icon: Icons.refresh,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: onRetry,
          ),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final EstimationStep step;

  @override
  Widget build(BuildContext context) {
    final icon = switch (step.state) {
      EstimationState.done => const Icon(Icons.check_circle_outline, size: 20, color: AppColors.green500),
      EstimationState.current => const SizedBox(
        width: 20,
        height: 20,
        child: Padding(
          padding: EdgeInsets.all(2),
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green500),
        ),
      ),
      EstimationState.pending => const Icon(Icons.circle_outlined, size: 20, color: AppColors.neutral300),
    };
    return Row(
      children: [
        icon,
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            step.text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: step.state == EstimationState.current ? FontWeight.w600 : FontWeight.w400,
              color: step.state == EstimationState.pending ? AppColors.neutral400 : AppColors.neutral800,
            ),
          ),
        ),
      ],
    );
  }
}
