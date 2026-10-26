import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';

enum NoticeTone { neutral, success, warning, danger }

/// Inline notice with a leading icon (`src/components/Feedback.tsx`).
class Notice extends StatelessWidget {
  const Notice({super.key, required this.message, this.tone = NoticeTone.neutral, this.title});

  final String message;
  final NoticeTone tone;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      NoticeTone.neutral => (AppColors.neutral100, AppColors.neutral700, Icons.info_outline),
      NoticeTone.success => (AppColors.successBg, AppColors.successText, Icons.check_circle_outline),
      NoticeTone.warning => (AppColors.warningBg, AppColors.warningText, Icons.warning_amber_rounded),
      NoticeTone.danger => (AppColors.dangerBg, AppColors.dangerText, Icons.error_outline),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.control)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground)),
                Text(message, style: TextStyle(fontSize: 12, height: 1.65, color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Spinner with "Cargando…".
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Cargando…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.green600),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.neutral600)),
        ],
      ),
    );
  }
}

/// Dashed placeholder for lists without items.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: AppColors.green100, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: AppColors.green700),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
            ),
            if (message != null) ...[
              const SizedBox(height: 4),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Danger notice with a "Reintentar" button, for failed loads.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Notice(message: message, tone: NoticeTone.danger),
        const SizedBox(height: 12),
        AppButton(
          label: 'Reintentar',
          icon: Icons.refresh,
          variant: AppButtonVariant.secondary,
          onPressed: onRetry,
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neutral300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.card)));
    for (final metric in path.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 9) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
