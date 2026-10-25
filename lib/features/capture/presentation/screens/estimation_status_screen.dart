import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/home_mock_data.dart';
import 'session_completed_screen.dart';

/// Modelo de datos para cada paso individual en la sincronización.
class EstimationStepModel {
  final String title;
  final String status; // 'completed', 'in_progress', 'pending'
  final String? detail;

  const EstimationStepModel({
    required this.title,
    required this.status,
    this.detail,
  });

  factory EstimationStepModel.fromJson(Map<String, dynamic> json) {
    return EstimationStepModel(
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      detail: json['detail'] as String?,
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isPending => status == 'pending';
}

/// Modelo representativo del estado general de la sesión de sincronización.
class EstimationStatusData {
  final String? animalId;
  final double overallProgress;
  final List<EstimationStepModel> steps;
  final bool isPending;

  const EstimationStatusData({
    this.animalId,
    required this.overallProgress,
    required this.steps,
    this.isPending = true,
  });

  factory EstimationStatusData.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final progress = (json['overallProgress'] as num?)?.toDouble() ?? 0.0;
    return EstimationStatusData(
      animalId: json['animalId'] as String?,
      overallProgress: progress,
      isPending: json['isPending'] as bool? ?? (progress < 1.0),
      steps: rawSteps
          .map((e) => EstimationStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Genera los datos visuales correspondientes a una sesión seleccionada
  factory EstimationStatusData.fromSession(RecentSessionModel session) {
    if (session.isPending) {
      return const EstimationStatusData(
        overallProgress: 0.45,
        isPending: true,
        steps: [
          EstimationStepModel(
            title: 'Conexión al backend establecida',
            status: 'completed',
          ),
          EstimationStepModel(
            title: 'Prioridad asignada en cola',
            status: 'completed',
          ),
          EstimationStepModel(
            title: 'Subiendo imagen (1/1)',
            status: 'in_progress',
            detail: '45% completado (1.2 MB / 2.6 MB)',
          ),
        ],
      );
    } else {
      return const EstimationStatusData(
        overallProgress: 1.0,
        isPending: false,
        steps: [
          EstimationStepModel(
            title: 'Conexión al backend establecida',
            status: 'completed',
          ),
          EstimationStepModel(
            title: 'Prioridad asignada en cola',
            status: 'completed',
          ),
          EstimationStepModel(
            title: 'Imagen subida (1/1)',
            status: 'completed',
            detail: '100% completado (2.6 MB / 2.6 MB)',
          ),
        ],
      );
    }
  }

  /// Mock estático según especificaciones de negocio
  static const Map<String, dynamic> mockJson = {
    "overallProgress": 0.45,
    "steps": [
      {"title": "Conexión al backend establecida", "status": "completed"},
      {"title": "Prioridad asignada en cola", "status": "completed"},
      {
        "title": "Subiendo imagen (1/1)",
        "status": "in_progress",
        "detail": "45% completado (1.2 MB / 2.6 MB)"
      }
    ]
  };

  static EstimationStatusData get defaultMock =>
      EstimationStatusData.fromJson(mockJson);
}

/// Pantalla de estado de sincronización de la sesión.
/// Proporciona retroalimentación visual del backend y refuerza la filosofía Offline-First.
class EstimationStatusScreen extends StatefulWidget {
  final EstimationStatusData? initialData;
  final RecentSessionModel? session;

  const EstimationStatusScreen({
    super.key,
    this.initialData,
    this.session,
  });

  /// Constructor factory conveniente a partir de un modelo de sesión
  factory EstimationStatusScreen.fromSession({
    Key? key,
    required RecentSessionModel session,
  }) {
    return EstimationStatusScreen(
      key: key,
      session: session,
      initialData: EstimationStatusData.fromSession(session),
    );
  }

  @override
  State<EstimationStatusScreen> createState() => _EstimationStatusScreenState();
}

class _EstimationStatusScreenState extends State<EstimationStatusScreen>
    with SingleTickerProviderStateMixin {
  late final EstimationStatusData _data;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _data = widget.initialData!;
    } else if (widget.session != null) {
      _data = EstimationStatusData.fromSession(widget.session!);
    } else {
      _data = EstimationStatusData.defaultMock;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (_data.overallProgress < 1.0) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Retorna a la pantalla de inicio al presionar la 'X'
  void _handleClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = _data.overallProgress >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera estética con difuminado, spinner/badge
              _buildHeader(),
              const SizedBox(height: 24),

              // 2. Barra de progreso general del análisis
              _buildAnalysisProgress(),
              const SizedBox(height: 20),

              // 3. Lista de progreso (Checklist de sincronización real)
              _buildProgressList(),
              const SizedBox(height: 24),

              // 4. Tarjeta informativa Offline-first
              _buildInfoCard(),
              const SizedBox(height: 16),

              // 5. Botón para navegar a los resultados de la sesión si ya fue sincronizada y estimada
              if (isCompleted) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.session != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SessionCompletedScreen.fromSession(
                            session: widget.session!,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SessionCompletedScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('VER RESULTADOS DE LA SESIÓN'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Barra superior: botón de cerrar ('X') que retorna al inicio y título
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
        ),
        onPressed: _handleClose,
        tooltip: 'Cerrar',
      ),
      title: const Text(
        'Captura de ganado',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
    );
  }

  /// Cabecera visual con contenedor difuminado / semitransparente detrás del spinner
  Widget _buildHeader() {
    final isCompleted = _data.overallProgress >= 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Contenedor estético con spinner (o check si está completado)
              if (isCompleted)
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.onlineLight,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 46,
                  ),
                )
              else
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.04);
                    return Transform.scale(
                      scale: scale,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Halo de fondo con opacidad suave
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.12 + (_pulseController.value * 0.08),
                              ),
                            ),
                          ),
                          // Spinner circular estilizado
                          const SizedBox(
                            width: 72,
                            height: 72,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              backgroundColor: Color(0xFFD8E2D9),
                            ),
                          ),
                          // Icono central
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),

              // Título principal
              Text(
                isCompleted ? 'Sincronización completada' : 'Sincronizando sesión...',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Mensaje descriptivo
              Text(
                isCompleted
                    ? 'Imágenes y datos sincronizados con éxito.\nEl registro ha sido actualizado en el servidor.'
                    : 'Subiendo capturas y datos al backend.\nNo cierres la aplicación.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tarjeta de progreso general del análisis
  Widget _buildAnalysisProgress() {
    final percentage = (_data.overallProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de sincronización',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _data.overallProgress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// Lista de progreso de pasos de sincronización reales (Checklist)
  Widget _buildProgressList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _data.steps.length,
        itemBuilder: (context, index) {
          final step = _data.steps[index];
          final isLast = index == _data.steps.length - 1;
          return _buildStepItem(step, isLast: isLast);
        },
      ),
    );
  }

  /// Elemento modular para cada paso con línea conectora vertical
  Widget _buildStepItem(EstimationStepModel step, {required bool isLast}) {
    Widget iconWidget;

    if (step.isCompleted) {
      iconWidget = Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.syncSuccess,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 16,
        ),
      );
    } else if (step.isInProgress) {
      iconWidget = Container(
        width: 26,
        height: 26,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.onlineLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        child: const CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    } else {
      iconWidget = Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.textMuted.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.schedule_rounded,
          color: AppColors.textMuted,
          size: 14,
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conector vertical de progreso
          Column(
            children: [
              iconWidget,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: step.isCompleted
                        ? AppColors.syncSuccess.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Título y detalle del estado
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight:
                          step.isPending ? FontWeight.w500 : FontWeight.w700,
                      color: step.isPending
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (step.detail != null && step.detail!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.detail!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta informativa Offline-first (fiel al mensaje del mockup original)
  Widget _buildInfoCard() {
    final isCompleted = _data.overallProgress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FB), // Azul cielo suave Offline-first
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBEE3F8), // Borde azul sutil
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono informativo circular
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Color(0xFF2B6CB0), // Azul corporativo de contraste
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted
                  ? Icons.cloud_done_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Textos informativos Offline-first
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted
                      ? 'Sesión sincronizada con éxito'
                      : 'Podés seguir capturando',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A365D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCompleted
                      ? 'Los datos de la captura fueron sincronizados con el servidor central de BovinoVision.'
                      : 'Si perdés señal, la estimación queda en cola y se envía sola cuando vuelva la conexión.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2C5282),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
