import 'investigation_stage.dart';

/// Условия, которые игрок должен выполнить, чтобы перейти на следующий этап.
/// Список выводится в UI ("checklist") и проверяется перед advanceStage.
class StageRequirement {
  const StageRequirement({
    required this.code,
    required this.label,
    required this.target,
  });

  /// Машинный ключ — какой счётчик считаем (см. InvestigationState).
  final StageMetric code;

  /// Человекочитаемый текст: "Просмотрено улик: 4 / 6".
  final String label;

  /// Сколько нужно набрать.
  final int target;
}

enum StageMetric {
  evidenceViewed,
  flagsPlaced,
  analysisOpened,
  evidenceLinked,
}

/// Карта требований по этапам. Для verdict — пусто (туда переходим
/// через requestVerdict, не advanceStage).
const Map<InvestigationStage, List<StageRequirement>> stageGateRequirements = {
  InvestigationStage.intake: [
    StageRequirement(
      code: StageMetric.evidenceViewed,
      label: 'ИЗУЧЕНО УЛИК',
      target: 6,
    ),
  ],
  InvestigationStage.cleanup: [
    StageRequirement(
      code: StageMetric.flagsPlaced,
      label: 'ФЛАГИ ИЛИ VALUE-ФИЛЬТР',
      target: 2,
    ),
  ],
  InvestigationStage.analysis: [
    StageRequirement(
      code: StageMetric.analysisOpened,
      label: 'ПРИМЕНЁН СТАТ-МЕТОД',
      target: 1,
    ),
  ],
  InvestigationStage.suspects: [
    StageRequirement(
      code: StageMetric.evidenceLinked,
      label: 'ПРИВЯЗАНО УЛИК К ФИГУРАНТАМ',
      target: 2,
    ),
  ],
  InvestigationStage.verdict: [],
};
