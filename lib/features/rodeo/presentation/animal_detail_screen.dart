import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/auth/session.dart';
import '../../../core/data/herd_api.dart';
import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/kpi_tile.dart';
import '../../../core/widgets/line_chart.dart';
import '../../../core/widgets/page_header.dart';
import '../../alerts/alert_texts.dart';
import '../data/rodeo_api.dart';
import '../domain/rodeo_logic.dart';
import 'animal_form.dart';
import 'weighing_timeline.dart';

/// Animal file (`FichaAnimalPage.tsx`): data, KPIs, alerts, growth curve, weighings and lot history.
class AnimalDetailScreen extends StatefulWidget {
  const AnimalDetailScreen({super.key, required this.animalId});

  final String animalId;

  @override
  State<AnimalDetailScreen> createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  late final HerdApi _herd = context.read<HerdApi>();
  late final RodeoApi _rodeo = RodeoApi(context.read<ApiClient>());

  Animal? _animal;
  List<Weighing> _weighings = const [];
  List<Alert> _alerts = const [];
  List<LotAssignment> _assignments = const [];
  String? _error;

  /// Form state while editing; null when the edit card is closed.
  AnimalFormValue? _edit;
  List<Breed> _breeds = const [];
  List<Lot> _lots = const [];
  bool _loadingCatalogs = false;
  bool _saving = false;
  String? _editError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final id = widget.animalId;
      final results = await Future.wait<Object>([
        _herd.animal(id),
        _rodeo.weighings(id),
        _herd.animalAlerts(id),
        _rodeo.lotHistory(id),
      ]);
      final animal = results[0] as Animal;
      final weighings = results[1] as List<Weighing>;
      final alerts = results[2] as List<Alert>;
      final assignments = results[3] as List<LotAssignment>;
      if (!mounted) return;
      setState(() {
        _animal = animal;
        _weighings = weighings;
        _alerts = alerts;
        _assignments = assignments;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _startEdit() async {
    final animal = _animal!;
    setState(() {
      _edit = AnimalFormValue.of(animal);
      _editError = null;
      _loadingCatalogs = true;
    });
    try {
      // Future.wait rethrows the first ApiException as is; record `.wait` would wrap it.
      final results = await Future.wait<Object>([_herd.breeds(), _herd.lots()]);
      final breeds = results[0] as List<Breed>;
      final lots = results[1] as List<Lot>;
      if (!mounted) return;
      setState(() {
        _breeds = breeds;
        _lots = lots;
        _loadingCatalogs = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _editError = error.message;
        _loadingCatalogs = false;
      });
    }
  }

  Future<void> _saveEdit() async {
    final animal = _animal!;
    final changes = _edit!.changesFrom(AnimalFormValue.of(animal));
    if (changes.isEmpty) {
      setState(() => _edit = null);
      return;
    }
    setState(() {
      _saving = true;
      _editError = null;
    });
    try {
      final updated = await _rodeo.updateAnimal(animal.id, changes);
      final assignments = changes.lotId == null ? _assignments : await _rodeo.lotHistory(animal.id);
      if (!mounted) return;
      setState(() {
        _animal = updated;
        _assignments = assignments;
        _edit = null;
        _saving = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _editError = error.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final animal = _animal;
    if (_error != null) {
      return ListView(
        padding: pagePadding,
        children: [const BackLink(), const SizedBox(height: 16), ErrorRetry(message: _error!, onRetry: _load)],
      );
    }
    if (animal == null) {
      return ListView(padding: pagePadding, children: const [BackLink(), LoadingView()]);
    }

    final auth = context.watch<AuthController>();
    final canWeigh = auth.can(Permissions.captureRecord);
    final canManage = auth.can(Permissions.herdManage);
    final weighBack = canWeigh ? _WeighButton(animalId: animal.id) : null;

    return ListView(
      padding: pagePadding,
      children: [
        const BackLink(),
        const SizedBox(height: 8),
        PageHeader(title: animal.identifier, subtitle: animalSubtitle(animal)),
        if (canWeigh || (canManage && _edit == null)) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ?weighBack,
              if (canManage && _edit == null)
                AppButton(label: 'Editar datos', icon: Icons.edit_outlined, variant: AppButtonVariant.secondary, onPressed: _startEdit),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (index, chip) in animalChips(animal).indexed)
              AppBadge(label: chip, tone: index == 0 ? BadgeTone.earth : BadgeTone.neutral),
          ],
        ),
        const SizedBox(height: 24),
        if (canManage && _edit != null) ...[_editCard(animal), const SizedBox(height: 24)],
        _kpis(),
        const SizedBox(height: 24),
        _alertNotices(),
        const SizedBox(height: 24),
        AppCard(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'Curva de crecimiento', subtitle: 'Peso estimado en cada pesaje'),
              LineChartView(
                labels: [for (final w in _weighings.reversed) formatShortDate(w.weighedAt)],
                series: [ChartSeries(name: 'Peso', values: [for (final w in _weighings.reversed) w.weightKg])],
                formatValue: (value) => formatKg(value, 1),
                formatAxis: formatKg,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CardHeader(title: 'Registro cronológico de pesajes', subtitle: 'Del más reciente al más antiguo'),
              if (_weighings.isEmpty)
                EmptyState(icon: Icons.monitor_weight_outlined, title: 'Todavía no tiene pesajes registrados', action: weighBack)
              else
                WeighingTimeline(weighings: _weighings),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _lotHistory(),
      ],
    );
  }

  Widget _kpis() {
    // The history only holds weighing events, newest first.
    final latest = _weighings.isEmpty ? null : _weighings[0];
    final previous = _weighings.length > 1 ? _weighings[1] : null;
    final delta = latest != null && previous != null ? latest.weightKg - previous.weightKg : null;
    final gmd = latest?.gmdKgPerDay;
    return KpiGrid(
      tiles: [
        KpiTile(label: 'Último pesaje', value: latest != null ? formatKg(latest.weightKg, 1) : '—'),
        KpiTile(
          label: 'Variación vs. anterior',
          value: delta != null ? '${delta > 0 ? '+' : ''}${formatKg(delta, 1)}' : '—',
          danger: delta != null && delta < 0,
        ),
        KpiTile(
          label: 'GMD del último intervalo',
          value: gmd != null ? formatGmd(gmd) : '—',
          danger: gmd != null && gmd < 0,
        ),
        KpiTile(label: 'Pesajes', value: formatNumber(_weighings.length)),
      ],
    );
  }

  Widget _alertNotices() {
    // The API also returns resolved alerts; only the active ones are shown.
    final active = _alerts.where((alert) => alert.active).toList();
    PriorityLevel levelOf(Alert alert) => PriorityLevel.of(alert.priority);
    if (active.isEmpty) return const Notice(message: 'Este animal no tiene alertas activas.', tone: NoticeTone.success);
    return Column(
      children: [
        for (final (index, alert) in active.indexed) ...[
          if (index > 0) const SizedBox(height: 8),
          Notice(
            tone: levelOf(alert) == PriorityLevel.high ? NoticeTone.danger : NoticeTone.warning,
            message: '${describeAlert(alert)} · prioridad ${levelOf(alert).label} · ${formatDate(alert.createdAt)}',
          ),
        ],
      ],
    );
  }

  Widget _lotHistory() {
    return AppCard(
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(title: 'Historial de lotes', subtitle: 'Cada pesaje se asocia al lote vigente en su fecha'),
          if (_assignments.isEmpty)
            const Text('Nunca estuvo asignado a un lote.', style: TextStyle(fontSize: 14, color: AppColors.neutral500))
          else
            for (final (index, assignment) in _assignments.indexed) ...[
              if (index > 0) const SizedBox(height: 8),
              _AssignmentRow(assignment: assignment),
            ],
        ],
      ),
    );
  }

  Widget _editCard(Animal animal) {
    return AppCard(
      padding: cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeader(
            title: 'Editar datos del animal',
            subtitle: 'Un dato ya cargado se puede cambiar, pero no dejar vacío.',
          ),
          if (_loadingCatalogs)
            const LoadingView()
          else
            AnimalFields(
              value: _edit!,
              onChanged: (value) => setState(() => _edit = value),
              breeds: _breeds,
              lots: _lots,
              original: AnimalFormValue.of(animal),
            ),
          if (_editError != null) ...[
            const SizedBox(height: 16),
            Notice(message: _editError!, tone: NoticeTone.danger),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: _saving ? 'Guardando…' : 'Guardar cambios',
                onPressed: _loadingCatalogs ? null : _saveEdit,
                loading: _saving,
              ),
              AppButton(
                label: 'Cancelar',
                variant: AppButtonVariant.ghost,
                onPressed: _saving ? null : () => setState(() => _edit = null),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Pesar este animal": opens the capture wizard with the animal already identified.
class _WeighButton extends StatelessWidget {
  const _WeighButton({required this.animalId});

  final String animalId;

  @override
  Widget build(BuildContext context) => AppButton(
        label: 'Pesar este animal',
        icon: Icons.scale_outlined,
        onPressed: () => context.go(AppRoutes.captureFor(animalId)),
      );
}

class _AssignmentRow extends StatelessWidget {
  const _AssignmentRow({required this.assignment});

  final LotAssignment assignment;

  @override
  Widget build(BuildContext context) {
    final until = assignment.until;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            'Lote ${assignment.lotCode}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
          ),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${formatDate(assignment.since)} – ${until != null ? formatDate(until) : 'hoy'}',
                style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
              ),
              if (until == null) const AppBadge(label: 'Vigente', tone: BadgeTone.brand),
            ],
          ),
        ],
      ),
    );
  }
}
