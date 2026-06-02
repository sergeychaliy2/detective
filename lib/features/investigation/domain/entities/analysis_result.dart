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
    required this.summary,
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

  /// Свободная строка: "Найдено 1 outlier. Самая аномальная — EV-0017".
  final String summary;

  final DescriptiveStats descriptive;

  bool get hasOutliers => outliers.isNotEmpty;

  /// Подсветка в UI: метод "сильный", если нашёл хотя бы один outlier.
  bool get isStrong => outliers.isNotEmpty;

  @override
  List<Object?> get props =>
      [method, metric, metricLabel, metricUnit, outliers, summary, descriptive];
}
