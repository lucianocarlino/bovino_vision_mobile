import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Screen title (20 px semibold, tight tracking) with an optional subtitle.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                  color: AppColors.neutral800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: const TextStyle(fontSize: 12, color: AppColors.neutral600)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// "Paso n de N" with one 32×4 segment per step (`src/components/Stepper.tsx`).
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.current, required this.total});

  /// One-based index of the current step.
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            children: [
              const TextSpan(text: 'Paso '),
              TextSpan(text: '$current', style: const TextStyle(fontWeight: FontWeight.w700)),
              const TextSpan(text: ' de '),
              TextSpan(text: '$total', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const Spacer(),
        for (var step = 1; step <= total; step++) ...[
          if (step > 1) const SizedBox(width: 6),
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: step <= current ? AppColors.green500 : AppColors.neutral200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rounded progress track (19 px) with green or brown fill and an optional caption row.
class ProgressBarView extends StatelessWidget {
  const ProgressBarView({super.key, required this.value, this.earth = false, this.label, this.caption});

  /// Fraction between 0 and 1.
  final double value;
  final bool earth;
  final String? label;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 19,
            child: LinearProgressIndicator(
              value: value.clamp(0, 1),
              backgroundColor: AppColors.neutral100,
              color: earth ? AppColors.brown400 : AppColors.green500,
            ),
          ),
        ),
        if (label != null || caption != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral700),
                  ),
                ),
              if (caption != null)
                Text(
                  caption!,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral500),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Label/value row used by data sheets ("Lote", "Operario", …).
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.neutral500))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.neutral800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
