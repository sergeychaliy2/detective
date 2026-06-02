import 'package:equatable/equatable.dart';

import '../../../case_board/domain/entities/case_entity.dart';
import '../../../profile/domain/entities/player_state.dart';
import 'analysis_method.dart';
import 'analysis_result.dart';
import 'evidence_entity.dart';
import 'investigation_stage.dart';
import 'protocol_entry.dart';
import 'stage_requirements.dart';
import 'suspect_entity.dart';

/// Закрытый числовой диапазон [min, max] для фильтра по value в DATA.
class ValueFilter extends Equatable {
  const ValueFilter({required this.min, required this.max});
  final num min;
  final num max;

  bool contains(num v) => v >= min && v <= max;

  @override
  List<Object?> get props => [min, max];
}

class InvestigationState extends Equatable {
  const InvestigationState({
    required this.caseInfo,
    required this.currentStage,
    required this.activeTab,
    required this.evidence,
    required this.suspects,
    required this.completedStages,
    required this.mentorVisible,
    required this.verdictRequested,
    required this.outcome,
    required this.viewedEvidenceIds,
    required this.viewedTabs,
    required this.evidenceLinks,
    required this.protocol,
    required this.revealedHintStages,
    required this.lifehackUsed,
    required this.sortDescending,
    required this.methodResults,
    required this.derivedColumns,
    this.selectedEvidenceId,
    this.valueFilter,
    this.activeMethod,
    this.pathFrom,
    this.pathTo,
    this.shortestPath,
  });

  factory InvestigationState.initial({
    required CaseEntity caseInfo,
    required List<EvidenceEntity> evidence,
    required List<SuspectEntity> suspects,
  }) =>
      InvestigationState(
        caseInfo: caseInfo,
        currentStage: InvestigationStage.intake,
        activeTab: WorkspaceTab.data,
        evidence: evidence,
        suspects: suspects,
        completedStages: const {},
        mentorVisible: caseInfo.difficulty != CaseDifficulty.exam,
        verdictRequested: false,
        outcome: null,
        viewedEvidenceIds: const {},
        viewedTabs: const {WorkspaceTab.data},
        evidenceLinks: const {},
        protocol: const [],
        revealedHintStages: const {},
        lifehackUsed: false,
        sortDescending: false,
        methodResults: const {},
        derivedColumns: const {},
        selectedEvidenceId: null,
        valueFilter: null,
        activeMethod: null,
        pathFrom: null,
        pathTo: null,
        shortestPath: null,
      );

  final CaseEntity caseInfo;
  final InvestigationStage currentStage;
  final WorkspaceTab activeTab;
  final List<EvidenceEntity> evidence;
  final List<SuspectEntity> suspects;
  final Set<InvestigationStage> completedStages;
  final bool mentorVisible;

  /// Игрок открыл overlay вердикта (но ещё не подал).
  final bool verdictRequested;

  /// Финальный исход. null = расследование идёт.
  final CaseOutcome? outcome;

  /// Идентификаторы улик, по которым игрок «кликнул».
  final Set<String> viewedEvidenceIds;

  /// Какие вкладки игрок открыл хоть раз.
  final Set<WorkspaceTab> viewedTabs;

  /// evidenceId → suspectId. Привязки игрока на этапе SUSPECTS.
  final Map<String, String> evidenceLinks;

  /// Лента протокола: что и почему сделал игрок.
  final List<ProtocolEntry> protocol;

  /// Стадии, для которых игрок раскрыл подсказку (1 раз / стадия).
  final Set<InvestigationStage> revealedHintStages;

  /// True если использовал лайфхак (раскрыта smoking-gun-улика).
  final bool lifehackUsed;

  /// Направление сортировки таблицы DATA (по timestamp).
  final bool sortDescending;

  /// Результаты применённых аналитических методов.
  final Map<AnalysisMethod, AnalysisResult> methodResults;

  /// Производные колонки, добавленные в DATA.
  final Set<DerivedColumn> derivedColumns;

  /// Активный (последний выбранный) метод — для рендера правой панели в ANALYSIS.
  final AnalysisMethod? activeMethod;

  /// Выделенная в DATA улика (для подсветки в NETWORK / для привязки).
  final String? selectedEvidenceId;

  /// Фильтр по value в DATA. null = выключен.
  final ValueFilter? valueFilter;

  /// Pathfinding в NETWORK.
  final String? pathFrom;
  final String? pathTo;
  final List<String>? shortestPath;

  bool get isExam => caseInfo.difficulty == CaseDifficulty.exam;

  int get flaggedCount => evidence.where((e) => e.flagged).length;

  /// Улики, прошедшие через текущий valueFilter (или все, если фильтра нет).
  List<EvidenceEntity> get filteredEvidence {
    final f = valueFilter;
    if (f == null) return evidence;
    return evidence.where((e) => f.contains(e.value)).toList();
  }

  /// Сколько улик скрыто фильтром (для счётчика в DATA).
  int get hiddenByFilter {
    final f = valueFilter;
    if (f == null) return 0;
    return evidence.length - filteredEvidence.length;
  }

  /// Числовой счётчик метрики гейта.
  int metric(StageMetric m) {
    switch (m) {
      case StageMetric.evidenceViewed:
        return viewedEvidenceIds.length;
      case StageMetric.flagsPlaced:
        return flaggedCount + (valueFilter != null ? 1 : 0);
      case StageMetric.analysisOpened:
        // Теперь это: «применён хотя бы один метод».
        return methodResults.isEmpty ? 0 : 1;
      case StageMetric.evidenceLinked:
        return evidenceLinks.length;
    }
  }

  /// Собирает список «требование → текущее значение» для текущего этапа.
  List<(StageRequirement, int)> currentStageProgress() {
    final reqs = stageGateRequirements[currentStage] ?? const [];
    return [for (final r in reqs) (r, metric(r.code))];
  }

  bool get canAdvance {
    final reqs = stageGateRequirements[currentStage] ?? const [];
    return reqs.every((r) => metric(r.code) >= r.target);
  }

  double get stageProgress {
    const total = InvestigationStage.values;
    final done = completedStages.length;
    return done / total.length;
  }

  InvestigationState copyWith({
    InvestigationStage? currentStage,
    WorkspaceTab? activeTab,
    List<EvidenceEntity>? evidence,
    List<SuspectEntity>? suspects,
    Set<InvestigationStage>? completedStages,
    bool? mentorVisible,
    bool? verdictRequested,
    CaseOutcome? outcome,
    Set<String>? viewedEvidenceIds,
    Set<WorkspaceTab>? viewedTabs,
    Map<String, String>? evidenceLinks,
    List<ProtocolEntry>? protocol,
    Set<InvestigationStage>? revealedHintStages,
    bool? lifehackUsed,
    bool? sortDescending,
    Map<AnalysisMethod, AnalysisResult>? methodResults,
    Set<DerivedColumn>? derivedColumns,
    AnalysisMethod? activeMethod,
    String? selectedEvidenceId,
    ValueFilter? valueFilter,
    String? pathFrom,
    String? pathTo,
    List<String>? shortestPath,
    bool clearOutcome = false,
    bool clearSelection = false,
    bool clearActiveMethod = false,
    bool clearValueFilter = false,
    bool clearPath = false,
  }) {
    return InvestigationState(
      caseInfo: caseInfo,
      currentStage: currentStage ?? this.currentStage,
      activeTab: activeTab ?? this.activeTab,
      evidence: evidence ?? this.evidence,
      suspects: suspects ?? this.suspects,
      completedStages: completedStages ?? this.completedStages,
      mentorVisible: mentorVisible ?? this.mentorVisible,
      verdictRequested: verdictRequested ?? this.verdictRequested,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      viewedEvidenceIds: viewedEvidenceIds ?? this.viewedEvidenceIds,
      viewedTabs: viewedTabs ?? this.viewedTabs,
      evidenceLinks: evidenceLinks ?? this.evidenceLinks,
      protocol: protocol ?? this.protocol,
      revealedHintStages: revealedHintStages ?? this.revealedHintStages,
      lifehackUsed: lifehackUsed ?? this.lifehackUsed,
      sortDescending: sortDescending ?? this.sortDescending,
      methodResults: methodResults ?? this.methodResults,
      derivedColumns: derivedColumns ?? this.derivedColumns,
      activeMethod: clearActiveMethod ? null : (activeMethod ?? this.activeMethod),
      selectedEvidenceId:
          clearSelection ? null : (selectedEvidenceId ?? this.selectedEvidenceId),
      valueFilter: clearValueFilter ? null : (valueFilter ?? this.valueFilter),
      pathFrom: clearPath ? null : (pathFrom ?? this.pathFrom),
      pathTo: clearPath ? null : (pathTo ?? this.pathTo),
      shortestPath: clearPath ? null : (shortestPath ?? this.shortestPath),
    );
  }

  @override
  List<Object?> get props => [
        caseInfo,
        currentStage,
        activeTab,
        evidence,
        suspects,
        completedStages,
        mentorVisible,
        verdictRequested,
        outcome,
        viewedEvidenceIds,
        viewedTabs,
        evidenceLinks,
        protocol,
        revealedHintStages,
        lifehackUsed,
        sortDescending,
        methodResults,
        derivedColumns,
        activeMethod,
        selectedEvidenceId,
        valueFilter,
        pathFrom,
        pathTo,
        shortestPath,
      ];
}
