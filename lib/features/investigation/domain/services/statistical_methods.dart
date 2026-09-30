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
        readout: 'n=${desc.n} · σ=${desc.std.toStringAsFixed(2)} — метод неприменим.',
        conclusion:
            'Выборка слишком мала или нулевой разброс — z-оценка не определена.',
        descriptive: desc,
      );
    }
    final hits = <OutlierHit>[];
    var maxAbsZ = 0.0;
    for (final e in evidence) {
      final z = (e.value.toDouble() - desc.mean) / desc.std;
      if (z.abs() > maxAbsZ) maxAbsZ = z.abs();
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
      readout: 'σ = ${desc.std.toStringAsFixed(1)} · n=${desc.n} · '
          '|z|max = ${maxAbsZ.toStringAsFixed(2)} · точек |z|>3: ${hits.length}',
      conclusion: hits.isEmpty
          ? 'Выбросов за 3σ нет — данные однородны. Если подозреваешь скошенную '
              'аномалию, проверь MAD или Бенфорда.'
          : 'Аномалия: ${hits.first.evidence.id} (${hits.first.scoreLabel}) — '
              'статистически выделяющаяся точка за порогом 3σ.',
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
        readout: 'n=${desc.n} — нужно ≥ 4 точек.',
        conclusion: 'Слишком мало данных для построения квартилей.',
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
      readout: 'IQR = ${desc.iqr.toStringAsFixed(1)} · заборы '
          '[${lower.toStringAsFixed(1)}, ${upper.toStringAsFixed(1)}] · '
          'вне коридора: ${hits.length}',
      conclusion: hits.isEmpty
          ? 'Все точки внутри заборов Тьюки — устойчивых выбросов нет '
              '(метод не зависит от формы распределения).'
          : '${hits.length} точк(а/и) за пределами коридора нормы. '
              'Лидер — ${hits.first.evidence.id}.',
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
        readout: 'n=${desc.n} — слишком мало точек.',
        conclusion: 'Недостаточно данных для оценки медианного отклонения.',
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
        readout: 'MAD = 0 · медиана = ${med.toStringAsFixed(1)}',
        conclusion:
            'MAD = 0 (более половины точек идентичны) — метод неприменим, попробуй z-score.',
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
      readout: 'MAD = ${madValue.toStringAsFixed(1)} · медиана = '
          '${med.toStringAsFixed(1)} · точек |M|>3.5: ${hits.length}',
      conclusion: hits.isEmpty
          ? 'modified-z всех точек ≤ 3.5 — устойчивых выбросов нет '
              '(MAD не «съедается» одиночными аномалиями).'
          : '${hits.length} устойчив${hits.length == 1 ? "ый" : "ых"} выброс'
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
        readout: 'n=$n — нужно ≥ 9 точек.',
        conclusion: 'Слишком мало данных для устойчивой оценки первой цифры.',
        descriptive: desc,
      );
    }
    final dist = firstDigitDistribution(evidence);
    final counted = dist.n;
    if (counted == 0) {
      return AnalysisResult(
        method: AnalysisMethod.benford,
        metric: 0,
        metricLabel: 'χ²',
        metricUnit: '',
        outliers: const [],
        readout: 'нет валидных первых цифр.',
        conclusion: 'Из значений не извлекается первая значащая цифра.',
        descriptive: desc,
      );
    }
    // χ²-статистика по сырым частотам vs ожидаемым.
    var chi2 = 0.0;
    for (var d = 1; d <= 9; d++) {
      final exp = dist.expected[d - 1] * counted;
      final diff = dist.counts[d - 1] - exp;
      if (exp > 0) chi2 += diff * diff / exp;
    }
    // Подозрительные цифры — те же, что подсветит chart (dist.suspect).
    final suspectDigits = <int>{
      for (var d = 1; d <= 9; d++)
        if (dist.suspect[d - 1]) d,
    };
    final hits = <OutlierHit>[];
    for (final e in evidence) {
      final d = _firstDigit(e.value);
      if (suspectDigits.contains(d)) {
        final exp = dist.expected[d - 1] * counted;
        final excess = dist.counts[d - 1] - exp;
        hits.add(OutlierHit(
          evidence: e,
          score: excess,
          scoreLabel:
              'first=$d (obs=${dist.counts[d - 1]} > exp=${exp.toStringAsFixed(1)})',
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
      readout: 'χ² = ${chi2.toStringAsFixed(2)} · крит. 15.51 (df=8, 5%) · '
          'n=$counted${suspectDigits.isEmpty ? '' : ' · избыток цифр: '
              '${(suspectDigits.toList()..sort()).join('/')}'}',
      conclusion: chi2 > 15.51
          ? 'Распределение первых цифр не соответствует закону Бенфорда — '
              'массив выдуман вручную (χ² выше критического).'
          : 'Первые цифры согласуются с Бенфордом — массовых подделок не видно.',
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
        readout: 'n=$n — нужно ≥ 4 точек.',
        conclusion: 'Недостаточно данных для ранговой корреляции.',
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
      readout: 'ρ = ${rho.toStringAsFixed(2)} · n=$n · '
          'нарушителей тренда: ${hits.length}',
      conclusion: rho.abs() > 0.7
          ? 'Сильная монотонная связь value↔time: значение растёт со временем '
              'не случайно. ${hits.length} точек ломают тренд (см. Δrank).'
          : rho.abs() > 0.3
              ? 'Умеренная монотонная связь value↔time — тенденция есть, но слабая.'
              : 'Монотонной связи value↔time нет — порядок во времени ни о чём не говорит.',
      descriptive: desc,
    );
  }

  static AnalysisResult descriptive(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final gap = desc.mean - desc.median;
    final skewed = desc.std > 0 && gap.abs() > 0.5 * desc.std;
    final String conclusion;
    if (!skewed) {
      conclusion =
          'mean ≈ median — распределение симметрично, среднему можно доверять.';
    } else if (gap > 0) {
      conclusion =
          'mean заметно выше median — справа сидит выброс/тяжёлый хвост, '
          'тянущий среднее вверх. Медиана честнее описывает типичное значение.';
    } else {
      conclusion =
          'mean заметно ниже median — слева тяжёлый хвост/аномально низкие '
          'значения тянут среднее вниз. Опирайся на медиану.';
    }
    return AnalysisResult(
      method: AnalysisMethod.descriptive,
      metric: desc.mean,
      metricLabel: 'mean',
      metricUnit: '',
      outliers: const [],
      readout: 'n=${desc.n}  ·  mean=${desc.mean.toStringAsFixed(1)}  ·  '
          'median=${desc.median.toStringAsFixed(1)}  ·  std=${desc.std.toStringAsFixed(1)}  ·  '
          'min=${desc.min.toStringAsFixed(0)}  ·  max=${desc.max.toStringAsFixed(0)}',
      conclusion: conclusion,
      descriptive: desc,
    );
  }

  /// Усечённое среднее (20% с каждого края) — устойчивая оценка центра.
  /// Большой разрыв mean ↔ trim значит, что среднее раздуто крайними точками.
  static AnalysisResult trimmedMean(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final n = desc.n;
    if (n < 5) {
      return AnalysisResult(
        method: AnalysisMethod.trimmedMean,
        metric: desc.mean,
        metricLabel: 'trim',
        metricUnit: '',
        outliers: const [],
        readout: 'n=$n — слишком мало для усечения.',
        conclusion: 'Нужно ≥ 5 точек, чтобы осмысленно отсечь хвосты.',
        descriptive: desc,
      );
    }
    final sorted = evidence.map((e) => e.value.toDouble()).toList()..sort();
    final k = (n * 0.2).floor();
    final kept = sorted.sublist(k, n - k);
    final trim = kept.reduce((a, b) => a + b) / kept.length;
    // Устойчивый разброс на «теле» выборки — для отсева крайних точек.
    final keptVar =
        kept.map((x) => (x - trim) * (x - trim)).reduce((a, b) => a + b) /
            kept.length;
    final keptStd = math.sqrt(keptVar);
    final shift = (desc.mean - trim).abs();
    final hits = <OutlierHit>[];
    if (keptStd > 0) {
      for (final e in evidence) {
        final rz = (e.value.toDouble() - trim) / keptStd;
        if (rz.abs() > 3) {
          hits.add(OutlierHit(
            evidence: e,
            score: rz.abs(),
            scoreLabel: 'отклон. ${rz.toStringAsFixed(1)}·σ_тела',
          ));
        }
      }
      hits.sort((a, b) => b.score.compareTo(a.score));
    }
    final bigShift = desc.std > 0 && shift > 0.5 * desc.std;
    return AnalysisResult(
      method: AnalysisMethod.trimmedMean,
      metric: trim,
      metricLabel: 'trim',
      metricUnit: '',
      outliers: hits,
      readout: 'mean = ${desc.mean.toStringAsFixed(1)} · trim₂₀ = '
          '${trim.toStringAsFixed(1)} · сдвиг = ${shift.toStringAsFixed(1)} · '
          'усечено $k+$k из $n',
      conclusion: bigShift
          ? 'mean ≫ trim — среднее раздуто крайними значениями; устойчивый '
              'центр ≈ ${trim.toStringAsFixed(0)}.'
              '${hits.isEmpty ? '' : ' Тянет в сторону — ${hits.first.evidence.id}.'}'
          : 'mean ≈ trim — среднее устойчиво, крайние точки не искажают центр.',
      descriptive: desc,
    );
  }

  /// Критерий Граббса: тест ровно одного выброса при α = 0.05.
  static AnalysisResult grubbs(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final n = desc.n;
    if (n < 3 || desc.std == 0) {
      return AnalysisResult(
        method: AnalysisMethod.grubbs,
        metric: 0,
        metricLabel: 'G',
        metricUnit: '',
        outliers: const [],
        readout: 'n=$n · σ=${desc.std.toStringAsFixed(2)} — тест неприменим.',
        conclusion: 'Нужно ≥ 3 точек и ненулевой разброс.',
        descriptive: desc,
      );
    }
    EvidenceEntity? maxE;
    var maxG = 0.0;
    for (final e in evidence) {
      final g = (e.value.toDouble() - desc.mean).abs() / desc.std;
      if (g > maxG) {
        maxG = g;
        maxE = e;
      }
    }
    final gCrit = _grubbsCritical(n);
    final significant = maxG > gCrit;
    final hits = <OutlierHit>[
      if (significant && maxE != null)
        OutlierHit(
          evidence: maxE,
          score: maxG,
          scoreLabel:
              'G = ${maxG.toStringAsFixed(2)} > ${gCrit.toStringAsFixed(2)}',
        ),
    ];
    return AnalysisResult(
      method: AnalysisMethod.grubbs,
      metric: maxG,
      metricLabel: 'G',
      metricUnit: '',
      outliers: hits,
      readout: 'G = ${maxG.toStringAsFixed(2)} · крит. ${gCrit.toStringAsFixed(2)} '
          '(n=$n, α=0.05) · кандидат ${maxE?.id ?? '—'}',
      conclusion: significant
          ? 'G > G_крит: ${maxE?.id} — статистически значимый выброс '
              '(отвергаем гипотезу об отсутствии выброса).'
          : 'G ≤ G_крит: значимого выброса нет, отклонения в пределах нормальной '
              'изменчивости.',
      descriptive: desc,
    );
  }

  /// Контрольная карта Шухарта + CUSUM по порядку во времени: ловит и
  /// одиночный вылет за μ ± 3σ, и накопленный дрейф/вброс.
  static AnalysisResult controlChart(List<EvidenceEntity> evidence) {
    final desc = describe(evidence);
    final n = desc.n;
    if (n < 4 || desc.std == 0) {
      return AnalysisResult(
        method: AnalysisMethod.controlChart,
        metric: 0,
        metricLabel: 'Σ/σ',
        metricUnit: '',
        outliers: const [],
        readout: 'n=$n · σ=${desc.std.toStringAsFixed(2)} — карта неинформативна.',
        conclusion: 'Нужно ≥ 4 точек и ненулевой разброс.',
        descriptive: desc,
      );
    }
    final ordered = [...evidence]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final ucl = desc.mean + 3 * desc.std;
    final lcl = desc.mean - 3 * desc.std;
    final hits = <OutlierHit>[];
    var cusum = 0.0;
    var maxAbsCusum = 0.0;
    for (final e in ordered) {
      final v = e.value.toDouble();
      cusum += v - desc.mean;
      if (cusum.abs() > maxAbsCusum) maxAbsCusum = cusum.abs();
      if (v > ucl || v < lcl) {
        final z = (v - desc.mean) / desc.std;
        hits.add(OutlierHit(
          evidence: e,
          score: z.abs(),
          scoreLabel: 'вне ±3σ (z=${z.toStringAsFixed(1)})',
        ));
      }
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    final driftSigma = maxAbsCusum / desc.std;
    return AnalysisResult(
      method: AnalysisMethod.controlChart,
      metric: driftSigma,
      metricLabel: 'Σ/σ',
      metricUnit: '',
      outliers: hits,
      readout: 'μ=${desc.mean.toStringAsFixed(1)} · σ=${desc.std.toStringAsFixed(1)} · '
          'UCL/LCL=μ±3σ · вне пределов: ${hits.length} · '
          'макс. дрейф ${driftSigma.toStringAsFixed(1)}σ',
      conclusion: hits.isEmpty
          ? 'Все точки внутри контрольных пределов — процесс стабилен, резкого '
              'вброса по времени не видно.'
          : 'Выход за ±3σ: ${hits.length}. В момент ${hits.first.evidence.id} '
              'процесс вышел из-под контроля — вероятный вброс.',
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
      case AnalysisMethod.trimmedMean:
        return trimmedMean(evidence);
      case AnalysisMethod.grubbs:
        return grubbs(evidence);
      case AnalysisMethod.controlChart:
        return controlChart(evidence);
    }
  }

  /// Распределение первых значащих цифр — единая основа и для метрики
  /// BENFORD, и для bar-chart. Возвращает частоты, доли (0..1), эталон
  /// Бенфорда и флаг «избыточности» каждой цифры (один критерий выбросов).
  static BenfordDistribution firstDigitDistribution(
      List<EvidenceEntity> evidence) {
    final counts = List<int>.filled(9, 0);
    var total = 0;
    for (final e in evidence) {
      final d = _firstDigit(e.value);
      if (d >= 1 && d <= 9) {
        counts[d - 1]++;
        total++;
      }
    }
    final observed = List<double>.filled(9, 0);
    final expected = List<double>.filled(9, 0);
    final suspect = List<bool>.filled(9, false);
    for (var d = 1; d <= 9; d++) {
      final expFrac = math.log(1 + 1 / d) / math.ln10;
      expected[d - 1] = expFrac;
      observed[d - 1] = total == 0 ? 0 : counts[d - 1] / total;
      final expCount = expFrac * total;
      suspect[d - 1] =
          total > 0 && expCount > 0 && counts[d - 1] > expCount + math.sqrt(expCount);
    }
    return BenfordDistribution(
      counts: counts,
      observed: observed,
      expected: expected,
      suspect: suspect,
      n: total,
    );
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

  /// Двусторонние критические значения критерия Граббса при α = 0.05
  /// для n = 3..30. За пределами таблицы — клампим к краям (в игре n ≈ 28).
  static double _grubbsCritical(int n) {
    const table = <int, double>{
      3: 1.155, 4: 1.481, 5: 1.715, 6: 1.887, 7: 2.020, 8: 2.127, //
      9: 2.215, 10: 2.290, 11: 2.355, 12: 2.412, 13: 2.462, 14: 2.507, //
      15: 2.549, 16: 2.585, 17: 2.620, 18: 2.651, 19: 2.681, 20: 2.709, //
      21: 2.733, 22: 2.758, 23: 2.781, 24: 2.802, 25: 2.822, 26: 2.841, //
      27: 2.859, 28: 2.876, 29: 2.893, 30: 2.908,
    };
    if (n <= 3) return table[3]!;
    if (n >= 30) return table[30]!;
    return table[n] ?? table[30]!;
  }
}
