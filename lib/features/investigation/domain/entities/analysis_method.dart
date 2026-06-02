import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Аналитические методы, доступные на вкладке ANALYSIS.
/// Каждый метод применяется ко всему массиву evidence и возвращает
/// `AnalysisResult` (см. соседний файл).
enum AnalysisMethod {
  descriptive(
    code: 'DESCRIBE',
    title: 'ОПИСАТЕЛЬНАЯ СТАТИСТИКА',
    short: 'mean / median / std / range',
    color: AppColors.hologramBlue,
    formula: 'mean = Σx/n  ·  std = √(Σ(x-mean)²/n)  ·  median, IQR',
    when:
        'Применяй на этапе intake — даёт паспорт распределения: центр, разброс, диапазон. '
        'Outliers не выделяет, но числа из неё нужны для всех остальных методов.',
  ),
  zScore(
    code: 'Z-SCORE',
    title: 'Z-ОЦЕНКА (3σ)',
    short: '|z| > 3 → outlier',
    color: AppColors.neonCyan,
    formula: 'z_i = (x_i − μ) / σ   ·   outlier если |z| > 3',
    when:
        'Чувствительный детектор выбросов в нормальных распределениях. '
        'Слаб против скоса и бимодальности. Если данные явно не нормальны — бери MAD.',
  ),
  iqr(
    code: 'IQR',
    title: 'МЕЖКВАРТИЛЬНЫЙ РАЗМАХ',
    short: 'x < Q1 − 1.5·IQR  ·  x > Q3 + 1.5·IQR',
    color: AppColors.electricBlue,
    formula:
        'IQR = Q3 − Q1   ·   outlier если x < Q1 − 1.5·IQR или x > Q3 + 1.5·IQR',
    when:
        'Не зависит от формы распределения. Классика для boxplot-анализа. '
        'На малых выборках (n < 12) ведёт себя дёргано.',
  ),
  mad(
    code: 'MAD',
    title: 'MEDIAN ABS DEVIATION',
    short: 'modified-z > 3.5 → outlier',
    color: AppColors.violet,
    formula:
        'MAD = median(|x_i − median(x)|)   ·   M = 0.6745·(x − med)/MAD   ·   outlier если |M| > 3.5',
    when:
        'Самый устойчивый к выбросам метод (breakdown 50%). '
        'Идеален когда в данных может быть несколько подозрительных точек.',
  ),
  benford(
    code: 'BENFORD',
    title: 'ЗАКОН БЕНФОРДА (χ²)',
    short: 'отклонение first-digit распределения',
    color: AppColors.amberWarning,
    formula:
        'P(d) = log₁₀(1 + 1/d) для d ∈ 1..9   ·   χ² = Σ (obs − exp)²/exp · n',
    when:
        'Для естественных данных, охватывающих много порядков (финансы, выборы, население). '
        'Высокий χ² — подделка. Не работает на узких диапазонах вроде 0–10.',
  ),
  spearman(
    code: 'SPEARMAN',
    title: 'РАНГОВАЯ КОРРЕЛЯЦИЯ ρ',
    short: 'ρ ∈ [−1, +1]: монотонная связь value↔time',
    color: AppColors.magenta,
    formula:
        'ρ = 1 − 6·Σd² / (n·(n² − 1))   где d_i = rank(value_i) − rank(time_i)',
    when:
        'Ловит тренд, не предполагая линейность. |ρ| близка к 1 — есть монотонная связь. '
        'Outliers — точки, чей вклад в d² максимален (нарушители тренда).',
  );

  const AnalysisMethod({
    required this.code,
    required this.title,
    required this.short,
    required this.color,
    required this.formula,
    required this.when,
  });

  final String code;
  final String title;
  final String short;
  final Color color;
  final String formula;
  final String when;
}

/// Производные колонки, которые игрок может добавить к таблице DATA.
/// Считаются на лету по текущему массиву evidence.
enum DerivedColumn {
  zScore('Z', 'z = (x − μ)/σ', AppColors.neonCyan),
  log10('log', 'log₁₀(x)', AppColors.hologramBlue),
  diffMedian('Δmed', 'x − median', AppColors.violet);

  const DerivedColumn(this.label, this.formula, this.color);

  final String label;
  final String formula;
  final Color color;
}
