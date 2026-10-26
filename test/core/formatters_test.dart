import 'package:bovino_vision_mobile/core/format/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses decimal comma and dot for thousands', () {
    expect(formatNumber(1248), '1.248');
    expect(formatNumber(1248000), '1.248.000');
    expect(formatNumber(0.85, 2), '0,85');
    expect(formatNumber(-0.3, 2), '-0,30');
  });

  test('formats kilograms with a separate unit', () {
    expect(formatKg(452), '452 kg');
    expect(formatKg(452.46, 1), '452,5 kg');
  });

  test('puts a space before the percent sign', () {
    expect(formatPercent(0.6), '60 %');
  });

  test('formats GMD with sign and two decimals', () {
    expect(formatGmd(0.85), '+0,85 kg/día');
    expect(formatGmd(-0.3), '-0,30 kg/día');
    expect(formatGmd(0), '0,00 kg/día');
  });

  test('reads API calendar dates as local dates', () {
    expect(formatDate('2026-10-20'), '20/10/2026');
    expect(formatShortDate('2026-09-01'), '1 sept');
  });

  test('shows date and time on a 24-hour clock', () {
    expect(formatDateTime('2026-10-19T22:05:00'), '19/10/2026, 22:05');
    expect(formatDateTime('2026-10-19T10:00:00'), '19/10/2026, 10:00');
    expect(formatTime('2026-10-19T09:05:00'), '09:05');
  });

  test('describes elapsed time', () {
    final now = DateTime(2026, 10, 20, 12);
    expect(formatAgo('2026-10-20T11:59:30', now: now), 'Recién');
    expect(formatAgo('2026-10-20T11:45:00', now: now), 'Hace 15 min');
    expect(formatAgo('2026-10-20T09:00:00', now: now), 'Hace 3 h');
    expect(formatAgo('2026-10-19T10:00:00', now: now), 'Ayer');
    expect(formatAgo('2026-10-16T12:00:00', now: now), 'Hace 4 días');
  });

  group('formatAge', () {
    final today = DateTime(2026, 10, 21, 12);

    test('counts whole calendar months and speaks in years once past a year', () {
      expect(formatAge('2024-07-10', today: today), '2 años y 3 meses');
      expect(formatAge('2025-04-21', today: today), '1 año y 6 meses');
      expect(formatAge('2025-10-21', today: today), '1 año');
      expect(formatAge('2023-10-21', today: today), '3 años');
    });

    test('speaks in months below a year, singular for one', () {
      expect(formatAge('2026-02-21', today: today), '8 meses');
      expect(formatAge('2026-09-21', today: today), '1 mes');
      expect(formatAge('2026-10-01', today: today), 'Menos de 1 mes');
    });

    test('returns null for a future birth date', () {
      expect(formatAge('2026-11-01', today: today), isNull);
    });
  });
}
