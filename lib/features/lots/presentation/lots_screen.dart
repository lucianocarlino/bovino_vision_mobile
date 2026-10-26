import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/session.dart';
import '../../../core/data/herd_api.dart';
import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_header.dart';
import '../data/lots_api.dart';
import '../domain/lot_form.dart';

/// Lots (`ListadoLotesPage.tsx` on phones): create form, rows with share of the herd and
/// target GMD, and inline editing. Creating and editing need `rodeo_gestionar`.
class LotsScreen extends StatefulWidget {
  const LotsScreen({super.key});

  @override
  State<LotsScreen> createState() => _LotsScreenState();
}

class _LotsScreenState extends State<LotsScreen> {
  late final HerdApi _herd = context.read<HerdApi>();
  late final LotsApi _lotsApi = LotsApi(context.read<ApiClient>());
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _target = TextEditingController();

  List<Lot> _lots = const [];
  bool _loading = true;
  String? _loadError;
  String? _createError;
  bool _creating = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _lots.isEmpty;
      _loadError = null;
    });
    try {
      final lots = await _herd.lots();
      if (!mounted) return;
      setState(() {
        _lots = lots;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final code = _code.text.trim();
    if (code.isEmpty) return;
    final target = parseGmdTarget(_target.text);
    if (target.error != null) {
      setState(() => _createError = target.error);
      return;
    }
    setState(() {
      _creating = true;
      _createError = null;
    });
    try {
      await _herd.createLot(code: code, name: _name.text, gmdTarget: target.value);
      if (!mounted) return;
      _code.clear();
      _name.clear();
      _target.clear();
      setState(() => _creating = false);
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _createError = error.message;
        _creating = false;
      });
    }
  }

  /// Saves the edit of [lot]; returns the error to show in the form, or null when it is done.
  Future<String?> _saveEdit(Lot lot, String name, String gmdText) async {
    final changes = lotChanges(lot, name: name, gmdText: gmdText);
    if (changes.error != null) return changes.error;
    if (changes.name == null && changes.gmdTarget == null) {
      setState(() => _editingId = null);
      return null;
    }
    try {
      final updated = await _lotsApi.updateLot(lot.id, name: changes.name, gmdTarget: changes.gmdTarget);
      if (!mounted) return null;
      setState(() {
        _lots = [for (final item in _lots) item.id == updated.id ? updated : item];
        _editingId = null;
      });
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().can(Permissions.herdManage);
    final total = _lots.fold(0, (sum, lot) => sum + lot.animalCount);

    return ListView(
      padding: pagePadding,
      children: [
        PageHeader(title: 'Lotes', subtitle: '${formatNumber(_lots.length)} ${_lots.length == 1 ? 'lote' : 'lotes'}'),
        const SizedBox(height: 24),
        if (canManage) ...[_createCard(), const SizedBox(height: 24)],
        if (_loadError != null) ErrorRetry(message: _loadError!, onRetry: _load),
        if (_loading) const LoadingView(),
        if (!_loading && _loadError == null && _lots.isEmpty)
          EmptyState(
            icon: Icons.grid_view_outlined,
            title: 'No hay lotes creados todavía',
            message: canManage
                ? 'Creá el primero con su código para empezar a agrupar el rodeo.'
                : 'Todavía no se creó ningún lote.',
          ),
        for (final lot in _lots) ...[
          if (canManage && _editingId == lot.id)
            _LotEditForm(
              key: ValueKey('edit-${lot.id}'),
              lot: lot,
              onSave: (name, gmd) => _saveEdit(lot, name, gmd),
              onCancel: () => setState(() => _editingId = null),
            )
          else
            _LotRow(
              lot: lot,
              share: total > 0 ? lot.animalCount / total : 0,
              onEdit: canManage ? () => setState(() => _editingId = lot.id) : null,
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _createCard() {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FieldLabel('Código de lote'),
          TextField(
            controller: _code,
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Por ejemplo, A1'),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('Nombre (opcional)'),
          TextField(
            controller: _name,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'Por ejemplo, Recría'),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('GMD objetivo, kg/día (opcional)'),
          TextField(
            controller: _target,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Por ejemplo, 0,8'),
          ),
          if (_createError != null) ...[
            const SizedBox(height: 12),
            Notice(message: _createError!, tone: NoticeTone.danger),
          ],
          const SizedBox(height: 12),
          AppButton(
            label: 'Crear lote',
            icon: Icons.add,
            loading: _creating,
            onPressed: _code.text.trim().isEmpty ? null : _create,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
      );
}

/// One lot as a bordered card: the table row of the web app, stacked as on phones.
class _LotRow extends StatelessWidget {
  const _LotRow({required this.lot, required this.share, required this.onEdit});

  final Lot lot;

  /// Fraction of the herd that is in this lot.
  final double share;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(lot.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral800)),
          const SizedBox(height: 8),
          _Cell(label: 'Nombre', value: lot.name ?? 'Sin nombre', muted: true),
          const SizedBox(height: 8),
          _Cell(label: 'Animales', value: formatNumber(lot.animalCount), bold: true),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: share.clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: AppColors.neutral100,
                    color: AppColors.green500,
                    semanticsLabel: 'Participación del lote ${lot.code}',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Text(
                  formatPercent(share),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Cell(label: 'GMD objetivo', value: gmdTargetLabel(lot.gmdTarget), muted: true),
          if (onEdit != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppButton(label: 'Editar', icon: Icons.edit_outlined, variant: AppButtonVariant.ghost, onPressed: onEdit),
            ),
          ],
        ],
      ),
    );
  }
}

/// Value prefixed by its uppercase column name, as the web app shows table cells on phones.
class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.value, this.muted = false, this.bold = false});

  final String label;
  final String value;
  final bool muted;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${label.toUpperCase()} ',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.neutral400),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: muted ? AppColors.neutral500 : AppColors.neutral800,
            ),
          ),
        ],
      ),
    );
  }
}

class _LotEditForm extends StatefulWidget {
  const _LotEditForm({super.key, required this.lot, required this.onSave, required this.onCancel});

  final Lot lot;

  /// Returns the error to show, or null when the edit is done.
  final Future<String?> Function(String name, String gmdText) onSave;
  final VoidCallback onCancel;

  @override
  State<_LotEditForm> createState() => _LotEditFormState();
}

class _LotEditFormState extends State<_LotEditForm> {
  late final _name = TextEditingController(text: widget.lot.name ?? '');
  late final _target = TextEditingController(text: gmdTargetText(widget.lot.gmdTarget));
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onSave(_name.text, _target.text);
    // On success the parent replaces this form, so only a failure leaves it on screen.
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.green300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Editar lote ${widget.lot.code}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral800),
          ),
          const SizedBox(height: 12),
          const _FieldLabel('Nombre'),
          TextField(controller: _name, textInputAction: TextInputAction.next),
          const SizedBox(height: 12),
          const _FieldLabel('GMD objetivo (kg/día)'),
          TextField(controller: _target, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          const SizedBox(height: 12),
          const Text(
            'Un dato ya cargado se puede cambiar, pero no dejar vacío.',
            style: TextStyle(fontSize: 11, color: AppColors.neutral500),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Notice(message: _error!, tone: NoticeTone.danger),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(label: 'Guardar cambios', loading: _saving, onPressed: _submit),
              AppButton(label: 'Cancelar', variant: AppButtonVariant.ghost, onPressed: _saving ? null : widget.onCancel),
            ],
          ),
        ],
      ),
    );
  }
}
