import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../capture/presentation/screens/estimation_status_screen.dart';
import '../../data/home_mock_data.dart';

/// Lista de sesiones recientes combinadas (sincronizadas en la nube y pendientes locales).
/// Muestra únicamente el día, la hora y la cantidad de animales procesados.
class RecentSessionsList extends StatelessWidget {
  final List<RecentSessionModel> sessions;
  final ValueChanged<RecentSessionModel>? onSessionTap;

  const RecentSessionsList({
    super.key,
    required this.sessions,
    this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de la sección
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Sesiones Recientes',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '${sessions.length} registradas',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de sesiones
        if (sessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No hay sesiones de captura registradas hoy.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final session = sessions[index];
              return _RecentSessionCard(
                session: session,
                onTap: () {
                  if (onSessionTap != null) {
                    onSessionTap!(session);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EstimationStatusScreen.fromSession(
                          session: session,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          ),
      ],
    );
  }
}

class _RecentSessionCard extends StatelessWidget {
  final RecentSessionModel session;
  final VoidCallback? onTap;

  const _RecentSessionCard({
    required this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = session.isPending;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? AppColors.syncPending.withValues(alpha: 0.5)
              : AppColors.border,
          width: isPending ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending
                ? AppColors.syncPending.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EstimationStatusScreen.fromSession(
                      session: session,
                    ),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icono temático: Reloj naranja para pendiente vs Checklist verde para sincronizado
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isPending
                        ? AppColors.offlineLight
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: isPending
                        ? Border.all(
                            color: AppColors.syncPending.withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: Icon(
                    isPending
                        ? Icons.access_time_rounded
                        : Icons.assignment_turned_in_rounded,
                    color: isPending ? AppColors.syncPending : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Información principal: Solo día, hora y cantidad de animales
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${session.displayDay}, ${session.displayTime}',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Etiqueta destacada "Pendiente"
                          if (isPending) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.offlineLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.syncPending
                                      .withValues(alpha: 0.4),
                                  width: 0.8,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 11,
                                    color: AppColors.syncPending,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    'Pendiente',
                                    style: TextStyle(
                                      color: AppColors.syncPending,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.pets_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${session.animalsProcessed} animales',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
