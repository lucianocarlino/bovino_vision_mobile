import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_exception.dart';
import '../../../../core/format/formatters.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/api_image.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/feedback.dart';
import '../../data/capture_api.dart';
import '../../data/capture_models.dart';
import '../capture_summary.dart';

/// "Fotos de esta sesión": the photos of the current capture session, newest first.
class SessionGallery extends StatefulWidget {
  const SessionGallery({super.key, required this.sessionId, required this.version, required this.previews});

  final String sessionId;

  /// Changes whenever a capture is added or finishes, to reload the list.
  final int version;

  /// Local copies by capture id (photos taken in this flow); the rest come from the API.
  final Map<String, Uint8List> previews;

  @override
  State<SessionGallery> createState() => _SessionGalleryState();
}

class _SessionGalleryState extends State<SessionGallery> {
  var _captures = <SessionCapture>[];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(SessionGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionId != widget.sessionId || oldWidget.version != widget.version) _load();
  }

  Future<void> _load() async {
    final version = widget.version;
    try {
      final captures = await CaptureApi(context.read<ApiClient>()).sessionCaptures(widget.sessionId);
      if (!mounted || version != widget.version) return;
      setState(() {
        _captures = captures;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted && version == widget.version) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_captures.isEmpty && _error == null) return const SizedBox.shrink();

    final recent = _captures.reversed.toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardHeader(
            title: 'Fotos de esta sesión',
            subtitle: '${_captures.length} ${_captures.length == 1 ? 'captura' : 'capturas'}',
          ),
          if (_error != null) ...[
            Notice(message: 'No pudimos actualizar las fotos de la sesión. $_error', tone: NoticeTone.warning),
            const SizedBox(height: 16),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final capture in recent)
                    SizedBox(
                      width: tileWidth,
                      child: _Tile(capture: capture, preview: widget.previews[capture.id]),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.capture, required this.preview});

  final SessionCapture capture;
  final Uint8List? preview;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = captureStatusBadge(capture.status);
    final reason = capture.failureReason;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ColoredBox(
              color: AppColors.green900,
              child: preview == null
                  ? ApiImage(imageId: capture.imageId)
                  : Image.memory(preview!, fit: BoxFit.cover, semanticLabel: 'Foto de ${capture.animalIdentifier}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capture.animalIdentifier,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral800),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDateTime(capture.capturedAt),
                  style: const TextStyle(fontSize: 11, color: AppColors.neutral500),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppBadge(label: label, tone: tone),
                ),
                if (capture.status == CaptureStatus.failed && reason != null) ...[
                  const SizedBox(height: 4),
                  Text(reason, style: const TextStyle(fontSize: 11, color: AppColors.dangerText)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
