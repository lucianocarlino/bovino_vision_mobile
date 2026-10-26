import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/api_exception.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../core/auth/session.dart';
import '../../../../core/data/herd_api.dart';
import '../../../../core/data/herd_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/feedback.dart';
import 'step_title.dart';

/// Step 1: find the animal by tag, or register it when the operator may.
class IdentifyStep extends StatefulWidget {
  const IdentifyStep({super.key, required this.onSelect});

  final ValueChanged<Animal> onSelect;

  @override
  State<IdentifyStep> createState() => _IdentifyStepState();
}

class _IdentifyStepState extends State<IdentifyStep> {
  var _query = '';
  var _results = <Animal>[];
  var _searching = false;
  var _registering = false;
  String? _error;

  // Responses can arrive out of order while typing; only the latest search is shown.
  var _lastSearch = 0;

  Future<void> _search(String text) async {
    final search = ++_lastSearch;
    setState(() => _query = text);
    if (text.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    try {
      final found = await context.read<HerdApi>().animals(query: text);
      if (mounted && search == _lastSearch) setState(() => _results = found);
    } on ApiException catch (error) {
      if (mounted && search == _lastSearch) setState(() => _error = error.message);
    } finally {
      if (mounted && search == _lastSearch) setState(() => _searching = false);
    }
  }

  Future<void> _register() async {
    final herd = context.read<HerdApi>();
    setState(() {
      _error = null;
      _registering = true;
    });
    try {
      widget.onSelect(await herd.createAnimal(NewAnimal(identifier: _query.trim())));
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = context.watch<AuthController>().can(Permissions.herdManage);
    final tag = _query.trim();
    final noMatches = tag.isNotEmpty && !_searching && _results.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepTitle(
          lead: 'Identificá el ',
          emphasis: 'animal',
          subtitle: 'Ingresá la caravana. Si no existe, la das de alta.',
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: _search,
          autocorrect: false,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14, color: AppColors.neutral800),
          decoration: const InputDecoration(
            hintText: 'Ingresá la caravana…',
            prefixIcon: Icon(Icons.search, size: 20, color: AppColors.neutral800),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
        if (_error != null) ...[const SizedBox(height: 16), Notice(message: _error!, tone: NoticeTone.danger)],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final animal in _results) ...[
            _AnimalOption(animal: animal, onTap: () => widget.onSelect(animal)),
            const SizedBox(height: 8),
          ],
        ],
        if (noMatches) ...[
          const SizedBox(height: 16),
          Notice(message: 'No hay ningún animal con la caravana “$tag”.'),
          if (canManage) ...[
            const SizedBox(height: 12),
            AppButton(
              label: 'Dar de alta “$tag”',
              icon: Icons.add,
              size: AppButtonSize.lg,
              expand: true,
              loading: _registering,
              onPressed: _register,
            ),
          ],
        ],
      ],
    );
  }
}

class _AnimalOption extends StatelessWidget {
  const _AnimalOption({required this.animal, required this.onTap});

  final Animal animal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (animal.breed != null) animal.breed!,
      if (animal.lotCode != null) 'Lote ${animal.lotCode}',
    ].join(' · ');
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.row),
        side: const BorderSide(color: AppColors.neutral200),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: const Icon(Icons.sell_outlined, size: 20, color: AppColors.green600),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal.identifier,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.neutral800),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
