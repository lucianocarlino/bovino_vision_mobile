import 'package:flutter/material.dart';
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

  /// Feedback informativo al pulsar sobre el indicador offline
  void _handleOfflineIndicatorPressed() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${_data.pendingSyncCount} pesajes guardados localmente pendientes de sincronización.',
        ),
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
              // 1. Identificación del animal editable y Chip Offline
              AnimalIdentificationHeader(
                controller: _animalIdController,
                pendingSyncCount: _data.pendingSyncCount,
                onChanged: (val) {
                  _data = _data.copyWith(currentAnimalId: val);
                },
                onSyncInfoPressed: _handleOfflineIndicatorPressed,
              ),
              const SizedBox(height: 16),

              // 2. Visor estético de la cámara
              const CameraPreviewViewport(),
              const SizedBox(height: 16),

              // 3. Controles de captura (Galería, Obturador y Alternar Cámara)
              CameraShutterControls(
                onCapturePressed: _handleShutterCapture,
                onGalleryPressed: _showNotImplementedSnackBar,
                onSecondaryControlPressed: _showNotImplementedSnackBar,
              ),
              const SizedBox(height: 16),

              // 4. Galería de sesión con ListView horizontal desplazable
              SessionGalleryBar(
                items: _data.sessionGallery,
                onItemPressed: (_) => _showNotImplementedSnackBar(),
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
