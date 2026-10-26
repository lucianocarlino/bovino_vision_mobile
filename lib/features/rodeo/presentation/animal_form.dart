import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/rodeo_api.dart';
import '../domain/rodeo_logic.dart';

/// Card padding of the web app on phones (`p-6`).
const cardPadding = EdgeInsets.all(24);

/// "‹ Rodeo" link at the top of the animal screens: back to the list.
class BackLink extends StatelessWidget {
  const BackLink({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: () => leaveAnimalScreen(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 44),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, size: 18, color: AppColors.neutral600),
              SizedBox(width: 8),
              Text('Rodeo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.neutral600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns to the herd list, which stays mounted under the animal screens and refreshes itself.
void leaveAnimalScreen(BuildContext context) => context.go(AppRoutes.rodeo);

/// Uppercase-free field label of the web forms (12 px medium) above its control.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.neutral700)),
      );
}

/// Breed, sex, birth date and lot of an animal as typed in the form; null means "no value".
class AnimalFormValue {
  const AnimalFormValue({this.breedId, this.sex, this.birthDate, this.lotId});

  factory AnimalFormValue.of(Animal animal) =>
      AnimalFormValue(breedId: animal.breedId, sex: animal.sex, birthDate: animal.birthDate, lotId: animal.lotId);

  final String? breedId;
  final Sex? sex;

  /// "YYYY-MM-DD".
  final String? birthDate;
  final String? lotId;

  AnimalFormValue withBreed(String? id) => AnimalFormValue(breedId: id, sex: sex, birthDate: birthDate, lotId: lotId);
  AnimalFormValue withSex(Sex? value) => AnimalFormValue(breedId: breedId, sex: value, birthDate: birthDate, lotId: lotId);
  AnimalFormValue withBirthDate(String? date) =>
      AnimalFormValue(breedId: breedId, sex: sex, birthDate: date, lotId: lotId);
  AnimalFormValue withLot(String? id) => AnimalFormValue(breedId: breedId, sex: sex, birthDate: birthDate, lotId: id);

  /// Body of `POST /animales` for [identifier].
  NewAnimal toNewAnimal(String identifier) =>
      NewAnimal(identifier: identifier, breedId: breedId, sex: sex, birthDate: birthDate, lotId: lotId);

  /// Only the fields that changed to a value: the API keeps the stored value for a null.
  AnimalChanges changesFrom(AnimalFormValue original) => AnimalChanges(
        breedId: breedId != null && breedId != original.breedId ? breedId : null,
        sex: sex != null && sex != original.sex ? sex : null,
        birthDate: birthDate != null && birthDate != original.birthDate ? birthDate : null,
        lotId: lotId != null && lotId != original.lotId ? lotId : null,
      );
}

/// Breed, sex, birth date and lot, shared by the create and edit forms.
class AnimalFields extends StatelessWidget {
  const AnimalFields({
    super.key,
    required this.value,
    required this.onChanged,
    required this.breeds,
    required this.lots,
    this.original,
  });

  final AnimalFormValue value;
  final ValueChanged<AnimalFormValue> onChanged;
  final List<Breed> breeds;
  final List<Lot> lots;

  /// Stored data: a field that already has a value cannot be emptied (the API keeps it).
  final AnimalFormValue? original;

  @override
  Widget build(BuildContext context) {
    final stored = original;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DropdownField<String>(
          label: 'Raza',
          emptyLabel: 'Sin registrar',
          value: value.breedId,
          lockedEmpty: stored?.breedId != null,
          options: [for (final breed in breeds) (breed.id, breed.name)],
          onChanged: (id) => onChanged(value.withBreed(id)),
        ),
        const SizedBox(height: 16),
        _DropdownField<Sex>(
          label: 'Sexo',
          emptyLabel: 'Sin registrar',
          value: value.sex,
          lockedEmpty: stored?.sex != null,
          options: [for (final sex in Sex.values) (sex, sex.label)],
          onChanged: (sex) => onChanged(value.withSex(sex)),
        ),
        const SizedBox(height: 16),
        _DateField(
          label: 'Fecha de nacimiento',
          value: value.birthDate,
          clearable: stored?.birthDate == null,
          onChanged: (date) => onChanged(value.withBirthDate(date)),
        ),
        const SizedBox(height: 16),
        _DropdownField<String>(
          label: 'Lote',
          emptyLabel: 'Sin lote',
          value: value.lotId,
          lockedEmpty: stored?.lotId != null,
          options: [
            for (final lot in lots) (lot.id, lot.name == null ? lot.label : '${lot.label} · ${lot.name}'),
          ],
          onChanged: (id) => onChanged(value.withLot(id)),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.emptyLabel,
    required this.value,
    required this.lockedEmpty,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String emptyLabel;
  final T? value;

  /// True when the stored value exists, so "no value" is not a valid choice.
  final bool lockedEmpty;
  final List<(T, String)> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectable = options.any((option) => option.$1 == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        InputDecorator(
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: selectable,
              isExpanded: true,
              icon: const Icon(Icons.expand_more, color: AppColors.neutral800),
              style: const TextStyle(fontSize: 14, color: AppColors.neutral800),
              dropdownColor: AppColors.white,
              items: [
                DropdownMenuItem<T?>(enabled: !lockedEmpty, child: Text(emptyLabel)),
                for (final (id, text) in options) DropdownMenuItem<T?>(value: id, child: Text(text, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.clearable, required this.onChanged});

  final String label;

  /// "YYYY-MM-DD".
  final String? value;
  final bool clearable;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context) async {
    final today = DateTime.now();
    final current = value == null ? null : parseApiDate(value!);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: DateTime(1980),
      lastDate: current != null && current.isAfter(today) ? current : today,
    );
    if (picked != null) onChanged(toApiDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final date = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FieldLabel(label),
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.control),
          onTap: () => _pick(context),
          child: InputDecorator(
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date == null ? 'dd/mm/aaaa' : formatDate(date),
                    style: TextStyle(fontSize: 14, color: date == null ? AppColors.neutral400 : AppColors.neutral800),
                  ),
                ),
                if (date != null && clearable)
                  InkWell(
                    onTap: () => onChanged(null),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(Icons.close, size: 18, color: AppColors.neutral500, semanticLabel: 'Quitar fecha'),
                    ),
                  ),
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.neutral800),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
