import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/session.dart';
import '../../core/data/herd_api.dart';
import '../../core/data/herd_models.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/page_header.dart';
import 'alert_card.dart';
import 'alert_texts.dart';

/// Active alerts of the herd (`src/features/alertas/AlertasPage.tsx`).
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Alert>? _alerts;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _alerts = null;
      _error = null;
    });
    try {
      final alerts = await context.read<HerdApi>().activeAlerts();
      if (mounted) setState(() => _alerts = alerts);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResolve = context.watch<AuthController>().can(Permissions.herdManage);
    final alerts = _alerts;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: pagePadding,
        children: [
          const PageHeader(
            title: 'Alertas del rodeo',
            subtitle: 'Animales con pérdida de peso o GMD por debajo del objetivo de su lote.',
          ),
          const SizedBox(height: 24),
          if (_error != null)
            ErrorRetry(message: _error!, onRetry: _load)
          else if (alerts == null)
            const LoadingView()
          else if (alerts.isEmpty)
            const EmptyState(
              icon: Icons.notifications_active_outlined,
              title: 'No hay alertas activas',
              message: 'El rodeo está dentro de los objetivos de ganancia de peso.',
            )
          else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final level in PriorityLevel.values)
                  AppBadge(
                    label: '${alerts.where((a) => PriorityLevel.of(a.priority) == level).length} de prioridad ${level.label}',
                    tone: level.tone,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const CardHeader(title: 'Actividad reciente'),
                  for (final alert in alerts) ...[
                    AlertCard(
                      key: ValueKey(alert.id),
                      alert: alert,
                      canResolve: canResolve,
                      onResolved: (id) => setState(() => _alerts = _alerts!.where((a) => a.id != id).toList()),
                    ),
                    if (alert != alerts.last) const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
