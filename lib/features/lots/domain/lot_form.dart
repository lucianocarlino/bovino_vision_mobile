import '../../../core/data/herd_models.dart';
import '../../../core/format/formatters.dart';

// Lot form rules, ported from the web app (`src/features/lotes/formularioLote.ts`).

/// Target GMD typed by the user: empty means none, a decimal comma is accepted, and it must
/// be positive (same rule as the API). Returns the error message in [error] when invalid.
({double? value, String? error}) parseGmdTarget(String text) {
  final clean = text.trim().replaceFirst(',', '.');
  if (clean.isEmpty) return (value: null, error: null);
  final value = double.tryParse(clean);
  if (value == null || !value.isFinite) return (value: null, error: 'La GMD objetivo debe ser un número');
  if (value <= 0) return (value: null, error: 'La GMD objetivo debe ser positiva');
  return (value: value, error: null);
}

/// Text for the target field when editing: "0,8".
String gmdTargetText(double? target) => target == null ? '' : '$target'.replaceFirst('.', ',');

/// Fields of [lot] that [name] and [gmdText] change to a value; an emptied field is not sent.
({String? name, double? gmdTarget, String? error}) lotChanges(Lot lot, {required String name, required String gmdText}) {
  final gmd = parseGmdTarget(gmdText);
  if (gmd.error != null) return (name: null, gmdTarget: null, error: gmd.error);
  final trimmed = name.trim();
  return (
    name: trimmed.isNotEmpty && trimmed != lot.name ? trimmed : null,
    gmdTarget: gmd.value != null && gmd.value != lot.gmdTarget ? gmd.value : null,
    error: null,
  );
}

/// "0,80 kg/día", or "Sin objetivo".
String gmdTargetLabel(double? target) => target == null ? 'Sin objetivo' : '${formatNumber(target, 2)} kg/día';
