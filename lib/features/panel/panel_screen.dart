import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/session.dart';
import '../../core/data/herd_api.dart';
import '../../core/data/herd_models.dart';
import '../../core/format/formatters.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_badge.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/brand.dart';
import '../../core/widgets/feedback.dart';
import '../../core/widgets/kpi_tile.dart';
import '../../core/widgets/line_chart.dart';
import '../../core/widgets/page_header.dart';
import '../alerts/alert_card.dart';
import '../alerts/alert_texts.dart';
import 'panel_api.dart';

const _featuredAlerts = 3;
const _noData = '—';

String _kg(double? value) => value == null ? _noData : formatKg(value, 1);
String _gmd(double? value) => value == null ? _noData : '${formatNumber(value, 2)} kg/día';
String _isoDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// "1.248 cabezas en 6 lotes · datos al 24 may".
String panelSubtitle({required int heads, required int lots, String? lotCode, String? lastDate}) {
  final headsText = '${formatNumber(heads)} ${heads == 1 ? 'cabeza' : 'cabezas'}';
  final where = lotCode != null ? 'el lote $lotCode' : '${formatNumber(lots)} ${lots == 1 ? 'lote' : 'lotes'}';
  final base = '$headsText en $where';
  return lastDate == null ? base : '$base · datos al ${formatShortDate(lastDate)}';
}

/// Herd dashboard (`src/features/panel/PanelPage.tsx`), phone layout.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});

  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  late final _panelApi = PanelApi(context.read<ApiClient>());
  late final _herdApi = context.read<HerdApi>();

  String? _lotId;
  List<Lot>? _lots;
  String? _lotsError;
  PanelData? _panel;
  List<Alert> _alerts = const [];
  String? _error;
  int _request = 0;

  DateTime? _from;
  DateTime? _to;
  PeriodReport? _report;
  String? _reportError;
  bool _reportLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLots();
    _loadPanel();
  }

  Future<void> _loadLots() async {
    try {
      final lots = await _herdApi.lots();
      if (mounted) setState(() => _lots = lots);
    } on ApiException catch (error) {
      if (mounted) setState(() => _lotsError = error.message);
    }
  }

  /// The alerts endpoint has no lot filter: within a lot, keep the alerts of its animals.
  Future<List<Alert>> _activeAlerts(String? lotId) async {
    final alerts = await _herdApi.activeAlerts();
    if (lotId == null) return alerts;
    final animals = await _herdApi.animals(lotId: lotId, withActiveAlerts: true);
    final ids = animals.map((a) => a.id).toSet();
    return alerts.where((a) => ids.contains(a.animalId)).toList();
  }

  Future<void> _loadPanel() async {
    final request = ++_request;
    final lotId = _lotId;
    setState(() {
      _panel = null;
      _error = null;
    });
    try {
      final panel = await _panelApi.panel(lotId: lotId);
      final alerts = await _activeAlerts(lotId);
      // A newer lot filter makes this response stale.
      if (!mounted || request != _request) return;
      setState(() {
        _panel = panel;
        _alerts = alerts;
      });
    } on ApiException catch (error) {
      if (mounted && request == _request) setState(() => _error = error.message);
    }
  }

  void _filterByLot(String? lotId) {
    setState(() {
      _lotId = lotId;
      // A report from another scope would be misleading.
      _report = null;
      _reportError = null;
    });
    _loadPanel();
  }

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1),
    );
    if (picked == null) return;
    setState(() => from ? _from = picked : _to = picked);
  }

  Future<void> _generateReport() async {
    if (_from == null || _to == null) {
      setState(() => _reportError = 'Elegí las dos fechas del período.');
      return;
    }
    setState(() {
      _reportLoading = true;
      _reportError = null;
    });
    try {
      final report = await _panelApi.report(from: _isoDate(_from!), to: _isoDate(_to!), lotId: _lotId);
      if (mounted) setState(() => _report = report);
    } on ApiException catch (error) {
      if (mounted) setState(() => _reportError = error.message);
    } finally {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = _panel;
    final lots = _lots;
    final selectedLot = lots?.where((lot) => lot.id == _lotId).firstOrNull;
    final scope = selectedLot != null ? 'del lote ${selectedLot.code}' : 'del rodeo';
    final points = panel?.evolution.where((p) => p.averageWeightKg != null).toList() ?? const <EvolutionPoint>[];
    final subtitle = panel != null && lots != null
        ? panelSubtitle(
            heads: panel.animalCount,
            lots: lots.length,
            lotCode: selectedLot?.code,
            lastDate: points.isEmpty ? null : points.last.date,
          )
        : 'Peso, ganancia diaria y alertas del rodeo en un vistazo.';

    return RefreshIndicator(
      onRefresh: _loadPanel,
      child: ListView(
        padding: pagePadding,
        children: [
          PageHeader(title: 'Panel del rodeo', subtitle: subtitle),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _lotId,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Todo el rodeo')),
              for (final lot in lots ?? const <Lot>[]) DropdownMenuItem<String?>(value: lot.id, child: Text(lot.label)),
            ],
            onChanged: _filterByLot,
          ),
          const SizedBox(height: 24),
          if (_error != null)
            ErrorRetry(message: _error!, onRetry: _loadPanel)
          else if (panel == null)
            const LoadingView()
          else
            ..._content(panel, points, selectedLot, scope),
        ],
      ),
    );
  }

  List<Widget> _content(PanelData panel, List<EvolutionPoint> points, Lot? selectedLot, String scope) {
    final target = targetCurve(points, selectedLot?.gmdTarget);
    final alertCount = _alerts.length;
    final coverage = panel.animalCount > 0 ? panel.animalsWithGmd / panel.animalCount : 0.0;
    final canResolve = context.watch<AuthController>().can(Permissions.herdManage);

    return [
      KpiGrid(tiles: [
        KpiTile(label: 'Animales', value: formatNumber(panel.animalCount)),
        KpiTile(label: 'Peso promedio', value: _kg(panel.averageWeightKg)),
        KpiTile(label: 'GMD promedio', value: _gmd(panel.averageGmd)),
        KpiTile(label: 'Animales con GMD', value: formatNumber(panel.animalsWithGmd)),
        KpiTile(label: 'Alertas activas', value: formatNumber(alertCount), danger: alertCount > 0),
      ]),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeader(
              title: 'Evolución de peso promedio',
              subtitle: target != null && selectedLot != null
                  ? 'Real contra objetivo del lote ${selectedLot.code}'
                  : 'Promedio $scope en cada fecha de pesaje',
            ),
            if (target != null) ...[
              const ChartLegend(items: [('Real', SeriesTone.brand), ('Objetivo', SeriesTone.earth)]),
              const SizedBox(height: 12),
            ],
            LineChartView(
              labels: [for (final p in points) formatShortDate(p.date)],
              series: [
                ChartSeries(name: target != null ? 'Real' : 'Peso promedio', values: [for (final p in points) p.averageWeightKg]),
                if (target != null) ChartSeries(name: 'Objetivo', tone: SeriesTone.earth, values: target),
              ],
              formatValue: (value) => formatKg(value, 1),
              formatAxis: (value) => formatKg(value),
            ),
            const SizedBox(height: 16),
            _LinkStrip(label: 'Ver animales del rodeo', onTap: () => context.go(AppRoutes.rodeo)),
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeader(
              title: 'Alertas críticas',
              subtitle: 'Las más urgentes $scope',
              trailing: alertCount > 0 ? AppBadge(label: formatNumber(alertCount), tone: BadgeTone.danger) : null,
            ),
            if (alertCount == 0)
              const Row(
                children: [
                  Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.green600),
                  SizedBox(width: 8),
                  Text('No hay alertas activas.', style: TextStyle(fontSize: 14, color: AppColors.neutral500)),
                ],
              )
            else ...[
              for (final alert in featuredAlerts(_alerts, _featuredAlerts)) ...[
                AlertCard(
                  key: ValueKey(alert.id),
                  alert: alert,
                  canResolve: canResolve,
                  onResolved: (id) => setState(() => _alerts = _alerts.where((a) => a.id != id).toList()),
                ),
                const SizedBox(height: 12),
              ],
              _LinkStrip(label: seeAlertsText(alertCount), onTap: () => context.go(AppRoutes.alerts)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardHeader(title: 'Composición del rodeo', subtitle: 'Cobertura de GMD y reparto por lote'),
            ProgressBarView(
              value: coverage,
              label: '${formatNumber(panel.animalsWithGmd)} de ${formatNumber(panel.animalCount)} animales con GMD',
              caption: formatPercent(coverage),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.layers_outlined, size: 18, color: AppColors.green600),
                SizedBox(width: 8),
                Text(
                  'Animales por lote',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.neutral800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lotsError != null)
              Notice(message: 'No pudimos cargar los lotes. $_lotsError', tone: NoticeTone.warning)
            else if (_lots == null)
              const LoadingView()
            else
              _LotDistribution(lots: _lots!, total: panel.animalCount),
          ],
        ),
      ),
      const SizedBox(height: 24),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeader(title: 'Reporte por período', subtitle: 'Pesajes y ganancia de peso $scope entre dos fechas'),
            _DateField(label: 'Desde', value: _from, onTap: () => _pickDate(from: true)),
            const SizedBox(height: 16),
            _DateField(label: 'Hasta', value: _to, onTap: () => _pickDate(from: false)),
            const SizedBox(height: 16),
            AppButton(label: 'Generar', expand: true, loading: _reportLoading, onPressed: _generateReport),
            if (_reportError != null) ...[
              const SizedBox(height: 16),
              Notice(message: _reportError!, tone: NoticeTone.danger),
            ],
            if (_report != null) ...[
              const SizedBox(height: 24),
              KpiGrid(tiles: [
                KpiTile(label: 'Pesajes en el período', value: formatNumber(_report!.weighings)),
                KpiTile(label: 'Animales pesados', value: formatNumber(_report!.animals)),
                KpiTile(label: 'Peso promedio', value: _kg(_report!.averageWeightKg)),
                KpiTile(label: 'GMD promedio', value: _gmd(_report!.averageGmd)),
              ]),
            ],
          ],
        ),
      ),
    ];
  }
}

class _LinkStrip extends StatelessWidget {
  const _LinkStrip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.neutral100,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.neutral800)),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.neutral500),
            ],
          ),
        ),
      ),
    );
  }
}

class _LotDistribution extends StatelessWidget {
  const _LotDistribution({required this.lots, required this.total});

  final List<Lot> lots;
  final int total;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final lot in lots)
        (key: lot.id, name: lot.name != null ? '${lot.code} · ${lot.name}' : lot.code, animals: lot.animalCount, target: lot.gmdTarget),
    ];
    final withoutLot = total - lots.fold<int>(0, (sum, lot) => sum + lot.animalCount);
    if (withoutLot > 0) rows.add((key: 'sin-lote', name: 'Sin lote', animals: withoutLot, target: null));

    if (total == 0 || rows.isEmpty) {
      return const Text(
        'Todavía no hay animales para repartir por lote.',
        style: TextStyle(fontSize: 14, color: AppColors.neutral500),
      );
    }

    const headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.neutral400);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows) ...[
          ProgressBarView(
            value: row.animals / total,
            label: row.name,
            caption: formatPercent(row.animals / total),
            earth: row.key == 'sin-lote',
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 4),
        Table(
          columnWidths: const {0: FlexColumnWidth(2), 1: IntrinsicColumnWidth(), 2: IntrinsicColumnWidth(), 3: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(children: [
              Padding(padding: EdgeInsets.only(bottom: 8), child: Text('LOTE', style: headerStyle)),
              Padding(padding: EdgeInsets.only(left: 8, bottom: 8), child: Text('ANIMALES', textAlign: TextAlign.right, style: headerStyle)),
              Padding(padding: EdgeInsets.only(left: 8, bottom: 8), child: Text('%', textAlign: TextAlign.right, style: headerStyle)),
              Padding(padding: EdgeInsets.only(left: 8, bottom: 8), child: Text('GMD OBJETIVO', textAlign: TextAlign.right, style: headerStyle)),
            ]),
            for (final row in rows)
              TableRow(
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.neutral200))),
                children: [
                  _cell(row.name, color: AppColors.neutral800, left: false),
                  _cell(formatNumber(row.animals), color: AppColors.neutral800, bold: true),
                  _cell(formatPercent(row.animals / total)),
                  _cell(_gmd(row.target)),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _cell(String text, {Color color = AppColors.neutral600, bool bold = false, bool left = true}) => Padding(
        padding: EdgeInsets.only(left: left ? 8 : 0, top: 8, bottom: 8),
        child: Text(
          text,
          textAlign: left ? TextAlign.right : TextAlign.left,
          style: TextStyle(fontSize: 13, color: color, fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
        ),
      );
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InputDecorator(
            decoration: const InputDecoration(suffixIcon: Icon(Icons.calendar_today_outlined, size: 18)),
            child: Text(
              value == null ? 'dd/mm/aaaa' : formatDate(_isoDate(value!)),
              style: TextStyle(fontSize: 14, color: value == null ? AppColors.neutral400 : AppColors.neutral800),
            ),
          ),
        ),
      ],
    );
  }
}
