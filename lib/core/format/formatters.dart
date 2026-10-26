// Argentine number and date formats, ported from the web app (`src/lib/formato.ts`):
// decimal comma, dot for thousands, 24-hour clock.

const _shortMonths = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sept', 'oct', 'nov', 'dic'];

final _calendarDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');

String _twoDigits(int value) => value.toString().padLeft(2, '0');

/// "1.248", "0,85".
String formatNumber(num value, [int decimals = 0]) {
  final fixed = value.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final integer = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  final sign = value < 0 && double.parse(fixed) != 0 ? '-' : '';
  return parts.length == 1 ? '$sign$integer' : '$sign$integer,${parts[1]}';
}

/// "452 kg", "452,5 kg".
String formatKg(num value, [int decimals = 0]) => '${formatNumber(value, decimals)} kg';

/// "60 %" with the space the design system asks for.
String formatPercent(num fraction) => '${formatNumber((fraction * 100).round())} %';

/// "+0,85 kg/día": average daily gain with sign and two decimals.
String formatGmd(num gmd) => '${gmd > 0 ? '+' : ''}${formatNumber(gmd, 2)} kg/día';

/// API calendar dates ("2026-10-20") are local dates; date-times are converted to local time.
DateTime parseApiDate(String value) {
  if (_calendarDate.hasMatch(value)) {
    final parts = value.split('-').map(int.parse).toList();
    return DateTime(parts[0], parts[1], parts[2]);
  }
  return DateTime.parse(value).toLocal();
}

/// "20/10/2026".
String formatDate(String value) {
  final date = parseApiDate(value);
  return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
}

/// "20 oct", for chart axes.
String formatShortDate(String value) {
  final date = parseApiDate(value);
  return '${date.day} ${_shortMonths[date.month - 1]}';
}

/// "14:30".
String formatTime(String value) {
  final date = parseApiDate(value);
  return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
}

/// "20/10/2026, 14:30".
String formatDateTime(String value) => '${formatDate(value)}, ${formatTime(value)}';

/// "Recién", "Hace 15 min", "Hace 3 h", "Ayer", "Hace 4 días", relative to [now].
String formatAgo(String value, {DateTime? now}) {
  final minutes = (now ?? DateTime.now()).difference(parseApiDate(value)).inMinutes;
  if (minutes < 1) return 'Recién';
  if (minutes < 60) return 'Hace $minutes min';
  final hours = minutes ~/ 60;
  if (hours < 24) return 'Hace $hours h';
  final days = hours ~/ 24;
  return days == 1 ? 'Ayer' : 'Hace $days días';
}

String _units(int amount, String singular, String plural) => '$amount ${amount == 1 ? singular : plural}';

/// Age from a birth date in whole calendar months: "Menos de 1 mes", "8 meses", "1 año",
/// "2 años y 3 meses". Null when the date is in the future.
String? formatAge(String birthDate, {DateTime? today}) {
  final birth = parseApiDate(birthDate);
  final reference = today ?? DateTime.now();
  final dayNotReached = reference.day < birth.day ? 1 : 0;
  final months = (reference.year - birth.year) * 12 + reference.month - birth.month - dayNotReached;
  if (months < 0) return null;
  if (months < 1) return 'Menos de 1 mes';
  if (months < 12) return _units(months, 'mes', 'meses');
  final years = _units(months ~/ 12, 'año', 'años');
  final remaining = months % 12;
  return remaining == 0 ? years : '$years y ${_units(remaining, 'mes', 'meses')}';
}
