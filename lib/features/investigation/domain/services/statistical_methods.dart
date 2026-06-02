import 'dart:math' as math;

import '../entities/analysis_method.dart';
import '../entities/analysis_result.dart';
import '../entities/evidence_entity.dart';

/// Чистые численные функции — без Flutter, тестируются изолированно.
/// На входе — массив EvidenceEntity (нужен для возврата OutlierHit с
/// привязкой к конкретной улике).
class StatisticalMethods {
  StatisticalMethods._();

  static const double _zScoreThreshold = 3.0;
  static const double _madThreshold = 3.5;
  static const double _madConst = 0.6745;
  static const double _iqrK = 1.5;

  // ───────── Описательная статистика ────────────────────────────────

  static DescriptiveStats describe(List<EvidenceEntity> evidence) {
    final n = evidence.length;
    if (n == 0) {
      return const DescriptiveStats(
        n: 0,
        mean: 0,
        median: 0,
        std: 0,
        min: 0,
        max: 0,
        q1: 0,
        q3: 0,
      );
    }
    final values = evidence.map((e) => e.value.toDouble()).toList()..sort();
    final mean = values.reduce((a, b) => a + b) / n;
    final variance =
        values.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / n;
    return DescriptiveStats(
      n: n,
      mean: mean,
      median: _percentile(values, 0.5),
      std: math.sqrt(variance),
      min: values.first,
      max: values.last,
      q1: _percentile(values, 0.25),
      q3: _percentile(values, 0.75),
    );
  }

  // ───────── Методы ─────────────────────────────────────────────────

  static AnalysisResult zScore(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    if (desc.n < 2 || desc.std == 0) {
      return AnalysisResult(
        method: AnalysisMethod.zScore,
        metric: 0,
        metricLabel: 'σ',
        metricUnit: '',
        outliers: const [],
        summary: 'Выборка слишком мала или std = 0 — метод не применим.',
        descriptive: desc,
      );
    }
    final hits = <OutlierHit>[];
    for (final e in evidence) {
      final z = (e.value.toDouble() - desc.mean) / desc.std;
      if (z.abs() > _zScoreThreshold) {
        hits.add(OutlierHit(
          evidence: e,
          score: z.abs(),
          scoreLabel: 'z = ${z.toStringAsFixed(2)}',
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return AnalysisResult(
      method: AnalysisMethod.zScore,
      metric: desc.std,
      metricLabel: 'σ',
      metricUnit: '',
      outliers: hits,
      summary: hits.isEmpty
          ? 'Выбросов выше 3σ не найдено. Возможно, аномалия в скосе — попробуй MAD.'
          : 'Найдено ${hits.length} outlier${_plural(hits.length)}. Самый сильный: '
              '${hits.first.evidence.id} (${hits.first.scoreLabel}).',
      descriptive: desc,
    );
  }

  static AnalysisResult iqr(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    if (desc.n < 4) {
      return AnalysisResult(
        method: AnalysisMethod.iqr,
        metric: 0,
        metricLabel: 'IQR',
        metricUnit: '',
        outliers: const [],
        summary: 'Слишком мало точек для IQR (нужно ≥ 4).',
        descriptive: desc,
      );
    }
    final lower = desc.q1 - _iqrK * desc.iqr;
    final upper = desc.q3 + _iqrK * desc.iqr;
    final hits = <OutlierHit>[];
    for (final e in evidence) {
      final v = e.value.toDouble();
      if (v < lower || v > upper) {
        final dist = v < lower ? (lower - v) : (v - upper);
        hits.add(OutlierHit(
          evidence: e,
          score: dist / (desc.iqr == 0 ? 1 : desc.iqr),
          scoreLabel: v < lower
              ? 'x < ${lower.toStringAsFixed(1)}'
              : 'x > ${upper.toStringAsFixed(1)}',
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return AnalysisResult(
      method: AnalysisMethod.iqr,
      metric: desc.iqr,
      metricLabel: 'IQR',
      metricUnit: '',
      outliers: hits,
      summary: hits.isEmpty
          ? 'Выбросов вне [Q1−1.5·IQR, Q3+1.5·IQR] не найдено.'
          : '${hits.length} outlier${_plural(hits.length)} вне '
              '[${lower.toStringAsFixed(1)}, ${upper.toStringAsFixed(1)}]. '
              'Лидер: ${hits.first.evidence.id}.',
      descriptive: desc,
    );
  }

  static AnalysisResult mad(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    if (desc.n < 2) {
      return AnalysisResult(
        method: AnalysisMethod.mad,
        metric: 0,
        metricLabel: 'MAD',
        metricUnit: '',
        outliers: const [],
        summary: 'Слишком мало точек.',
        descriptive: desc,
      );
    }
    final values = evidence.map((e) => e.value.toDouble()).toList();
    final med = desc.median;
    final deviations = values.map((x) => (x - med).abs()).toList()..sort();
    final madValue = _percentile(deviations, 0.5);
    if (madValue == 0) {
      return AnalysisResult(
        method: AnalysisMethod.mad,
        metric: 0,
        metricLabel: 'MAD',
        metricUnit: '',
        outliers: const [],
        summary:
            'MAD = 0 (более половины точек идентичны). Метод не применим, попробуй z-score.',
        descriptive: desc,
      );
    }
    final hits = <OutlierHit>[];
    for (final e in evidence) {
      final mz = _madConst * (e.value.toDouble() - med) / madValue;
      if (mz.abs() > _madThreshold) {
        hits.add(OutlierHit(
          evidence: e,
          score: mz.abs(),
          scoreLabel: 'M = ${mz.toStringAsFixed(2)}',
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return AnalysisResult(
      method: AnalysisMethod.mad,
      metric: madValue,
      metricLabel: 'MAD',
      metricUnit: '',
      outliers: hits,
      summary: hits.isEmpty
          ? 'modified-z всех точек ≤ 3.5 — устойчивых выбросов нет.'
          : '${hits.length} устойчив${hits.length == 1 ? "ый" : "ых"} outlier'
              '${_plural(hits.length)}. Самый явный — ${hits.first.evidence.id} '
              '(${hits.first.scoreLabel}).',
      descriptive: desc,
    );
  }

  static AnalysisResult benford(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final n = evidence.length;
    if (n < 9) {
      return AnalysisResult(
        method: AnalysisMethod.benford,
        metric: 0,
        metricLabel: 'χ²',
        metricUnit: '',
        outliers: const [],
        summary: 'Слишком мало точек для Бенфорда (нужно ≥ 9).',
        descriptive: desc,
      );
    }
    // Считаем частоты первых значащих цифр.
    final observed = List<int>.filled(10, 0); // индексы 1..9
    var counted = 0;
    for (final e in evidence) {
      final d = _firstDigit(e.value);
      if (d >= 1 && d <= 9) {
        observed[d]++;
        counted++;
      }
    }
    if (counted == 0) {
      return AnalysisResult(
        method: AnalysisMethod.benford,
        metric: 0,
        metricLabel: 'χ²',
        metricUnit: '',
        outliers: const [],
        summary: 'Нет валидных значений для извлечения первой цифры.',
        descriptive: desc,
      );
    }
    // Бенфордовы ожидания.
    final expected = List<double>.filled(10, 0);
    for (var d = 1; d <= 9; d++) {
      expected[d] = math.log(1 + 1 / d) / math.ln10;
    }
    // χ²-статистика.
    var chi2 = 0.0;
    final residual = List<double>.filled(10, 0);
    for (var d = 1; d <= 9; d++) {
      final exp = expected[d] * counted;
      final diff = observed[d] - exp;
      residual[d] = diff;
      if (exp > 0) chi2 += diff * diff / exp;
    }
    // Подозрительные цифры — где observed заметно выше expected.
    final suspectDigits = <int>{};
    for (var d = 1; d <= 9; d++) {
      final exp = expected[d] * counted;
      if (exp > 0 && observed[d] > exp + math.sqrt(exp)) {
        suspectDigits.add(d);
      }
    }
    final hits = <OutlierHit>[];
    for (final e in evidence) {
      final d = _firstDigit(e.value);
      if (suspectDigits.contains(d)) {
        final exp = expected[d] * counted;
        final excess = observed[d] - exp;
        hits.add(OutlierHit(
          evidence: e,
          score: excess,
          scoreLabel:
              'first=$d (obs=${observed[d]} > exp=${exp.toStringAsFixed(1)})',
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return AnalysisResult(
      method: AnalysisMethod.benford,
      metric: chi2,
      metricLabel: 'χ²',
      metricUnit: '',
      outliers: hits,
      summary: chi2 > 15.51
          ? 'χ² = ${chi2.toStringAsFixed(2)} > 15.51 (5%-критическое для df=8). '
              'Распределение первых цифр не соответствует Бенфорду — есть подделка.'
          : 'χ² = ${chi2.toStringAsFixed(2)} ≤ 15.51. Распределение первых цифр '
              'согласуется с Бенфордом — массовых аномалий не видно.',
      descriptive: desc,
    );
  }

  /// Spearman ρ между value и индексом по timestamp (порядок).
  /// |ρ| → 1: монотонная связь. Outliers — точки с максимальным |d|.
  static AnalysisResult spearman(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final n = evidence.length;
    if (n < 4) {
      return AnalysisResult(
        method: AnalysisMethod.spearman,
        metric: 0,
        metricLabel: 'ρ',
        metricUnit: '',
        outliers: const [],
        summary: 'Слишком мало точек для Спирмена (нужно ≥ 4).',
        descriptive: desc,
      );
    }
    final indexed = List<MapEntry<int, EvidenceEntity>>.generate(
      n,
      (i) => MapEntry(i, evidence[i]),
    );
    // Ранг по timestamp (естественный — индекс после сортировки).
    final byTime = [...indexed]
      ..sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
    final timeRank = <int, int>{};
    for (var i = 0; i < n; i++) {
      timeRank[byTime[i].key] = i + 1;
    }
    // Ранг по value.
    final byValue = [...indexed]
      ..sort((a, b) => a.value.value.compareTo(b.value.value));
    final valueRank = <int, int>{};
    for (var i = 0; i < n; i++) {
      valueRank[byValue[i].key] = i + 1;
    }
    // ρ.
    var sumD2 = 0.0;
    final residuals = <int, double>{};
    for (var i = 0; i < n; i++) {
      final d = (valueRank[i]! - timeRank[i]!).toDouble();
      residuals[i] = d;
      sumD2 += d * d;
    }
    final rho = 1 - 6 * sumD2 / (n * (n * n - 1));
    // Outliers — точки с максимальным |d| (нарушают тренд).
    final hitEntries = residuals.entries.toList()
      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    final hits = <OutlierHit>[];
    for (final r in hitEntries) {
      if (r.value.abs() < n * 0.25) break; // "сильное" расхождение
      hits.add(OutlierHit(
        evidence: evidence[r.key],
        score: r.value.abs(),
        scoreLabel: 'Δrank = ${r.value.toStringAsFixed(0)}',
      ));
      if (hits.length >= 5) break;
    }
    return AnalysisResult(
      method: AnalysisMethod.spearman,
      metric: rho,
      metricLabel: 'ρ',
      metricUnit: '',
      outliers: hits,
      summary: rho.abs() > 0.7
          ? 'ρ = ${rho.toStringAsFixed(2)} — сильная монотонная связь value↔time. '
              '${hits.length} точек ломают тренд (см. Δrank).'
          : rho.abs() > 0.3
              ? 'ρ = ${rho.toStringAsFixed(2)} — умеренная связь.'
              : 'ρ = ${rho.toStringAsFixed(2)} — связи value↔time нет.',
      descriptive: desc,
    );
  }

  static AnalysisResult descriptive(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    return AnalysisResult(
      method: AnalysisMethod.descriptive,
      metric: desc.mean,
      metricLabel: 'mean',
      metricUnit: '',
      outliers: const [],
      summary: 'n=${desc.n}  ·  mean=${desc.mean.toStringAsFixed(1)}  ·  '
          'median=${desc.median.toStringAsFixed(1)}  ·  std=${desc.std.toStringAsFixed(1)}  ·  '
          'min=${desc.min.toStringAsFixed(0)}  ·  max=${desc.max.toStringAsFixed(0)}',
      descriptive: desc,
    );
  }

  /// Диспетчер: применить метод по enum'у.
  static AnalysisResult apply(
      AnalysisMethod method, List<EvidenceEntity> evidence) {
    switch (method) {
      case AnalysisMethod.descriptive:
        return descriptive(evidence);
      case AnalysisMethod.zScore:
        return zScore(evidence);
      case AnalysisMethod.iqr:
        return iqr(evidence);
      case AnalysisMethod.mad:
        return mad(evidence);
      case AnalysisMethod.benford:
        return benford(evidence);
      case AnalysisMethod.spearman:
        return spearman(evidence);
    }
  }

  // ───────── Helpers ────────────────────────────────────────────────

  /// Линейная интерполяция перцентиля по уже отсортированному массиву.
  static double _percentile(List<double> sorted, double p) {
    if (sorted.isEmpty) return 0;
    if (sorted.length == 1) return sorted.first;
    final pos = p * (sorted.length - 1);
    final lo = pos.floor();
    final hi = pos.ceil();
    if (lo == hi) return sorted[lo];
    final frac = pos - lo;
    return sorted[lo] + (sorted[hi] - sorted[lo]) * frac;
  }

  static int _firstDigit(num value) {
    var v = value.abs().toDouble();
    if (v == 0) return 0;
    while (v >= 10) {
      v /= 10;
    }
    while (v < 1) {
      v *= 10;
    }
    return v.floor();
  }

  static String _plural(int n) => n == 1 ? '' : 'ов';
}
