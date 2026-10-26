import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/kpi_tile.dart';
import '../../../core/widgets/page_header.dart';
import '../domain/rodeo_logic.dart';
import 'animal_card.dart';

const _searchDebounce = Duration(milliseconds: 300);

/// Herd list (`ListadoAnimalesPage.tsx`): tiles, search, lot / alert chips and animal cards.
class RodeoScreen extends StatefulWidget {
  const RodeoScreen({super.key});

  @override
  State<RodeoScreen> createState() => _RodeoScreenState();
}

class _RodeoScreenState extends State<RodeoScreen> {
  late final HerdApi _herd = context.read<HerdApi>();
  late final GoRouter _router = GoRouter.of(context);
  bool _awayFromList = false;
  final _searchController = TextEditingController();
  Timer? _searchTimer;

  String _query = '';
  String? _lotId;
  bool _onlyWithAlerts = false;

  List<Animal> _animals = const [];

  /// The whole herd, unfiltered: feeds the tiles whatever the search or the alerts chip say.
  List<Animal> _fullHerd = const [];
  List<Lot> _lots = const [];
  bool _loading = true;
  String? _error;

  /// A newer request makes the response of an older one stale.
  int _requestId = 0;

  bool get _hasFilters => _query.trim().isNotEmpty || _lotId != null || _onlyWithAlerts;

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_onRouteChanged);
    _loadLots();
    _load();
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// The chips and the "% del objetivo" are a nicety: if the lots fail the list still works.
  Future<void> _loadLots() async {
    try {
      final lots = await _herd.lots();
      if (mounted) setState(() => _lots = lots);
    } on ApiException {
      // Keeps whatever lots were already loaded.
    }
  }

  /// Loads the list for the current filters; [silent] keeps the list on screen while refreshing.
  Future<void> _load({bool silent = false}) async {
    final request = ++_requestId;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final animals = await _herd.animals(lotId: _lotId, query: _query, withActiveAlerts: _onlyWithAlerts ? true : null);
      if (!mounted || request != _requestId) return;
      setState(() {
        _animals = animals;
        if (!_hasFilters) _fullHerd = animals;
        _loading = false;
        _error = null;
      });
      if (_hasFilters && (silent || _fullHerd.isEmpty)) unawaited(_loadFullHerd());
    } on ApiException catch (error) {
      if (!mounted || request != _requestId) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadFullHerd() async {
    try {
      final herd = await _herd.animals();
      if (mounted) setState(() => _fullHerd = herd);
    } on ApiException {
      // The tiles are a nicety: they keep their last figures.
    }
  }

  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      _query = text;
      _load();
    });
  }

  void _selectChip({String? lotId, bool alerts = false}) {
    if (_lotId == lotId && _onlyWithAlerts == alerts) return;
    _lotId = lotId;
    _onlyWithAlerts = alerts;
    _load();
  }

  void _clearFilters() {
    _searchTimer?.cancel();
    _searchController.clear();
    _query = '';
    _lotId = null;
    _onlyWithAlerts = false;
    _load();
  }

  void _open(String location) => context.go(location);

  /// The list stays mounted under the animal screens; coming back refreshes it.
  void _onRouteChanged() {
    final path = _router.routerDelegate.currentConfiguration.uri.path;
    if (path != AppRoutes.rodeo) {
      _awayFromList = path.startsWith('${AppRoutes.rodeo}/');
      return;
    }
    if (!_awayFromList) return;
    _awayFromList = false;
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().can(Permissions.herdManage);
    final count = _animals.length;
    final lotsById = {for (final lot in _lots) lot.id: lot};
    final scope = _lotId == null ? _fullHerd : _fullHerd.where((animal) => animal.lotId == _lotId).toList();
    final kpis = herdKpis(HerdSummary.of(scope), lotCode: _lotId == null ? null : lotsById[_lotId]?.code);

    return ListView(
      padding: pagePadding,
      children: [
        PageHeader(title: 'Rodeo', subtitle: '${formatNumber(count)} ${count == 1 ? 'resultado' : 'resultados'}'),
        const SizedBox(height: 24),
        KpiGrid(
          tiles: [for (final kpi in kpis) KpiTile(label: kpi.label, value: kpi.value, detail: kpi.detail)],
        ),
        const SizedBox(height: 24),
        _SearchField(controller: _searchController, onChanged: _onSearchChanged),
        if (canManage) ...[
          const SizedBox(height: 12),
          AppButton(
            label: 'Nuevo animal',
            icon: Icons.add,
            expand: true,
            onPressed: () => _open(AppRoutes.animalNew),
          ),
        ],
        const SizedBox(height: 12),
        _FilterChips(
          lots: _lots,
          selectedLotId: _lotId,
          onlyWithAlerts: _onlyWithAlerts,
          onAll: _clearChip,
          onLot: (id) => _selectChip(lotId: id),
          onAlerts: () => _selectChip(alerts: true),
        ),
        const SizedBox(height: 24),
        if (_error != null) ErrorRetry(message: _error!, onRetry: _load),
        if (_loading && _error == null) const LoadingView(),
        if (!_loading && _error == null && _animals.isEmpty)
          _hasFilters ? _NoMatches(onClear: _clearFilters) : _NoAnimals(canManage: canManage, onAdd: () => _open(AppRoutes.animalNew)),
        if (_error == null)
          for (final animal in _animals) ...[
            AnimalCard(
              animal: animal,
              lot: animal.lotId == null ? null : lotsById[animal.lotId],
              onTap: () => _open(AppRoutes.animal(animal.id)),
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  void _clearChip() => _selectChip();
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Buscar por identificador',
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: AppColors.neutral800),
        decoration: const InputDecoration(
          hintText: 'Buscar por identificador…',
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.neutral800),
        ),
      ),
    );
  }
}

/// "Todos", one chip per lot and "Alertas"; scrolls sideways when the lots do not fit.
class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.lots,
    required this.selectedLotId,
    required this.onlyWithAlerts,
    required this.onAll,
    required this.onLot,
    required this.onAlerts,
  });

  final List<Lot> lots;
  final String? selectedLotId;
  final bool onlyWithAlerts;
  final VoidCallback onAll;
  final ValueChanged<String> onLot;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          AppFilterChip(label: 'Todos', selected: selectedLotId == null && !onlyWithAlerts, onTap: onAll),
          for (final lot in lots) ...[
            const SizedBox(width: 8),
            AppFilterChip(label: lot.label, selected: selectedLotId == lot.id, onTap: () => onLot(lot.id)),
          ],
          const SizedBox(width: 8),
          AppFilterChip(label: 'Alertas', selected: onlyWithAlerts, onTap: onAlerts),
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.pets,
      title: 'Ningún animal coincide con los filtros',
      message: 'Probá con otra búsqueda o quitá los filtros para ver todo el rodeo.',
      action: AppButton(label: 'Quitar filtros', icon: Icons.close, variant: AppButtonVariant.secondary, onPressed: onClear),
    );
  }
}

class _NoAnimals extends StatelessWidget {
  const _NoAnimals({required this.canManage, required this.onAdd});

  final bool canManage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.pets,
      title: 'Todavía no hay animales cargados',
      message: canManage
          ? 'Dá de alta el primero para empezar a registrar sus pesajes.'
          : 'Cuando se den de alta animales, van a aparecer acá.',
      action: canManage ? AppButton(label: 'Dar de alta un animal', icon: Icons.add, onPressed: onAdd) : null,
    );
  }
}
