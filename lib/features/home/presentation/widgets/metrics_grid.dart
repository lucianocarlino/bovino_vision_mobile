import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/home_mock_data.dart';

class MetricsGrid extends StatelessWidget {
  final MetricsModel metrics;

  const MetricsGrid({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern('es_AR');

    return Row(
      children: [
        // Métrica: Total Rodeo
        Expanded(
          child: _MetricCard(
            label: 'Total Rodeo',
            value: numberFormat.format(metrics.totalRodeo),
            icon: Icons.pets_rounded,
            iconColor: const Color(0xFF2E7D32),
            iconBackground: const Color(0xFFE8F5E9),
          ),
        ),
        const SizedBox(width: 10),

        // Métrica: Lotes Activos
        Expanded(
          child: _MetricCard(
            label: 'Lotes Activos',
            value: metrics.activeLotes.toString(),
            icon: Icons.fence_rounded,
            iconColor: const Color(0xFF00796B),
            iconBackground: const Color(0xFFE0F2F1),
          ),
        ),
        const SizedBox(width: 10),

        // Métrica: Capturas Hoy
        Expanded(
          child: _MetricCard(
            label: 'Capturas Hoy',
            value: metrics.capturesToday.toString(),
            icon: Icons.camera_alt_rounded,
            iconColor: const Color(0xFFE65100),
            iconBackground: const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono en cápsula
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 12),

          // Valor numérico
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),

          // Etiqueta
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
