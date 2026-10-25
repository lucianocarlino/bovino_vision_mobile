import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/home_mock_data.dart';

/// Modelo de datos para cada paso individual en la sincronización e inferencia.
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

/// Modelo representativo del estado general de la sesión de estimación.
class EstimationStatusData {
  final String animalId;
  final double overallProgress;
  final List<EstimationStepModel> steps;
  final bool isPending;

  const EstimationStatusData({
    required this.animalId,
    required this.overallProgress,
    required this.steps,
    this.isPending = true,
  });

  factory EstimationStatusData.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    final progress = (json['overallProgress'] as num?)?.toDouble() ?? 0.0;
    return EstimationStatusData(
      animalId: json['animalId'] as String? ?? '',
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
      return EstimationStatusData(
        animalId: session.id.startsWith('AR-')
            ? session.id
            : (session.animalsProcessed == 1
                ? 'AR-003421'
                : 'AR-003421 (${session.animalsProcessed} en sesión)'),
        overallProgress: 0.45,
        isPending: true,
        steps: const [
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
          EstimationStepModel(
            title: 'Estimando peso (IA)',
            status: 'pending',
          ),
        ],
      );
    } else {
      final animalTag = session.id == 's1'
          ? 'AR-001012'
          : (session.id == 's2' ? 'AR-002030' : 'AR-003421');

      return EstimationStatusData(
        animalId: session.id.startsWith('AR-')
            ? session.id
            : '$animalTag (${session.animalsProcessed} procesados)',
        overallProgress: 1.0,
        isPending: false,
        steps: const [
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
          EstimationStepModel(
            title: 'Estimación completada (IA)',
            status: 'completed',
            detail: 'Inferencia biométrica finalizada',
          ),
        ],
      );
    }
  }

  /// Mock estático según especificaciones de negocio
  static const Map<String, dynamic> mockJson = {
    "animalId": "AR-003421",
    "overallProgress": 0.45,
    "steps": [
      {"title": "Conexión al backend establecida", "status": "completed"},
      {"title": "Prioridad asignada en cola", "status": "completed"},
      {
        "title": "Subiendo imagen (1/1)",
        "status": "in_progress",
        "detail": "45% completado (1.2 MB / 2.6 MB)"
      },
      {"title": "Estimando peso (IA)", "status": "pending"}
    ]
  };

  static EstimationStatusData get defaultMock =>
      EstimationStatusData.fromJson(mockJson);
}

/// Pantalla de estado de sincronización e inferencia para estimación bovina.
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

  /// Despliega el SnackBar estricto para acciones no implementadas
  void _showNotImplemented() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not implemented'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              // 1. Cabecera estética con difuminado, spinner/badge y datos del animal
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
            ],
          ),
        ),
      ),
    );
  }

  /// Barra superior: botón de cerrar ('X') y título sin el indicador '4/4'
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
        onPressed: _showNotImplemented,
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
                              Icons.psychology_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 18),

              // Chip de identificación del animal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.tag_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Caravana: ${_data.animalId}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Título principal
              Text(
                isCompleted ? 'Estimación completada' : 'Estimando peso...',
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
                    ? 'Inferencia y sincronización completadas con éxito.\nEl pesaje ha sido registrado en el rodeo.'
                    : 'Identificando la caravana y evaluando la condición corporal.\nNo cierres la aplicación.',
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
                'Progreso del análisis',
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
