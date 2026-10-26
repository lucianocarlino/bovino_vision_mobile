import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../data/capture_api.dart';
import '../data/capture_models.dart';
import 'capture_summary.dart';

/// Capture home: greeting, connection pill, the big "Nueva captura" button and recent sessions.
class CaptureHomeScreen extends StatefulWidget {
  const CaptureHomeScreen({super.key});

  @override
  State<CaptureHomeScreen> createState() => _CaptureHomeScreenState();
}

class _CaptureHomeScreenState extends State<CaptureHomeScreen> {
  static const _recentCount = 5;

  final _now = DateTime.now();
  var _loading = true;
  var _sessions = <RecentSession>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sessions = await CaptureApi(context.read<ApiClient>()).recentSessions(limit: _recentCount);
      if (mounted) setState(() => _sessions = sessions);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startCapture() async {
    await context.push(AppRoutes.captureNew);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthController>().session?.user.name ?? '';
    final online = context.watch<ConnectivityService>().isOnline;

    return ListView(
      padding: pagePadding,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${greetingFor(_now)},', style: const TextStyle(fontSize: 14, color: AppColors.neutral500)),
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.neutral800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const ConnectionPill(),
          ],
        ),
        const SizedBox(height: 24),
        _NewCaptureButton(onTap: online ? _startCapture : null),
        if (!online) ...[
          const SizedBox(height: 12),
          const Notice(
            title: 'Sin conexión',
            message: 'Necesitás conexión para sacar fotos y enviarlas. Conectate para empezar una captura.',
            tone: NoticeTone.warning,
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'Sesiones recientes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.neutral800),
        ),
        const SizedBox(height: 12),
        _recentSessions(),
      ],
    );
  }

  Widget _recentSessions() {
    if (_loading) return const LoadingView(label: 'Cargando sesiones…');
    if (_error != null) return ErrorRetry(message: 'No pudimos cargar las sesiones recientes: $_error', onRetry: _load);
    if (_sessions.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'Todavía no hiciste capturas',
        message: 'Las sesiones que empieces van a aparecer acá.',
      );
    }
    return Column(
      children: [
        for (final session in _sessions) ...[
          _SessionCard(summary: summarizeSession(session, _now)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

/// Hero button: green gradient, 92 px tall, camera tile, title and subtitle.
class _NewCaptureButton extends StatelessWidget {
  const _NewCaptureButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.card);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.green600, AppColors.green800],
          ),
          boxShadow: AppShadows.md,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 92),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.15), borderRadius: radius),
                      child: const Icon(Icons.photo_camera_outlined, size: 28, color: AppColors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva captura',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              height: 1.2,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pesá sin arrear: 4 tomas y listo',
                            style: TextStyle(fontSize: 14, color: AppColors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 24, color: AppColors.white.withValues(alpha: 0.85)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: const Icon(Icons.photo_camera_outlined, size: 20, color: AppColors.green600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'Sesión de captura',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                      ),
                    ),
                    if (summary.inProgress) ...[
                      const SizedBox(width: 8),
                      const AppBadge(label: 'En curso', tone: BadgeTone.warning),
                    ],
                  ],
                ),
                Text(summary.detail, style: const TextStyle(fontSize: 12, color: AppColors.neutral500)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            summary.when,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral500),
          ),
        ],
      ),
    );
  }
}
