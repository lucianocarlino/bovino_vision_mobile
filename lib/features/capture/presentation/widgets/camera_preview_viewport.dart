import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Visor visual para la captura de la cámara biométrica.
/// Muestra un placeholder de alta fidelidad estética sin indicadores en tiempo real
/// según las reglas de negocio ERS (omitidos: "Luz correcta", "Acercate 1 m", "Encuadre").
class CameraPreviewViewport extends StatelessWidget {
  final VoidCallback? onDoubleTapFocus;

  const CameraPreviewViewport({
    super.key,
    this.onDoubleTapFocus,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF101411), // Contenedor oscuro estético
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Fondo de textura sutil simulando sensor de cámara
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Visor Biométrico Bovino',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alinee el perfil completo del animal',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Guías visuales de esquina fotográficas (Corner Brackets)
              const Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: _CameraCornerBrackets(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dibuja sutiles marcas de encuadre en las cuatro esquinas del visor
class _CameraCornerBrackets extends StatelessWidget {
  const _CameraCornerBrackets();

  @override
  Widget build(BuildContext context) {
    final bracketColor = AppColors.primaryLight.withValues(alpha: 0.7);
    const bracketSize = 22.0;
    const bracketThickness = 2.5;

    return Stack(
      children: [
        // Esquina superior izquierda
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: bracketColor, width: bracketThickness),
                left: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Esquina superior derecha
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: bracketColor, width: bracketThickness),
                right: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Esquina inferior izquierda
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: bracketColor, width: bracketThickness),
                left: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
        // Esquina inferior derecha
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: bracketSize,
            height: bracketSize,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: bracketColor, width: bracketThickness),
                right: BorderSide(color: bracketColor, width: bracketThickness),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
