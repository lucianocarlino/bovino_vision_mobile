import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../capture/presentation/screens/capture_screen.dart';
import '../../../capture/presentation/screens/estimation_status_screen.dart';
import '../../../capture/presentation/screens/session_completed_screen.dart';
import '../../../rodeo/presentation/screens/rodeo_screen.dart';
import '../../data/home_mock_data.dart';
import '../providers/home_sync_provider.dart';
import '../widgets/capture_cta_button.dart';
import '../widgets/home_header.dart';
import '../widgets/metrics_grid.dart';
import '../widgets/recent_sessions_list.dart';
import '../widgets/sync_status_card.dart';

/// Pantalla Principal del MVP BovinoVision
/// Con arquitectura Offline-First y reactividad ante cambios de conectividad y sincronización.
class HomeScreen extends StatefulWidget {
  final HomeDashboardData? initialData;

  const HomeScreen({
    super.key,
    this.initialData,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Consumo seguro del gestor de estado con fallback para entornos de testing aislados
    final homeProvider = Provider.of<HomeSyncProvider?>(context);

    final user = homeProvider?.user ??
        widget.initialData?.user ??
        HomeDashboardData.staticMock.user;

    final syncStatus = homeProvider?.syncStatus ??
        widget.initialData?.syncStatus ??
        HomeDashboardData.staticMock.syncStatus;

    final metrics = homeProvider?.metrics ??
        widget.initialData?.metrics ??
        HomeDashboardData.staticMock.metrics;

    final recentSessions = homeProvider?.recentSessions ??
        widget.initialData?.recentSessions ??
        HomeDashboardData.staticMock.recentSessions;

    final isOnline = homeProvider?.isOnline ?? user.isOnline;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.visibility_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'BovinoVision',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
        actions: [
          // Indicador dinámico de conectividad en AppBar (En línea / Sin conexión)
          Center(
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isOnline
                          ? 'Estado de red: En línea. Servidor central alcanzable.'
                          : 'Estado de red: Sin conexión. Operando en modo SQLite local.',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.onlineLight : AppColors.offlineLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isOnline
                        ? AppColors.online.withValues(alpha: 0.35)
                        : AppColors.offline.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                      size: 14,
                      color: isOnline ? AppColors.online : AppColors.offline,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isOnline ? 'En línea' : 'Sin conexión',
                      style: TextStyle(
                        color: isOnline ? AppColors.online : AppColors.offline,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            if (homeProvider != null) {
              await homeProvider.loadData();
              if (homeProvider.isOnline && homeProvider.pendingCount > 0) {
                await homeProvider.syncNow();
              }
            } else {
              await Future.delayed(const Duration(milliseconds: 400));
              setState(() {});
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tarjeta de Usuario e Indicador de Conectividad en Cabecera
                HomeHeader(
                  user: user,
                  onConnectivityTap: () {
                    if (homeProvider != null) {
                      homeProvider.setSimulatedConnectivity(!isOnline);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 2. Caja de Estado de Sincronización Dinámica Offline-first
                SyncStatusCard(
                  syncStatus: syncStatus,
                  onSyncPressed: () async {
                    if (homeProvider != null) {
                      if (!homeProvider.isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sin conexión a internet. Los datos se guardan en SQLite local.',
                            ),
                            backgroundColor: AppColors.offline,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            syncStatus.isSynced
                                ? 'Base de datos sincronizada con el servidor.'
                                : 'Iniciando sincronización de cola SQLite...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );

                      await homeProvider.syncNow();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            syncStatus.isSynced
                                ? 'Base de datos sincronizada con el servidor.'
                                : 'Iniciando sincronización de cola SQLite...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 3. Grid de Métricas del Rodeo (KPIs)
                MetricsGrid(metrics: metrics),
                const SizedBox(height: 20),

                // 4. CTA Primario: Iniciar Sesión de Captura
                CaptureCtaButton(
                  isOnline: isOnline,
                  onStartCapture: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CaptureScreen(),
                      ),
                    );
                    // Actualizar panel al regresar de la captura
                    if (mounted && homeProvider != null) {
                      await homeProvider.loadData();
                    }
                  },
                ),
                const SizedBox(height: 24),

                // 5. Lista de Sesiones Recientes (combinando sincronizadas y pendientes)
                RecentSessionsList(
                  sessions: recentSessions,
                  onSessionTap: (session) {
                    if (session.isPending) {
                      // Sesión pendiente de subida: muestra estado de sincronización
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EstimationStatusScreen.fromSession(
                            session: session,
                          ),
                        ),
                      );
                    } else {
                      // Sesión procesada y sincronizada: muestra resultados de estimación
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SessionCompletedScreen.fromSession(
                            session: session,
                            isOffline: !isOnline,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) async {
          if (index == 1) {
            // Enlazar la opción del menú inferior ("Rodeo") con el buscador de animales
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RodeoScreen(),
              ),
            );
            if (mounted) {
              setState(() {
                _currentNavIndex = 0;
              });
            }
            return;
          }

          setState(() {
            _currentNavIndex = index;
          });

          if (index != 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Not implemented'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded, color: AppColors.primary),
            label: 'Rodeo',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }
}
