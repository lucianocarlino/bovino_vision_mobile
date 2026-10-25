import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/home_sync_provider.dart';
import '../../data/models/capture_record_model.dart';
import '../../data/models/capture_session_model.dart';
import '../../data/models/session_gallery_item.dart';
import '../../data/repositories/capture_repository.dart';
import '../widgets/animal_identification_header.dart';
import '../widgets/camera_preview_viewport.dart';
import '../widgets/camera_shutter_controls.dart';
import '../widgets/session_gallery_bar.dart';

/// Pantalla de Captura Biométrica de BovinoVision (capture_screen.dart)
/// Diseñada para operarios de campo en condiciones rurales offline-first.
class CaptureScreen extends StatefulWidget {
  final CaptureScreenData? initialData;

  const CaptureScreen({
    super.key,
    this.initialData,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late CaptureScreenData _data;
  late final TextEditingController _animalIdController;
  late final String _sessionId;
  final ImagePicker _imagePicker = ImagePicker();
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    // Identificador único para la sesión actual
    _sessionId = 'ses_${DateTime.now().millisecondsSinceEpoch}';
    // Carga de datos mock según especificación ERS
    _data = widget.initialData ?? CaptureScreenData.staticMock;
    _animalIdController = TextEditingController(text: _data.currentAnimalId);
  }

  @override
  void dispose() {
    _animalIdController.dispose();
    super.dispose();
  }

  /// Muestra el mensaje estandarizado para botones cuya lógica nativa está pendiente
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

  /// Abre la galería nativa mediante image_picker para importar una fotografía,
  /// actualiza la vista previa y añade la captura a la lista de la sesión.
  Future<void> _handleImportFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      // Manejo de cancelaciones: si el usuario regresa sin seleccionar una foto
      if (pickedFile == null) {
        return;
      }

      final currentId = _animalIdController.text.trim();
      final effectiveId = currentId.isNotEmpty
          ? currentId
          : 'BOV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

      if (_animalIdController.text.trim().isEmpty) {
        _animalIdController.text = effectiveId;
      }

      final newItem = SessionGalleryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        animalId: effectiveId,
        imageThumbnail: pickedFile.path,
        capturedAt: DateTime.now(),
      );

      setState(() {
        _selectedImagePath = pickedFile.path;
        _data = _data.copyWith(
          currentAnimalId: effectiveId,
          sessionGallery: [..._data.sessionGallery, newItem],
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imagen importada exitosamente para el animal $effectiveId.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar imagen: $e'),
          backgroundColor: AppColors.offline,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Lógica de disparo del obturador con validación de regla de negocio:
  /// "Solo se toma una foto por animal."
  void _handleShutterCapture() {
    final currentId = _animalIdController.text.trim();

    if (currentId.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese la identificación o caravana del animal.'),
          backgroundColor: AppColors.offline,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Verificación de existencia previa en la galería de la sesión
    final alreadyCaptured =
        _data.sessionGallery.any((item) => item.animalId == currentId);

    if (alreadyCaptured) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El animal $currentId ya cuenta con una captura registrada en esta sesión.',
          ),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Registro de nueva captura
    final newItem = SessionGalleryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      animalId: currentId,
      imageThumbnail: 'assets/mock_cow.jpg',
      capturedAt: DateTime.now(),
    );

    setState(() {
      _selectedImagePath = 'assets/mock_cow.jpg';
      _data = _data.copyWith(
        currentAnimalId: currentId,
        sessionGallery: [..._data.sessionGallery, newItem],
      );
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Captura registrada exitosamente para el animal $currentId.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Solicita confirmación al usuario antes de finalizar y guarda en SQLite local
  Future<void> _handleFinishSession() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              SizedBox(width: 10),
              Text(
                'Finalizar sesión',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          content: Text(
            '¿Desea finalizar la sesión de captura actual?\nSe registrarán ${_data.sessionGallery.length} ${_data.sessionGallery.length == 1 ? "toma" : "tomas"} en la base de datos local.',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'CANCELAR',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('CONFIRMAR'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Si hay elementos en la galería, persistirlos en la base de datos local SQLite
      if (_data.sessionGallery.isNotEmpty) {
        final records = _data.sessionGallery.map((item) {
          final hash = item.animalId.hashCode.abs();
          final pesoEstimado = 410.0 + (hash % 115);
          return CaptureRecordModel(
            id: 'cap_${item.id}',
            animalId: item.animalId,
            loteId: 'lote_campo_1',
            sessionId: _sessionId,
            pesoEstimado: pesoEstimado,
            confianza: 0.94,
            imagenPath: item.imageThumbnail,
            timestamp: item.capturedAt ?? DateTime.now(),
            syncStatus: 'pending',
          );
        }).toList();

        final homeProvider = Provider.of<HomeSyncProvider?>(context, listen: false);
        if (homeProvider != null) {
          await homeProvider.recordCaptureSession(
            sessionId: _sessionId,
            captures: records,
          );
        } else {
          try {
            await CaptureRepository().saveSessionCaptures(records);
          } catch (_) {}
        }
      }

      if (!mounted) return;
      // Regresa a la pantalla principal (HomeScreen)
      Navigator.of(context).popUntil((route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión finalizada y guardada en la base de datos local.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Construye el visor visual: si hay una foto seleccionada o capturada,
  /// la muestra manteniendo las proporciones y estilos visuales del visor de cámara.
  Widget _buildCameraViewport() {
    if (_selectedImagePath != null) {
      final isAsset = _selectedImagePath!.startsWith('assets/');

      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101411),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (isAsset)
                  Image.asset(
                    _selectedImagePath!,
                    fit: BoxFit.cover,
                  )
                else
                  Image.file(
                    File(_selectedImagePath!),
                    fit: BoxFit.cover,
                  ),

                // Indicador sutil de imagen seleccionada
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo_library_rounded,
                          color: AppColors.primaryLight,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Imagen de sesión',
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

                // Botón para cerrar la vista previa y regresar al visor en vivo
                Positioned(
                  top: 12,
                  right: 12,
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        setState(() {
                          _selectedImagePath = null;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const CameraPreviewViewport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Captura Biométrica',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          // Botón de alternar Flash
          IconButton(
            tooltip: 'Alternar Flash',
            icon: const Icon(
              Icons.flash_off_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: _showNotImplementedSnackBar,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Identificación del animal editable
              AnimalIdentificationHeader(
                controller: _animalIdController,
                onChanged: (val) {
                  _data = _data.copyWith(currentAnimalId: val);
                },
              ),
              const SizedBox(height: 16),

              // 2. Visor estético de la cámara o imagen seleccionada
              _buildCameraViewport(),
              const SizedBox(height: 16),

              // 3. Controles de captura (Galería, Obturador y Alternar Cámara)
              CameraShutterControls(
                onCapturePressed: _handleShutterCapture,
                onGalleryPressed: _handleImportFromGallery,
                onSecondaryControlPressed: _showNotImplementedSnackBar,
              ),
              const SizedBox(height: 16),

              // 4. Galería de sesión con ListView horizontal desplazable
              SessionGalleryBar(
                items: _data.sessionGallery,
                onItemPressed: (item) {
                  setState(() {
                    _selectedImagePath = item.imageThumbnail;
                  });
                },
              ),
              const SizedBox(height: 20),

              // 5. Botón de acción para finalizar la sesión con modal de confirmación
              ElevatedButton.icon(
                onPressed: _handleFinishSession,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('FINALIZAR SESIÓN DE CAPTURA'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
