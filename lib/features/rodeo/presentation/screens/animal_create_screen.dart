import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Pantalla de Creación y Registro de Animales en BovinoVision.
/// Permite ingresar los datos obligatorios de un nuevo bovino
/// manteniendo la misma distribución y estilo de tarjetas que [AnimalDetailScreen].
class AnimalCreateScreen extends StatefulWidget {
  final bool? isOffline;
  final List<String>? initialLotes;
  final void Function(Map<String, dynamic> animal)? onAnimalCreated;

  const AnimalCreateScreen({
    super.key,
    this.isOffline,
    this.initialLotes,
    this.onAnimalCreated,
  });

  @override
  State<AnimalCreateScreen> createState() => _AnimalCreateScreenState();
}

class _AnimalCreateScreenState extends State<AnimalCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores y variables de formulario
  late final TextEditingController _idController;
  late final TextEditingController _nacimientoController;

  String? _selectedRaza;
  String? _selectedSexo;
  String? _selectedLote;
  bool _isSaving = false;

  // Catálogos iniciales con pocos datos mockeados y extensibles dinámicamente
  late List<String> _razas;
  late List<String> _lotes;

  static const List<String> _razasIniciales = [
    'Aberdeen Angus',
    'Hereford',
    'Brangus',
  ];

  static const List<String> _sexosDisponibles = [
    'Macho',
    'Hembra',
  ];

  static const List<String> _lotesIniciales = [
    'Lote A-12',
    'Lote B-05',
  ];

  static const String _actionCreateLote = '__ACTION_CREATE_LOTE__';
  static const String _actionCreateRaza = '__ACTION_CREATE_RAZA__';

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController();
    _nacimientoController = TextEditingController();

    _razas = List<String>.from(_razasIniciales);
    _lotes = widget.initialLotes != null && widget.initialLotes!.isNotEmpty
        ? List<String>.from(widget.initialLotes!)
        : List<String>.from(_lotesIniciales);
  }

  @override
  void dispose() {
    _idController.dispose();
    _nacimientoController.dispose();
    super.dispose();
  }

  /// Diálogo modal interactivo para crear una nueva opción (Lote o Raza)
  /// directamente desde el formulario.
  Future<void> _showCreateOptionDialog({
    required String title,
    required String labelText,
    required String hintText,
    required IconData icon,
    required void Function(String) onConfirm,
    VoidCallback? onCancel,
  }) async {
    final textController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre no puede estar vacío';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(textController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (created != null && created.isNotEmpty) {
      onConfirm(created);
    } else {
      onCancel?.call();
    }
  }

  /// Despliega el selector de fecha nativo para la fecha de nacimiento.
  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1, now.month, now.day),
      firstDate: DateTime(now.year - 25),
      lastDate: now,
      builder: (dialogContext, child) {
        return Theme(
          data: Theme.of(dialogContext).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final dia = pickedDate.day.toString().padLeft(2, '0');
      final mes = pickedDate.month.toString().padLeft(2, '0');
      final anio = pickedDate.year.toString();
      setState(() {
        _nacimientoController.text = '$dia/$mes/$anio';
      });
    }
  }

  /// Valida el formulario y guarda los datos del animal registrado.
  void _onSaveAnimal() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final nuevoId = _idController.text.trim();
    final nuevoAnimal = <String, dynamic>{
      'id': nuevoId,
      'raza': _selectedRaza ?? '',
      'sexo': _selectedSexo ?? '',
      'lote': _selectedLote ?? '',
      'nacimiento': _nacimientoController.text.trim(),
      'peso': '- kg',
      'estado': 'Registrado',
      'imagen': '',
      'isOffline': widget.isOffline ?? false,
    };

    widget.onAnimalCreated?.call(nuevoAnimal);

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animal $nuevoId registrado con éxito'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).maybePop(nuevoAnimal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Registrar Animal',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Formulario estructurado con el mismo estilo de tarjetas
                _buildFormFields(),
                const SizedBox(height: 24),

                // Botón principal de guardado
                _buildSaveButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye todos los campos de formulario organizados en tarjetas blancas.
  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjeta principal: Identificador SENASA
        _buildIdentificationCard(),
        const SizedBox(height: 16),

        // Tarjetas de Parámetros: Raza y Sexo
        _buildMorphologySection(),
        const SizedBox(height: 16),

        // Tarjetas de Trazabilidad: Lote y Fecha de Nacimiento
        _buildTraceabilitySection(),
      ],
    );
  }

  /// Tarjeta blanca con estilo idéntico al encabezado de identificación del detalle.
  /// Contiene el campo obligatorio del Identificador SENASA.
  Widget _buildIdentificationCard() {
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
          const Row(
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 6),
              Text(
                'IDENTIFICADOR SENASA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _idController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
            decoration: InputDecoration(
              hintText: 'Ej. AR-003421',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El identificador SENASA es obligatorio';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// Tarjetas para los parámetros morfológicos (Raza y Sexo).
  Widget _buildMorphologySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo: Raza (desplegable con opción de crear)
        Expanded(
          child: _buildCardContainer(
            icon: Icons.pets_rounded,
            title: 'RAZA',
            onAddPressed: () {
              _showCreateOptionDialog(
                title: 'Nueva Raza',
                labelText: 'Nombre de la raza',
                hintText: 'Ej. Braford',
                icon: Icons.pets_rounded,
                onConfirm: (nuevaRaza) {
                  setState(() {
                    if (!_razas.contains(nuevaRaza)) {
                      _razas.add(nuevaRaza);
                    }
                    _selectedRaza = nuevaRaza;
                  });
                },
              );
            },
            child: DropdownButtonFormField<String>(
              value: _selectedRaza,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              decoration: _inputDecoration(hintText: 'Seleccionar'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: [
                ..._razas.map((raza) {
                  return DropdownMenuItem<String>(
                    value: raza,
                    child: Text(
                      raza,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: _actionCreateRaza,
                  child: Text(
                    '+ Nueva raza',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == _actionCreateRaza) {
                  final previousRaza = _selectedRaza;
                  _showCreateOptionDialog(
                    title: 'Nueva Raza',
                    labelText: 'Nombre de la raza',
                    hintText: 'Ej. Braford',
                    icon: Icons.pets_rounded,
                    onConfirm: (nuevaRaza) {
                      setState(() {
                        if (!_razas.contains(nuevaRaza)) {
                          _razas.add(nuevaRaza);
                        }
                        _selectedRaza = nuevaRaza;
                      });
                    },
                    onCancel: () {
                      setState(() {
                        _selectedRaza = previousRaza;
                      });
                    },
                  );
                } else {
                  setState(() {
                    _selectedRaza = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty || value == _actionCreateRaza) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Campo: Sexo
        Expanded(
          child: _buildCardContainer(
            icon: Icons.transgender_rounded,
            title: 'SEXO',
            child: DropdownButtonFormField<String>(
              value: _selectedSexo,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              decoration: _inputDecoration(hintText: 'Seleccionar'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: _sexosDisponibles.map((sexo) {
                return DropdownMenuItem<String>(
                  value: sexo,
                  child: Text(
                    sexo,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSexo = value;
                });
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjetas para los parámetros de trazabilidad (Lote y Fecha de Nacimiento).
  Widget _buildTraceabilitySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo: Lote (desplegable con opción de crear)
        Expanded(
          child: _buildCardContainer(
            icon: Icons.grid_view_rounded,
            title: 'LOTE',
            onAddPressed: () {
              _showCreateOptionDialog(
                title: 'Nuevo Lote',
                labelText: 'Nombre o número de lote',
                hintText: 'Ej. Lote C-03',
                icon: Icons.grid_view_rounded,
                onConfirm: (nuevoLote) {
                  setState(() {
                    if (!_lotes.contains(nuevoLote)) {
                      _lotes.add(nuevoLote);
                    }
                    _selectedLote = nuevoLote;
                  });
                },
              );
            },
            child: DropdownButtonFormField<String>(
              value: _selectedLote,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary),
              decoration: _inputDecoration(hintText: 'Seleccionar'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              items: [
                ..._lotes.map((lote) {
                  return DropdownMenuItem<String>(
                    value: lote,
                    child: Text(
                      lote,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: _actionCreateLote,
                  child: Text(
                    '+ Nuevo lote',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              onChanged: (value) {
                if (value == _actionCreateLote) {
                  final previousLote = _selectedLote;
                  _showCreateOptionDialog(
                    title: 'Nuevo Lote',
                    labelText: 'Nombre o número de lote',
                    hintText: 'Ej. Lote C-03',
                    icon: Icons.grid_view_rounded,
                    onConfirm: (nuevoLote) {
                      setState(() {
                        if (!_lotes.contains(nuevoLote)) {
                          _lotes.add(nuevoLote);
                        }
                        _selectedLote = nuevoLote;
                      });
                    },
                    onCancel: () {
                      setState(() {
                        _selectedLote = previousLote;
                      });
                    },
                  );
                } else {
                  setState(() {
                    _selectedLote = value;
                  });
                }
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty || value == _actionCreateLote) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Campo: Fecha de Nacimiento
        Expanded(
          child: _buildCardContainer(
            icon: Icons.calendar_today_rounded,
            title: 'NACIMIENTO',
            child: TextFormField(
              controller: _nacimientoController,
              readOnly: true,
              onTap: () => _pickBirthDate(context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: _inputDecoration(
                hintText: 'DD/MM/AAAA',
                suffixIcon: const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Contenedor reutilizable de tarjeta con estilo idéntico a las tarjetas métricas del detalle.
  Widget _buildCardContainer({
    required IconData icon,
    required String title,
    required Widget child,
    VoidCallback? onAddPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onAddPressed != null)
                InkWell(
                  onTap: onAddPressed,
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(2.0),
                    child: Icon(
                      Icons.add_circle_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Decoración base para campos dentro de las tarjetas métricas.
  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: AppColors.textMuted,
      ),
      filled: true,
      fillColor: AppColors.background,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      errorStyle: const TextStyle(
        fontSize: 11,
        color: Colors.redAccent,
      ),
    );
  }

  /// Botón principal inferior para guardar el nuevo animal.
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isSaving ? null : _onSaveAnimal,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded, size: 20),
        label: Text(
          _isSaving ? 'Guardando...' : 'Guardar Animal',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
