import 'dart:math';

import 'package:detective/features/investigation/domain/entities/analysis_method.dart';
import 'package:detective/features/investigation/domain/entities/evidence_entity.dart';
import 'package:detective/features/investigation/domain/services/statistical_methods.dart';
import 'package:flutter_test/flutter_test.dart';

EvidenceEntity _ev(String id, num value, {DateTime? at}) => EvidenceEntity(
      id: id,
      timestamp: at ?? DateTime(2026, 1, 1),
      kind: EvidenceKind.transaction,
      source: 'TEST',
      summary: '',
      value: value,
      flagged: false,
    );

void main() {
  group('StatisticalMethods.describe', () {
    test('симметричная выборка [1..5]: mean=3, median=3', () {
      final r = StatisticalMethods.describe([
        for (var i = 1; i <= 5; i++) _ev('E$i', i),
      ]);
      expect(r.n, 5);
      expect(r.mean, 3);
      expect(r.median, 3);
      expect(r.min, 1);
      expect(r.max, 5);
      expect(r.q1, 2);
      expect(r.q3, 4);
    });

    test('std известного набора (по формуле популяции)', () {
      // [2,4,4,4,5,5,7,9] → mean=5, var=4, std=2
      final r = StatisticalMethods.describe([
        for (final v in const [2, 4, 4, 4, 5, 5, 7, 9])
          _ev('E${v.hashCode}', v),
      ]);
      expect(r.mean, 5);
      expect(r.std, closeTo(2, 1e-9));
    });

    test('пустой вход возвращает нули, не падает', () {
      final r = StatisticalMethods.describe(const []);
      expect(r.n, 0);
      expect(r.mean, 0);
      expect(r.std, 0);
    });
  });

  group('StatisticalMethods.zScore', () {
    test('явный outlier выявляется', () {
      // 20 точек около 100±5 + одна 200 — должна быть outlier с z > 3.
      final rng = Random(42);
      final list = [
        for (var i = 0; i < 20; i++) _ev('E$i', 100 + rng.nextInt(10) - 5),
        _ev('GUN', 200),
      ];
      final r = StatisticalMethods.zScore(list);
      expect(r.outliers, isNotEmpty);
      expect(r.outliers.first.evidence.id, 'GUN');
      expect(r.outliers.first.score, greaterThan(3.0));
    });

    test('равномерные данные — нет outliers', () {
      final list = [for (var i = 0; i < 30; i++) _ev('E$i', 100)];
      final r = StatisticalMethods.zScore(list);
      expect(r.outliers, isEmpty);
    });
  });

  group('StatisticalMethods.iqr', () {
    test('outliers за полтора IQR от Q1/Q3', () {
      final list = [
        for (final v in const [10, 12, 14, 15, 16, 17, 18, 19, 20, 100])
          _ev('E$v', v),
      ];
      final r = StatisticalMethods.iqr(list);
      expect(r.outliers.map((h) => h.evidence.id), contains('E100'));
    });
  });

  group('StatisticalMethods.mad', () {
    test('устойчив против двух выбросов', () {
      // z-score обычно «маскирует» один outlier другим (std раздувается);
      // MAD использует медиану и должен оба обнаружить. Базовая выборка
      // должна иметь небольшой разброс, чтобы MAD > 0.
      final rng = Random(42);
      final list = [
        for (var i = 0; i < 20; i++) _ev('E$i', 50 + rng.nextInt(11) - 5),
        _ev('A', 500),
        _ev('B', 600),
      ];
      final mad = StatisticalMethods.mad(list);
      expect(mad.outliers.map((h) => h.evidence.id),
          containsAll(['A', 'B']));
    });
  });

  group('StatisticalMethods.benford', () {
    test('равномерные первые цифры → высокий χ² (плохо для Бенфорда)', () {
      // 90 точек: по 10 на каждую первую цифру 1..9.
      // Бенфорд ожидает 30% единиц, получит 11% → большой χ².
      final list = <EvidenceEntity>[];
      for (var d = 1; d <= 9; d++) {
        for (var k = 0; k < 10; k++) {
          list.add(_ev('E${d}_$k', d * 100 + k));
        }
      }
      final r = StatisticalMethods.benford(list);
      expect(r.metric, greaterThan(15.51));
    });

    test('Бенфордовое распределение → низкий χ²', () {
      // Сгенерируем 200 значений: первая цифра d с вероятностью log10(1+1/d).
      final rng = Random(7);
      final list = <EvidenceEntity>[];
      var i = 0;
      for (var d = 1; d <= 9; d++) {
        final share = (log(1 + 1 / d) / ln10);
        final count = (200 * share).round();
        for (var k = 0; k < count; k++) {
          // Случайная величина с нужной первой цифрой.
          final mag = pow(10, rng.nextInt(3)).toInt();
          list.add(_ev('E${i++}', d * mag + rng.nextInt(mag)));
        }
      }
      final r = StatisticalMethods.benford(list);
      expect(r.metric, lessThan(15.51));
    });
  });

  group('StatisticalMethods.spearman', () {
    test('строго монотонные value↔time → ρ = 1', () {
      final list = [
        for (var i = 0; i < 10; i++)
          _ev('E$i', i, at: DateTime(2026, 1, 1).add(Duration(days: i))),
      ];
      final r = StatisticalMethods.spearman(list);
      expect(r.metric, closeTo(1.0, 1e-9));
    });

    test('обратный порядок → ρ = -1', () {
      final list = [
        for (var i = 0; i < 10; i++)
          _ev('E$i', 100 - i,
              at: DateTime(2026, 1, 1).add(Duration(days: i))),
      ];
      final r = StatisticalMethods.spearman(list);
      expect(r.metric, closeTo(-1.0, 1e-9));
    });
  });

  group('StatisticalMethods.apply (диспетчер)', () {
    test('вызывает соответствующую функцию по enum', () {
      final list = [for (var i = 0; i < 10; i++) _ev('E$i', i)];
      for (final m in AnalysisMethod.values) {
        final r = StatisticalMethods.apply(m, list);
        expect(r.method, m);
        expect(r.descriptive.n, 10);
      }
    });
  });
}
