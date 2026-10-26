import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/data/herd_api.dart';
import '../../../core/network/connectivity_service.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_header.dart';
import 'capture_flow_controller.dart';
import 'capture_summary.dart';
import 'widgets/estimating_step.dart';
import 'widgets/identify_step.dart';
import 'widgets/photo_step.dart';
import 'widgets/result_step.dart';
import 'widgets/session_gallery.dart';

/// Capture wizard: Animal, Foto, Estimación, Resultado. With [animalId] the animal is
/// preloaded and the first step is skipped.
class CaptureFlowScreen extends StatefulWidget {
  const CaptureFlowScreen({super.key, this.animalId});

  final String? animalId;

  @override
  State<CaptureFlowScreen> createState() => _CaptureFlowScreenState();
}

class _CaptureFlowScreenState extends State<CaptureFlowScreen> {
  late final CaptureFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CaptureFlowController(client: context.read<ApiClient>(), herd: context.read<HerdApi>());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Offline nothing is started; the flow begins as soon as the connection is back.
    if (Provider.of<ConnectivityService>(context).isOnline) _controller.start(animalId: widget.animalId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _backToHome() async {
    if (!await _controller.leave() || !mounted) return;
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.capture);
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => ListView(
        padding: pagePadding,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Inicio de captura',
              icon: Icons.arrow_back,
              variant: AppButtonVariant.ghost,
              onPressed: _controller.loading ? null : _backToHome,
            ),
          ),
          const SizedBox(height: 12),
          const PageHeader(title: 'Nueva captura', subtitle: 'Registrá el peso de un animal con una foto.'),
          const SizedBox(height: 24),
          if (!online) ...[
            const Notice(
              title: 'Sin conexión',
              message: 'Necesitás conexión para sacar fotos y enviarlas. Conectate y volvé a intentar.',
              tone: NoticeTone.warning,
            ),
            const SizedBox(height: 16),
          ],
          ..._content(online),
        ],
      ),
    );
  }

  List<Widget> _content(bool online) {
    final sessionId = _controller.sessionId;
    if (sessionId == null) {
      if (!online) return const [];
      final error = _controller.error;
      return [
        error == null
            ? const LoadingView(label: 'Iniciando sesión de captura…')
            : Notice(message: error, tone: NoticeTone.danger),
      ];
    }

    final (stage, body) = _stage(online);
    final result = _controller.result;
    // An estimated result brings its own "Tomar otra" and "Tomar otra foto" actions.
    final back = stage == 4 && (result?.isEstimated ?? false) ? null : _controller.back;

    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepIndicator(current: stage, total: 4),
            const SizedBox(height: 24),
            body,
            if (back != null) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: back.label,
                  icon: Icons.arrow_back,
                  variant: AppButtonVariant.ghost,
                  onPressed: _controller.loading ? null : _controller.goBack,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      SessionGallery(sessionId: sessionId, version: _controller.galleryVersion, previews: _controller.previews),
    ];
  }

  /// Number of the current step (1 to 4) and its content.
  (int, Widget) _stage(bool online) {
    final animal = _controller.animal;
    final result = _controller.result;

    if (_controller.step == CaptureStep.result && result != null) {
      return (
        4,
        ResultStep(
          result: result,
          animal: animal,
          loading: _controller.loading,
          online: online,
          error: _controller.error,
          onConfirm: _controller.confirm,
          onNextAnimal: _controller.nextAnimal,
          onAnotherPhoto: _controller.goBack,
        ),
      );
    }

    if (animal == null || _controller.step == CaptureStep.identify) {
      if (_controller.openingAnimal) return (1, const LoadingView(label: 'Abriendo el animal…'));
      final error = _controller.error;
      return (
        1,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IdentifyStep(onSelect: _controller.selectAnimal),
            if (error != null) ...[const SizedBox(height: 16), Notice(message: error, tone: NoticeTone.danger)],
          ],
        ),
      );
    }

    if (_controller.step == CaptureStep.processing) {
      return (
        3,
        EstimatingStep(
          animal: animal,
          capture: _controller.capture,
          error: _controller.error,
          onRetry: _controller.retryPolling,
        ),
      );
    }

    return (
      2,
      PhotoStep(
        animal: animal,
        capture: _controller.capture,
        preview: _controller.preview,
        loading: _controller.loading,
        removing: _controller.removingPhoto,
        online: online,
        notice: _controller.notice,
        error: _controller.error,
        onPick: _controller.takePhoto,
        onRetry: _controller.retryPhoto,
        onRemove: _controller.removePhoto,
        onProcess: _controller.requestWeighing,
      ),
    );
  }
}
