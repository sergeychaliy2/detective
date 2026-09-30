import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../investigation/domain/entities/analysis_method.dart';

/// Уровень сложности дела (по концепции "Тень числа":
/// обучающий / практика / экзаменационный).
enum CaseDifficulty {
  trainee('OP-T', 'ОБУЧАЮЩИЙ', '15–30 МИН', AppColors.hologramBlue),
  practice('OP-P', 'ПРАКТИКА', '45–90 МИН', AppColors.neonCyan),
  exam('OP-X', 'ЭКЗАМЕН', '2–3 ЧАСА', AppColors.magenta);

  const CaseDifficulty(this.code, this.label, this.duration, this.color);

  final String code;
  final String label;
  final String duration;
  final Color color;
}

/// Жизненный цикл дела.
enum CaseStatus {
  locked('ЗАБЛОКИРОВАНО', AppColors.textMuted),
  available('ДОСТУПНО', AppColors.neonCyan),
  inProgress('В РАБОТЕ', AppColors.amberWarning),
  solved('ЗАКРЫТО', AppColors.jadeSuccess),
  failed('ПРОВАЛЕНО', AppColors.crimsonError);

  const CaseStatus(this.label, this.color);

  final String label;
  final Color color;
}

/// Тематическая глава, в которую входит дело.
enum CaseTheme {
  finance('ФИНАНСЫ', 'Аномалии в транзакциях'),
  biostatistics('БИОСТАТИСТИКА', 'Поиск нулевого пациента'),
  sociology('СОЦИОЛОГИЯ', 'Электоральные аномалии'),
  econometrics('ЭКОНОМЕТРИКА', 'Прогноз обвалов рынка'),
  cryptography('КРИПТОГРАФИЯ', 'Расшифровка переписки');

  const CaseTheme(this.label, this.tagline);

  final String label;
  final String tagline;
}

class CaseEntity extends Equatable {
  const CaseEntity({
    required this.id,
    required this.code,
    required this.title,
    required this.brief,
    required this.theme,
    required this.difficulty,
    required this.status,
    required this.rewardXp,
    required this.dataPoints,
    required this.suspects,
    required this.evidenceTypes,
    required this.solutionSuspectId,
    required this.solutionValue,
    required this.solutionTolerance,
    required this.solutionRationale,
    required this.solutionEvidenceKindIndex,
    required this.theoryHints,
    required this.solutionMethod,
    this.isTutorial = false,
    this.noiseMean = 1500,
    this.noiseStd = 600,
  });

  final String id;
  final String code;
  final String title;
  final String brief;
  final CaseTheme theme;
  final CaseDifficulty difficulty;
  final CaseStatus status;
  final int rewardXp;
  final int dataPoints;
  final int suspects;
  final List<String> evidenceTypes;

  /// ID правильного подозреваемого. Сверяется на этапе вердикта.
  final String solutionSuspectId;

  /// "Улика-цифра": число, доказывающее обвинение (p-value × 1000,
  /// сумма транзакции, и т.п. — зависит от темы дела).
  final num solutionValue;

  /// Допустимое отклонение игрока от правильного значения.
  final num solutionTolerance;

  /// Объяснение, почему именно это число — выводится по подсказке.
  final String solutionRationale;

  /// Индекс EvidenceKind, в котором "сидит" улика-цифра. Используется
  /// процедурным сидером, чтобы посадить аномалию в нужный тип.
  final int solutionEvidenceKindIndex;

  /// Контекстные подсказки наставника по этапам (5 штук, по числу
  /// этапов следствия). Полнотекстовая теория — тут же.
  final List<String> theoryHints;

  /// Аналитический метод, который наиболее ясно вскрывает аномалию
  /// этого дела. Использование «правильного» метода даёт +XP-бонус
  /// и подсвечивается в OutcomeOverlay как «элегантное решение».
  final AnalysisMethod solutionMethod;

  /// Дело-туториал: помечается бейджем «ТУТОРИАЛ» и ведёт игрока пошагово.
  final bool isTutorial;

  /// Параметры шумового распределения для процедурной генерации улик.
  final num noiseMean;
  final num noiseStd;

  bool isVerdictCorrect({required String suspectId, required num value}) {
    if (suspectId != solutionSuspectId) return false;
    return (value - solutionValue).abs() <= solutionTolerance;
  }

  CaseEntity copyWith({CaseStatus? status}) => CaseEntity(
        id: id,
        code: code,
        title: title,
        brief: brief,
        theme: theme,
        difficulty: difficulty,
        status: status ?? this.status,
        rewardXp: rewardXp,
        dataPoints: dataPoints,
        suspects: suspects,
        evidenceTypes: evidenceTypes,
        solutionSuspectId: solutionSuspectId,
        solutionValue: solutionValue,
        solutionTolerance: solutionTolerance,
        solutionRationale: solutionRationale,
        solutionEvidenceKindIndex: solutionEvidenceKindIndex,
        theoryHints: theoryHints,
        solutionMethod: solutionMethod,
        isTutorial: isTutorial,
        noiseMean: noiseMean,
        noiseStd: noiseStd,
      );

  @override
  List<Object?> get props => [
        id,
        code,
        title,
        brief,
        theme,
        difficulty,
        status,
        rewardXp,
        dataPoints,
        suspects,
        evidenceTypes,
        solutionSuspectId,
        solutionValue,
        solutionTolerance,
        solutionRationale,
        solutionEvidenceKindIndex,
        theoryHints,
        solutionMethod,
        isTutorial,
        noiseMean,
        noiseStd,
      ];
}
