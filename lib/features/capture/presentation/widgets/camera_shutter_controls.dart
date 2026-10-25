import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Barra de controles inferiores de captura:
/// Botón de galería (secundario), Botón disparador de obturador y Botón de alternar flash/cámara.
class CameraShutterControls extends StatelessWidget {
  final VoidCallback onCapturePressed;
  final VoidCallback onGalleryPressed;
  final VoidCallback onSecondaryControlPressed;
  final bool isCaptureDisabled;

  const CameraShutterControls({
    super.key,
    required this.onCapturePressed,
    required this.onGalleryPressed,
    required this.onSecondaryControlPressed,
    this.isCaptureDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Botón Galería / Álbum
          _ControlButton(
            icon: Icons.photo_library_outlined,
            tooltip: 'Galería de fotos',
            onPressed: onGalleryPressed,
          ),

          // Botón Principal de Obturador (Shutter)
          GestureDetector(
            onTap: onCapturePressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(
                  color: isCaptureDisabled
                      ? AppColors.textMuted.withValues(alpha: 0.4)
                      : AppColors.primary,
                  width: 4,
                ),
                boxShadow: isCaptureDisabled
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCaptureDisabled
                        ? AppColors.textMuted
                        : AppColors.primary,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Botón Secundario (Cambiar cámara / opciones)
          _ControlButton(
            icon: Icons.flip_camera_ios_outlined,
            tooltip: 'Alternar cámara',
            onPressed: onSecondaryControlPressed,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.textPrimary, size: 24),
        onPressed: onPressed,
      ),
    );
  }
}
