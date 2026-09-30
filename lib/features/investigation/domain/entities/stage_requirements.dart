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
  robustnessTried,
  analysisOpened,
  accusationBuilt,
}

/// Карта требований по этапам. Для verdict — пусто (туда переходим
/// через requestVerdict, не advanceStage).
///
/// intake — без условий: знакомство с массивом не должно быть busywork,
/// переход открыт сразу.
const Map<InvestigationStage, List<StageRequirement>> stageGateRequirements = {
  InvestigationStage.intake: [],
  InvestigationStage.cleanup: [
    StageRequirement(
      code: StageMetric.robustnessTried,
      label: 'ПРОБА ПОДМЕНЫ ЗНАЧЕНИЯ',
      target: 1,
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
      code: StageMetric.accusationBuilt,
      label: 'ОБВИНЕНИЕ СФОРМИРОВАНО',
      target: 1,
    ),
  ],
  InvestigationStage.verdict: [],
};
