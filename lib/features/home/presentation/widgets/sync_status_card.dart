import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_mock_data.dart';

/// Tarjeta dinámica de estado de sincronización offline-first.
/// Alterna visualmente entre estado exitoso (verde) y alerta de registros pendientes (naranja).
class SyncStatusCard extends StatelessWidget {
  final SyncStatusModel syncStatus;
  final VoidCallback? onSyncPressed;

  const SyncStatusCard({
    super.key,
    required this.syncStatus,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSynced = syncStatus.isSynced;
    final isSyncing = syncStatus.isSyncing;

    // Colores según estado: Exitoso (Verde agro) vs Pendiente/Alerta (Naranja rural)
    final primaryColor = isSynced ? AppColors.syncSuccess : AppColors.syncPending;
    final backgroundColor = isSynced
        ? const Color(0xFFEFF8F1)
        : AppColors.offlineLight; // Fondo naranja de alerta
    final borderColor = isSynced
        ? const Color(0xFFC8E6C9)
        : AppColors.syncPending.withValues(alpha: 0.45);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.3),
        boxShadow: [
          BoxShadow(
            color: (isSynced ? AppColors.primary : AppColors.syncPending)
                .withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono indicador de estado offline-first
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: isSyncing
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : Icon(
                    isSynced
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_upload_outlined,
                    color: primaryColor,
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),

          // Título y Mensaje del estado de sincronización
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        syncStatus.title,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isSynced
                          ? Icons.check_circle_rounded
                          : (isSyncing ? Icons.sync_rounded : Icons.warning_amber_rounded),
                      size: 16,
                      color: primaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  syncStatus.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Botón de sincronización manual / estado de carga
          if (isSyncing)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Subiendo...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            )
          else
            IconButton(
              onPressed: onSyncPressed,
              icon: Icon(
                Icons.sync_rounded,
                color: primaryColor,
                size: 22,
              ),
              tooltip: isSynced ? 'Verificar servidor' : 'Sincronizar ahora',
            ),
        ],
      ),
    );
  }
}
