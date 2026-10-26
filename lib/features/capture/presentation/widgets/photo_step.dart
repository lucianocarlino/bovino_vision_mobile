import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/data/herd_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feedback.dart';
import '../../data/capture_models.dart';
import '../../data/photo_picker.dart';
import 'step_title.dart';

/// Step 2: take or pick the photo, then send it to estimation or remove it.
class PhotoStep extends StatelessWidget {
  const PhotoStep({
    super.key,
    required this.animal,
    required this.capture,
    required this.preview,
    required this.loading,
    required this.removing,
    required this.online,
    required this.notice,
    required this.error,
    required this.onPick,
    required this.onRetry,
    required this.onRemove,
    required this.onProcess,
  });

  final Animal animal;
  final Capture? capture;
  final Uint8List? preview;
  final bool loading;
  final bool removing;
  final bool online;
  final String? notice;
  final String? error;
  final ValueChanged<PhotoSource> onPick;
  final VoidCallback onRetry;
  final VoidCallback onRemove;
  final VoidCallback onProcess;

  @override
  Widget build(BuildContext context) {
    final registered = capture != null;
    final canPick = online && !loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(lead: 'Foto del ', emphasis: 'animal'),
        const SizedBox(height: 4),
        TagLine(identifier: animal.identifier),
        const SizedBox(height: 20),
        _Frame(preview: preview),
        if (preview == null) ...[
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Alineá el animal de perfil con la guía',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.neutral800),
            ),
          ),
          const Center(
            child: Text(
              'Cuatro tomas dan la mejor estimación',
              style: TextStyle(fontSize: 14, color: AppColors.neutral500),
            ),
          ),
        ],
        if (!registered) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Usar cámara',
                  icon: Icons.photo_camera_outlined,
                  size: AppButtonSize.lg,
                  expand: true,
                  onPressed: canPick ? () => onPick(PhotoSource.camera) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Galería',
                  icon: Icons.add_photo_alternate_outlined,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.lg,
                  expand: true,
                  onPressed: canPick ? () => onPick(PhotoSource.gallery) : null,
                ),
              ),
            ],
          ),
        ],
        if (notice != null && !registered) ...[const SizedBox(height: 16), Notice(message: notice!)],
        if (loading) LoadingView(label: removing ? 'Quitando foto…' : 'Subiendo foto…'),
        if (error != null && registered) ...[
          const SizedBox(height: 16),
          Notice(message: error!, tone: NoticeTone.danger),
        ],
        if (error != null && !registered) ...[
          const SizedBox(height: 16),
          Notice(message: 'No se pudo registrar la foto: $error', tone: NoticeTone.warning),
          const SizedBox(height: 12),
          AppButton(
            label: 'Sacar otra foto',
            icon: Icons.refresh,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: onRetry,
          ),
        ],
        if (registered) ...[
          const SizedBox(height: 20),
          const Notice(message: 'Foto cargada. Lista para estimar el peso.', tone: NoticeTone.success),
          const SizedBox(height: 12),
          AppButton(
            label: 'Procesar pesaje',
            icon: Icons.arrow_forward,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: canPick ? onProcess : null,
          ),
          const SizedBox(height: 12),
          AppButton(
            label: 'Quitar foto',
            icon: Icons.delete_outline,
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.lg,
            expand: true,
            onPressed: loading ? null : onRemove,
          ),
        ],
      ],
    );
  }
}

/// 4:5 framing guide (corner marks, dashed silhouette and the three shot conditions),
/// or the photo just taken.
class _Frame extends StatelessWidget {
  const _Frame({required this.preview});

  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: AspectRatio(
          aspectRatio: 4 / 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: ColoredBox(
              color: AppColors.green900,
              child: preview == null
                  ? const _Guide()
                  : Image.memory(preview!, fit: BoxFit.cover, semanticLabel: 'Vista previa de la captura'),
            ),
          ),
        ),
      ),
    );
  }
}

class _Guide extends StatelessWidget {
  const _Guide();

  static const _indicators = [
    (text: 'Luz correcta', icon: Icons.wb_sunny_outlined, color: AppColors.green300),
    (text: 'Acercate 1 m', icon: Icons.straighten, color: AppColors.warning500),
    (text: 'Encuadre', icon: Icons.crop_free, color: AppColors.green300),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(left: 20, top: 20, child: _Corner(top: true, left: true)),
        const Positioned(right: 20, top: 20, child: _Corner(top: true, left: false)),
        const Positioned(left: 20, bottom: 20, child: _Corner(top: false, left: true)),
        const Positioned(right: 20, bottom: 20, child: _Corner(top: false, left: false)),
        Align(
          alignment: const Alignment(0, 0.04),
          child: FractionallySizedBox(
            widthFactor: 0.64,
            heightFactor: 0.44,
            child: CustomPaint(painter: _DashedOutlinePainter()),
          ),
        ),
        Positioned(
          top: 24,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green900.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.green300.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'ESPERANDO ANIMAL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                  color: AppColors.green300,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: Row(
            children: [
              for (final (index, indicator) in _indicators.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.green900.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(indicator.icon, size: 16, color: indicator.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            indicator.text,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  const _Corner({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: AppColors.green300, width: 4);
    const radius = Radius.circular(8);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? radius : Radius.zero,
          topRight: top && !left ? radius : Radius.zero,
          bottomLeft: !top && left ? radius : Radius.zero,
          bottomRight: !top && !left ? radius : Radius.zero,
        ),
      ),
    );
  }
}

class _DashedOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green300.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: const Radius.circular(120),
          topRight: const Radius.circular(90),
          bottomLeft: const Radius.circular(60),
          bottomRight: const Radius.circular(60),
        ),
      );
    for (final metric in outline.computeMetrics()) {
      for (var distance = 0.0; distance < metric.length; distance += 12) {
        canvas.drawPath(metric.extractPath(distance, distance + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
