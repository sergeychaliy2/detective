import 'package:equatable/equatable.dart';

import 'analysis_method.dart';
import 'evidence_entity.dart';

/// Один outlier с пояснением, почему он выбивается.
class OutlierHit extends Equatable {
  const OutlierHit({
    required this.evidence,
    required this.score,
    required this.scoreLabel,
  });

  final EvidenceEntity evidence;

  /// Численный «вес» выброса (z, modified-z, residual χ², |d| и т.д.) —
  /// именно этим методы рейтят outlier-ов.
  final double score;

  /// Человекочитаемая подпись: "z = 3.2", "M = 4.1", "Δrank = 14".
  final String scoreLabel;

  @override
  List<Object?> get props => [evidence, score, scoreLabel];
}

/// Распределение первых значащих цифр (1..9) для визуализации Бенфорда.
/// Все списки длиной 9 (индекс 0 → цифра 1).
class BenfordDistribution extends Equatable {
  const BenfordDistribution({
    required this.counts,
    required this.observed,
    required this.expected,
    required this.suspect,
    required this.n,
  });

  /// Сырые частоты цифр.
  final List<int> counts;

  /// Наблюдаемые доли 0..1.
  final List<double> observed;

  /// Теоретические доли по Бенфорду 0..1.
  final List<double> expected;

  /// Цифра «избыточна»: наблюдаемая частота превышает ожидаемую больше
  /// чем на √exp (≈1σ пуассоновского счёта) — тот же критерий, по которому
  /// метод BENFORD помечает улики-выбросы. Единый источник истины.
  final List<bool> suspect;

  /// Число валидных точек (с извлекаемой первой цифрой).
  final int n;

  bool get hasSuspect => suspect.any((s) => s);

  @override
  List<Object?> get props => [counts, observed, expected, suspect, n];
}

/// Описательная статистика — фундамент, нужный всем остальным методам.
class DescriptiveStats extends Equatable {
  const DescriptiveStats({
    required this.n,
    required this.mean,
    required this.median,
    required this.std,
    required this.min,
    required this.max,
    required this.q1,
    required this.q3,
  });

  final int n;
  final double mean;
  final double median;
  final double std;
  final double min;
  final double max;
  final double q1;
  final double q3;

  double get iqr => q3 - q1;
  double get range => max - min;

  @override
  List<Object?> get props => [n, mean, median, std, min, max, q1, q3];
}

/// Результат применения одного аналитического метода ко всему массиву.
class AnalysisResult extends Equatable {
  const AnalysisResult({
    required this.method,
    required this.metric,
    required this.metricLabel,
    required this.metricUnit,
    required this.outliers,
    required this.readout,
    required this.conclusion,
    required this.descriptive,
  });

  final AnalysisMethod method;

  /// Главное число метода (σ, IQR, χ², ρ, ...).
  final double metric;

  /// "σ" / "IQR" / "χ²" / "ρ".
  final String metricLabel;

  /// Опционально единица: "" / "%". Нужно только чтобы не плодить пустые строки.
  final String metricUnit;

  /// Найденные выбросы, отсортированные по убыванию score.
  final List<OutlierHit> outliers;

  /// Нейтральная сводка ПОСЧИТАННОГО — только числа, без интерпретации.
  /// Видна всегда: "χ² = 48.1 (крит. 15.51, df=8) · n=28 · пики: 4/5/7".
  final String readout;

  /// ВЫВОД — словесная интерпретация результата. Скрыта до раскрытия
  /// игроком (бесплатно в обучении, со штрафом в практике, недоступна на экзамене).
  final String conclusion;

  final DescriptiveStats descriptive;

  bool get hasOutliers => outliers.isNotEmpty;

  /// Подсветка в UI: метод "сильный", если нашёл хотя бы один outlier.
  bool get isStrong => outliers.isNotEmpty;

  @override
  List<Object?> get props => [
        method,
        metric,
        metricLabel,
        metricUnit,
        outliers,
        readout,
        conclusion,
        descriptive,
      ];
}
