import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/rodeo_mock_data.dart';

/// Pantalla de Detalle del Animal de BovinoVision.
/// Permite visualizar y editar la información de trazabilidad y biometría de un bovino.
class AnimalDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool? isOffline;
  final Map<String, dynamic>? animalDetail;

  const AnimalDetailScreen({
    super.key,
    this.initialData,
    this.isOffline,
    this.animalDetail,
  });

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late bool _isOffline;
  late Map<String, dynamic> _detail;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.isOffline ??
        widget.initialData?['isOffline'] as bool? ??
        RodeoMockData.isOffline;

    final initialDetail = widget.animalDetail ??
        widget.initialData?['animalDetail'] as Map<String, dynamic>? ??
        RodeoMockData.animalDetail;
    _detail = Map<String, dynamic>.from(initialDetail);
  }

  void _showNotImplementedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not implemented'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Abre un diálogo modal interactivo para modificar el identificador,
  /// el lote, la raza, el sexo y la fecha de nacimiento del animal.
  Future<void> _openEditAnimalDialog() async {
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _EditAnimalDialog(initialDetail: _detail),
    );

    if (updated != null && mounted) {
      setState(() {
        _detail.addAll(updated);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos del animal actualizados'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _detail['id'] ?? 'Detalle del Animal',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textPrimary),
            tooltip: 'Modificar animal',
            onPressed: _openEditAnimalDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Imagen Superior con soporte reactivo a estado de red (Online / Offline)
              _buildHeaderImage(),
              const SizedBox(height: 18),

              // 2. Encabezado de Identificación SENASA, Raza, Sexo, Edad y Chip de Salud
              _buildIdentificationHeader(),
              const SizedBox(height: 18),

              // 3. Grid 2x2 de Parámetros: Lote, Nacimiento, Último Peso y GMD (Not implemented)
              _buildMetricsGrid(),
              const SizedBox(height: 22),

              // 4. Historial de Pesajes: Gráfico y Lista inferior (Not implemented)
              _buildWeightHistorySection(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la imagen superior según el estado de conexión del dispositivo.
  /// Si isOffline == false muestra la imagen del animal.
  /// Si isOffline == true muestra un contenedor gris / placeholder estético.
  Widget _buildHeaderImage() {
    final imagePath = _detail['imagen'] as String? ?? '';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 210,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _isOffline ? const Color(0xFFE4E8E4) : AppColors.surfaceMuted,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _isOffline
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_off_rounded,
                      size: 38,
                      color: AppColors.offline,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Imagen no disponible',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Modo sin conexión activo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surfaceMuted,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 54,
                                color: AppColors.primaryLight.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _detail['raza'] ?? 'Bovino',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Última captura',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Construye la cabecera de datos con el identificador SENASA, raza, sexo, edad
  /// y el chip de Salud atenuado como 'Not implemented'. Incluye botón de edición rápida.
  Widget _buildIdentificationHeader() {
    final id = _detail['id'] ?? 'S/ID';
    final raza = _detail['raza'] ?? 'Raza no definida';
    final sexo = _detail['sexo'] ?? 'No especificado';
    final edad = _detail['edad'] ?? 'Edad no registrada';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'IDENTIFICADOR SENASA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: _openEditAnimalDialog,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(
                              Icons.edit_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Chip de Salud marcado visualmente como "Not implemented"
              _buildNotImplementedChip(
                label: 'Salud',
                icon: Icons.favorite_border_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                raza,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('·', style: TextStyle(color: AppColors.textMuted)),
              ),
              Text(
                sexo,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text('·', style: TextStyle(color: AppColors.textMuted)),
              ),
              Text(
                edad,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Grid 2x2 con parámetros del animal: LOTE, NACIMIENTO, ÚLTIMO PESO y GMD.
  Widget _buildMetricsGrid() {
    final lote = _detail['lote'] ?? 'Sin asignar';
    final nacimiento = _detail['nacimiento'] ?? '-';
    final ultimoPeso = _detail['ultimoPeso'] ?? '-';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.grid_view_rounded,
                title: 'LOTE',
                value: lote,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.calendar_today_rounded,
                title: 'NACIMIENTO',
                value: nacimiento,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.monitor_weight_outlined,
                title: 'ÚLTIMO PESO',
                value: ultimoPeso,
                isHighlight: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNotImplementedCard(
                title: 'GMD',
                subtitle: 'Ganancia Media Diaria',
                icon: Icons.trending_up_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tarjeta estándar para datos implementados (Lote, Nacimiento, Último Peso).
  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight
              ? AppColors.primaryLight.withValues(alpha: 0.4)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: isHighlight ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 14.5,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppColors.primary : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Chip visual superior para funciones no implementadas (ej. Salud).
  Widget _buildNotImplementedChip({
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _showNotImplementedSnackBar(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              '$label: Not implemented',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta con estilo atenuado para funciones no implementadas (ej. GMD).
  Widget _buildNotImplementedCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => _showNotImplementedSnackBar(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F5F3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Not implemented',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección del Historial de pesajes (gráfico y lista inferior),
  /// mostrada visualmente como 'Not implemented' según los requisitos del sistema.
  Widget _buildWeightHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de pesajes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Evolución en los últimos 6 meses',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Not implemented',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Gráfico atenuado
          InkWell(
            onTap: () => _showNotImplementedSnackBar(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 110,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 36,
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gráfico de evolución: Not implemented',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Lista inferior de últimos pesajes
          const Text(
            'Últimos pesajes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          InkWell(
            onTap: () => _showNotImplementedSnackBar(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Lista de pesajes históricos: Not implemented',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Diálogo modal con formulario para editar los datos biométricos del animal.
class _EditAnimalDialog extends StatefulWidget {
  final Map<String, dynamic> initialDetail;

  const _EditAnimalDialog({required this.initialDetail});

  @override
  State<_EditAnimalDialog> createState() => _EditAnimalDialogState();
}

class _EditAnimalDialogState extends State<_EditAnimalDialog> {
  late final TextEditingController _idController;
  late final TextEditingController _loteController;
  late final TextEditingController _razaController;
  late final TextEditingController _sexoController;
  late final TextEditingController _nacimientoController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.initialDetail['id']?.toString() ?? '');
    _loteController = TextEditingController(text: widget.initialDetail['lote']?.toString() ?? '');
    _razaController = TextEditingController(text: widget.initialDetail['raza']?.toString() ?? '');
    _sexoController = TextEditingController(text: widget.initialDetail['sexo']?.toString() ?? '');
    _nacimientoController = TextEditingController(text: widget.initialDetail['nacimiento']?.toString() ?? '');
  }

  @override
  void dispose() {
    _idController.dispose();
    _loteController.dispose();
    _razaController.dispose();
    _sexoController.dispose();
    _nacimientoController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? true) {
      Navigator.of(context).pop({
        'id': _idController.text.trim(),
        'lote': _loteController.text.trim(),
        'raza': _razaController.text.trim(),
        'sexo': _sexoController.text.trim(),
        'nacimiento': _nacimientoController.text.trim(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: AppColors.surface,
      title: const Row(
        children: [
          Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
          SizedBox(width: 8),
          Text(
            'Modificar animal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'Identificador SENASA',
                    prefixIcon: Icon(Icons.qr_code_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa un identificador válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _loteController,
                  decoration: const InputDecoration(
                    labelText: 'Lote',
                    prefixIcon: Icon(Icons.grid_view_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _razaController,
                  decoration: const InputDecoration(
                    labelText: 'Raza',
                    prefixIcon: Icon(Icons.pets_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _sexoController,
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    prefixIcon: Icon(Icons.transgender_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nacimientoController,
                  decoration: const InputDecoration(
                    labelText: 'Nacimiento',
                    prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
