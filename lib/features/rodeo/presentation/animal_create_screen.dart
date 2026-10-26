import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/data/herd_api.dart';
import '../../../core/data/herd_models.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/page_header.dart';
import 'animal_form.dart';

/// "Nuevo animal": the web's inline sign-up card as its own phone screen. On success it goes
/// back to the herd list, which reloads and shows the new animal.
class AnimalCreateScreen extends StatefulWidget {
  const AnimalCreateScreen({super.key});

  @override
  State<AnimalCreateScreen> createState() => _AnimalCreateScreenState();
}

class _AnimalCreateScreenState extends State<AnimalCreateScreen> {
  late final HerdApi _herd = context.read<HerdApi>();
  final _identifier = TextEditingController();

  List<Breed> _breeds = const [];
  List<Lot> _lots = const [];
  bool _loadingCatalogs = true;
  String? _catalogError;

  AnimalFormValue _value = const AnimalFormValue();
  bool _sending = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadCatalogs();
  }

  @override
  void dispose() {
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loadingCatalogs = true;
      _catalogError = null;
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
        _catalogError = error.message;
        _loadingCatalogs = false;
      });
    }
  }

  Future<void> _submit() async {
    final identifier = _identifier.text.trim();
    if (identifier.isEmpty) return;
    setState(() {
      _sending = true;
      _submitError = null;
    });
    try {
      await _herd.createAnimal(_value.toNewAnimal(identifier));
      if (mounted) leaveAnimalScreen(context);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _sending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: pagePadding,
      children: [
        const BackLink(),
        const SizedBox(height: 8),
        const PageHeader(title: 'Nuevo animal'),
        const SizedBox(height: 24),
        if (_catalogError != null)
          ErrorRetry(message: _catalogError!, onRetry: _loadCatalogs)
        else if (_loadingCatalogs)
          const LoadingView()
        else
          AppCard(padding: cardPadding, child: _form()),
      ],
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FieldLabel('Identificador del nuevo animal'),
        TextField(
          controller: _identifier,
          autofocus: true,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Caravana o identificador'),
        ),
        const SizedBox(height: 16),
        AnimalFields(
          value: _value,
          onChanged: (value) => setState(() => _value = value),
          breeds: _breeds,
          lots: _lots,
        ),
        if (_submitError != null) ...[
          const SizedBox(height: 16),
          Notice(message: _submitError!, tone: NoticeTone.danger),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton(
              label: 'Agregar',
              loading: _sending,
              onPressed: _identifier.text.trim().isEmpty ? null : _submit,
            ),
            AppButton(
              label: 'Cancelar',
              variant: AppButtonVariant.ghost,
              onPressed: _sending ? null : () => leaveAnimalScreen(context),
            ),
          ],
        ),
      ],
    );
  }
}
