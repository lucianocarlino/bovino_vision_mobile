import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/rodeo_mock_data.dart';
import 'animal_create_screen.dart';
import 'animal_detail_screen.dart';

/// Pantalla Principal del Rodeo en BovinoVision.
/// Representa la pestaña "Rodeo" del BottomNavigationBar, con
/// buscador de animales interactivo, filtrado/agrupamiento por lote y listado de bovinos registrados.
class RodeoScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final bool autoFocusSearch;

  const RodeoScreen({
    super.key,
    this.initialData,
    this.autoFocusSearch = false,
  });

  @override
  State<RodeoScreen> createState() => _RodeoScreenState();
}

class _RodeoScreenState extends State<RodeoScreen> {
  int _currentNavIndex = 1; // Pestaña "Rodeo" seleccionada por defecto
  String _selectedLoteFilter = 'Todos';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  late bool _isOffline;
  late List<Map<String, dynamic>> _allAnimals;

  @override
  void initState() {
    super.initState();
    _isOffline = widget.initialData?['isOffline'] as bool? ?? RodeoMockData.isOffline;
    _allAnimals = widget.initialData?['animals'] != null
        ? List<Map<String, dynamic>>.from(widget.initialData!['animals'] as List)
        : List<Map<String, dynamic>>.from(RodeoMockData.animals);

    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
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

  List<String> get _availableLotes {
    final lotes = <String>{'Todos'};
    for (final animal in _allAnimals) {
      final loteStr = animal['lote'] as String?;
      if (loteStr != null && loteStr.isNotEmpty) {
        lotes.add('Lote $loteStr');
      }
    }
    return lotes.toList();
  }

  List<Map<String, dynamic>> get _filteredAnimals {
    return _allAnimals.where((animal) {
      final id = (animal['id'] as String? ?? '').toLowerCase();
      final lote = animal['lote'] as String? ?? '';
      final raza = (animal['raza'] as String? ?? '').toLowerCase();

      // Filtro por lote
      final matchesLote = _selectedLoteFilter == 'Todos' ||
          'Lote $lote'.toLowerCase() == _selectedLoteFilter.toLowerCase();

      // Filtro por búsqueda de texto
      final query = _searchQuery.trim().toLowerCase();
      final matchesQuery = query.isEmpty ||
          id.contains(query) ||
          lote.toLowerCase().contains(query) ||
          raza.contains(query);

      return matchesLote && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Rodeo',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppColors.primaryDark,
          ),
        ),
        // Menú superior derecho (avatar/iniciales) eliminado estrictamente según especificación
        actions: const [],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Buscador de animales por identificador SENASA o lote
              _buildSearchBar(),
              const SizedBox(height: 16),

              // 2. Filtros por Lote interactivos (se eliminó el box de alertas y el de totales)
              _buildFilters(),
              const SizedBox(height: 18),

              // 3. Listado agrupado y filtrable de animales
              _buildAnimalList(),
              const SizedBox(height: 80), // Espacio para no solapar el FAB
            ],
          ),
        ),
      ),
      // Botón flotante para "Agregar animal" (ícono add), enlazado con la pantalla de creación
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final nuevoAnimal = await Navigator.of(context).push<Map<String, dynamic>>(
            MaterialPageRoute(
              builder: (context) => AnimalCreateScreen(
                isOffline: _isOffline,
                initialLotes: _availableLotes.where((lote) => lote != 'Todos').toList(),
              ),
            ),
          );

          if (nuevoAnimal != null && mounted) {
            setState(() {
              _allAnimals.insert(0, nuevoAnimal);
            });
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        tooltip: 'Agregar animal',
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          if (index == 1) {
            // Si ya estamos en Rodeo y pulsa la opción del menú, enfoca el buscador de animales
            _searchFocusNode.requestFocus();
            setState(() {
              _currentNavIndex = 1;
            });
            return;
          }

          if (index == 0) {
            // Regresar a la vista de Inicio o navegar si corresponde
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              _showNotImplementedSnackBar(context);
            }
            return;
          }

          // Otras pestañas no implementadas
          _showNotImplementedSnackBar(context);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded, color: AppColors.primary),
            label: 'Rodeo',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded, color: AppColors.primary),
            label: 'Usuarios',
          ),
        ],
      ),
    );
  }

  /// Barra de búsqueda por ID SENASA o lote.
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: widget.autoFocusSearch,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar por ID SENASA o lote...',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }

  /// Barra horizontal de chips de filtrado por Lote (el box de alertas fue eliminado).
  Widget _buildFilters() {
    final lotes = _availableLotes;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...lotes.map((lote) {
            final isSelected = _selectedLoteFilter == lote;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(lote),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedLoteFilter = selected ? lote : 'Todos';
                  });
                },
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.18),
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.border,
                ),
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                showCheckmark: false,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Lista de animales, filtrable y agrupada por lote.
  Widget _buildAnimalList() {
    final animals = _filteredAnimals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Animales',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${animals.length} resultados · orden: último pesaje',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (animals.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(
                  Icons.pets_rounded,
                  size: 40,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No se encontraron animales para este filtro',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: animals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildAnimalCard(animals[index]);
            },
          ),
      ],
    );
  }

  /// Tarjeta individual de un animal con toda la información visible en el mockup:
  /// Identificador, raza, lote, estado y último peso registrado.
  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final id = animal['id'] as String? ?? 'S/ID';
    final lote = animal['lote'] as String? ?? '-';
    final raza = animal['raza'] as String? ?? 'Bovino';
    final peso = animal['peso'] as String? ?? '-';
    final estado = animal['estado'] as String? ?? 'Normal';
    final imagen = animal['imagen'] as String? ?? '';

    final isOptimo = estado.toLowerCase() == 'óptimo' || estado.toLowerCase() == 'optimo';

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AnimalDetailScreen(
              isOffline: _isOffline,
              animalDetail: {
                "id": id,
                "raza": raza,
                "sexo": animal['sexo'] ?? "Macho",
                "edad": animal['edad'] ?? "24 meses",
                "lote": "$lote",
                "nacimiento": animal['nacimiento'] ?? "15 mar 2022",
                "ultimoPeso": peso,
                "imagen": imagen,
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Miniatura fotográfica o avatar ilustrativo
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: AppColors.surfaceMuted,
                child: Image.asset(
                  imagen,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.pets_rounded,
                        color: AppColors.primaryLight.withValues(alpha: 0.8),
                        size: 26,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Metadatos centrales del animal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          lote,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          raza,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOptimo ? AppColors.onlineLight : AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: isOptimo ? AppColors.online : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estado,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOptimo ? AppColors.online : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Peso y flecha de navegación a detalle
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  peso,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
