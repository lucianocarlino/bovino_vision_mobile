import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/data/home_mock_data.dart';

/// Modelo de datos para el resumen general de la sesión sincronizada.
class SessionSummaryModel {
  final String date;
  final String time;
  final int totalAnimals;

  const SessionSummaryModel({
    required this.date,
    required this.time,
    required this.totalAnimals,
  });

  factory SessionSummaryModel.fromJson(Map<String, dynamic> json) {
    return SessionSummaryModel(
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      totalAnimals: json['totalAnimals'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'time': time,
    'totalAnimals': totalAnimals,
  };

  SessionSummaryModel copyWith({
    String? date,
    String? time,
    int? totalAnimals,
  }) {
    return SessionSummaryModel(
      date: date ?? this.date,
      time: time ?? this.time,
      totalAnimals: totalAnimals ?? this.totalAnimals,
    );
  }
}

/// Modelo de datos para el detalle individual de cada animal en la sesión.
class AnimalDetailModel {
  final String id;
  final num weight;
  final String lote;
  final String previousWeight;
  final String operatorName;

  const AnimalDetailModel({
    required this.id,
    required this.weight,
    required this.lote,
    required this.previousWeight,
    required this.operatorName,
  });

  factory AnimalDetailModel.fromJson(Map<String, dynamic> json) {
    return AnimalDetailModel(
      id: json['id'] as String? ?? '',
      weight: (json['weight'] as num?) ?? 0,
      lote: json['lote'] as String? ?? '',
      previousWeight: json['previousWeight'] as String? ?? '',
      operatorName: json['operator'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weight': weight,
    'lote': lote,
    'previousWeight': previousWeight,
    'operator': operatorName,
  };

  AnimalDetailModel copyWith({
    String? id,
    num? weight,
    String? lote,
    String? previousWeight,
    String? operatorName,
  }) {
    return AnimalDetailModel(
      id: id ?? this.id,
      weight: weight ?? this.weight,
      lote: lote ?? this.lote,
      previousWeight: previousWeight ?? this.previousWeight,
      operatorName: operatorName ?? this.operatorName,
    );
  }
}

/// Estado global inmutable para la pantalla de sesión finalizada.
class SessionCompletedData {
  final bool isOffline;
  final SessionSummaryModel sessionSummary;
  final List<AnimalDetailModel> animals;

  const SessionCompletedData({
    this.isOffline = false,
    required this.sessionSummary,
    required this.animals,
  });

  factory SessionCompletedData.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['sessionSummary'] as Map<String, dynamic>? ?? {};
    final animalsJson = json['animals'] as List<dynamic>? ?? [];

    return SessionCompletedData(
      isOffline: json['isOffline'] as bool? ?? false,
      sessionSummary: SessionSummaryModel.fromJson(summaryJson),
      animals: animalsJson
          .map((e) => AnimalDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Crea los datos de la pantalla a partir de un modelo de sesión sincronizada
  factory SessionCompletedData.fromSession(
    RecentSessionModel session, {
    bool isOffline = false,
  }) {
    final defaultMock = SessionCompletedData.staticMock;
    return SessionCompletedData(
      isOffline: isOffline,
      sessionSummary: SessionSummaryModel(
        date: session.displayDay,
        time: session.displayTime,
        totalAnimals: session.animalsProcessed > 0
            ? session.animalsProcessed
            : defaultMock.sessionSummary.totalAnimals,
      ),
      animals: defaultMock.animals,
    );
  }

  Map<String, dynamic> toJson() => {
    'isOffline': isOffline,
    'sessionSummary': sessionSummary.toJson(),
    'animals': animals.map((a) => a.toJson()).toList(),
  };

  SessionCompletedData copyWith({
    bool? isOffline,
    SessionSummaryModel? sessionSummary,
    List<AnimalDetailModel>? animals,
  }) {
    return SessionCompletedData(
      isOffline: isOffline ?? this.isOffline,
      sessionSummary: sessionSummary ?? this.sessionSummary,
      animals: animals ?? this.animals,
    );
  }

  /// Mock estático según especificaciones de negocio
  static const Map<String, dynamic> mockJson = {
    "isOffline": false,
    "sessionSummary": {
      "date": "15/05/2026",
      "time": "09:12",
      "totalAnimals": 12,
    },
    "animals": [
      {
        "id": "AR-003421",
        "weight": 458,
        "lote": "A-12 - Potrero 4",
        "previousWeight": "443 kg • +15 kg en 33 días",
        "operator": "F. López",
      },
      {
        "id": "AR-003422",
        "weight": 510,
        "lote": "A-12 - Potrero 4",
        "previousWeight": "490 kg • +20 kg en 33 días",
        "operator": "F. López",
      },
    ],
  };

  static SessionCompletedData get staticMock =>
      SessionCompletedData.fromJson(mockJson);
}

/// Pantalla de resultados de una sesión finalizada (session_completed_screen.dart).
/// Muestra los pesajes estimados sincronizados o la vista reducida si el dispositivo se encuentra offline.
class SessionCompletedScreen extends StatefulWidget {
  final SessionCompletedData? initialData;
  final bool? isOffline;
  final VoidCallback? onBackPressed;
  final VoidCallback? onDiscardMeasurement;

  const SessionCompletedScreen({
    super.key,
    this.initialData,
    this.isOffline,
    this.onBackPressed,
    this.onDiscardMeasurement,
  });

  /// Constructor factory conveniente a partir de un modelo de sesión sincronizada
  factory SessionCompletedScreen.fromSession({
    Key? key,
    required RecentSessionModel session,
    bool? isOffline,
    VoidCallback? onBackPressed,
    VoidCallback? onDiscardMeasurement,
  }) {
    return SessionCompletedScreen(
      key: key,
      isOffline: isOffline,
      onBackPressed: onBackPressed,
      onDiscardMeasurement: onDiscardMeasurement,
      initialData: SessionCompletedData.fromSession(
        session,
        isOffline: isOffline ?? false,
      ),
    );
  }

  @override
  State<SessionCompletedScreen> createState() => _SessionCompletedScreenState();
}

class _SessionCompletedScreenState extends State<SessionCompletedScreen> {
  late SessionCompletedData _data;
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final baseData = widget.initialData ?? SessionCompletedData.staticMock;
    final effectiveOffline = widget.isOffline ?? baseData.isOffline;
    _data = baseData.copyWith(isOffline: effectiveOffline);
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Mensaje estándar para funciones pendientes según reglas de desarrollo
  void _showNotImplementedSnackBar() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not implemented'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Acción del botón volver atrás
  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    _showNotImplementedSnackBar();
  }

  /// Acción del botón descartar medición
  void _handleDiscardMeasurement() {
    if (widget.onDiscardMeasurement != null) {
      widget.onDiscardMeasurement!();
      return;
    }
    _showNotImplementedSnackBar();
  }

  /// Alterna el modo offline para testing e interacción en tiempo de ejecución
  void _toggleOfflineMode() {
    setState(() {
      _data = _data.copyWith(isOffline: !_data.isOffline);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _data.isOffline
              ? 'Modo sin conexión activado (vista resumida)'
              : 'Modo en línea activado (carrusel de animales)',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Cabecera con estado de la sesión y fecha/hora
            _buildSessionStatusHeader(),

            // Cuerpo principal: Carrusel en línea o Vista simplificada Offline
            Expanded(
              child: _data.isOffline
                  ? _buildOfflineView()
                  : _buildOnlineCarousel(),
            ),
          ],
        ),
      ),
    );
  }

  /// Barra superior con botón volver atrás, título y selector de estado de red
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Volver',
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 16,
          ),
        ),
        onPressed: _handleBack,
      ),
      title: const Text(
        'Resultados de sesión',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Chip interactivo para probar ambos estados de conectividad (Online / Offline)
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(
            child: InkWell(
              onTap: _toggleOfflineMode,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _data.isOffline
                      ? AppColors.offlineLight
                      : AppColors.onlineLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _data.isOffline
                        ? AppColors.offline.withValues(alpha: 0.4)
                        : AppColors.online.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _data.isOffline
                          ? Icons.wifi_off_rounded
                          : Icons.wifi_rounded,
                      size: 13,
                      color: _data.isOffline
                          ? AppColors.offline
                          : AppColors.online,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _data.isOffline ? 'Offline' : 'Online',
                      style: TextStyle(
                        color: _data.isOffline
                            ? AppColors.offline
                            : AppColors.online,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Cabecera informativa con resumen de sincronización de la sesión
  Widget _buildSessionStatusHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _data.isOffline
                  ? AppColors.offlineLight
                  : AppColors.onlineLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _data.isOffline
                  ? Icons.cloud_off_rounded
                  : Icons.cloud_done_rounded,
              size: 18,
              color: _data.isOffline ? AppColors.offline : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _data.isOffline
                      ? 'Sesión sincronizada (modo local)'
                      : 'Sesión procesada y sincronizada',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_data.sessionSummary.date} • ${_data.sessionSummary.time} • ${_data.sessionSummary.totalAnimals} animales',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// MODO ONLINE: Carrusel horizontal navegable entre todos los animales de la sesión
  Widget _buildOnlineCarousel() {
    if (_data.animals.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'No se encontraron animales registrados en esta sesión.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Indicador de posición actual en el carrusel
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Animal ${_currentPage + 1} de ${_data.animals.length}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _buildPageIndicator(),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Carrusel desplazable horizontalmente
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _data.animals.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final animal = _data.animals[index];
              return _buildAnimalCard(animal, index, _data.animals.length);
            },
          ),
        ),

        // Botón único inferior: "Descartar esta medición"
        _buildDiscardButton(),
      ],
    );
  }

  /// Indicadores de página discretos y estilizados
  Widget _buildPageIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_data.animals.length, (index) {
        final isSelected = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isSelected ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  /// Tarjeta individual del animal sin fotografía y sin indicadores de precisión/error
  Widget _buildAnimalCard(AnimalDetailModel animal, int index, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identificación del animal (Caravana)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          animal.id,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.onlineLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sincronizado',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bloque del peso estimado (Número grande y destacado)
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Peso estimado',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${animal.weight}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'kg',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 20),

              // Detalles del pesaje (Lote, Peso anterior, Operador)
              _buildDetailRow(
                icon: Icons.fence_rounded,
                label: 'Lote',
                value: animal.lote,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.history_rounded,
                label: 'Peso anterior',
                value: animal.previousWeight,
              ),
              const SizedBox(height: 14),
              _buildDetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Operador',
                value: animal.operatorName,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Fila modular de metadatos del animal
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Botón único de acción: "Descartar esta medición"
  Widget _buildDiscardButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Center(
        child: TextButton.icon(
          onPressed: _handleDiscardMeasurement,
          icon: const Icon(
            Icons.delete_outline_rounded,
            size: 18,
            color: Color(0xFFC62828),
          ),
          label: const Text(
            'Descartar esta medición',
            style: TextStyle(
              color: Color(0xFFC62828),
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  /// MODO OFFLINE: Vista simplificada cuando no hay internet
  /// Muestra únicamente: Fecha de la sesión, Hora, y Cantidad total de animales.
  Widget _buildOfflineView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner de estado Offline
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.offlineLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.offline.withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.offline,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dispositivo sin conexión',
                        style: TextStyle(
                          color: AppColors.offline,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'El detalle individual de los animales no está disponible sin conexión a internet para optimizar el almacenamiento local.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta simplificada mostrando ÚNICAMENTE Fecha, Hora y Cantidad total de animales
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Resumen de la sesión',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 16),

                // 1. Fecha de la sesión
                _buildOfflineSummaryRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Fecha de la sesión',
                  value: _data.sessionSummary.date,
                ),
                const SizedBox(height: 16),

                // 2. Hora
                _buildOfflineSummaryRow(
                  icon: Icons.access_time_rounded,
                  label: 'Hora',
                  value: _data.sessionSummary.time,
                ),
                const SizedBox(height: 16),

                // 3. Cantidad total de animales
                _buildOfflineSummaryRow(
                  icon: Icons.pets_rounded,
                  label: 'Cantidad total de animales',
                  value: '${_data.sessionSummary.totalAnimals}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Fila de resumen para la vista offline
  Widget _buildOfflineSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
