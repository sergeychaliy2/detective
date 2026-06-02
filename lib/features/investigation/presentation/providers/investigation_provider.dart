import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../case_board/domain/entities/case_entity.dart';
import '../../../case_board/presentation/providers/case_board_providers.dart';
import '../../../profile/domain/entities/player_state.dart';
import '../../../profile/presentation/providers/player_provider.dart';
import '../../data/investigation_seed.dart';
import '../../domain/entities/analysis_method.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/investigation_stage.dart';
import '../../domain/entities/investigation_state.dart';
import '../../domain/entities/protocol_entry.dart';
import '../../domain/services/graph_metrics.dart';
import '../../domain/services/statistical_methods.dart';

/// Стоимость подсказки и лайфхака (XP / репутация).
class _MentorCost {
  static const int hintXp = 10;
  static const int hintRep = 1;
  static const int lifehackXp = 25;
  static const int lifehackRep = 3;
}

class InvestigationController extends StateNotifier<InvestigationState?> {
  InvestigationController(this._ref, CaseEntity? caseInfo)
      : super(_initial(caseInfo)) {
    if (caseInfo != null) {
      Future<void>.microtask(() {
        try {
          _ref
              .read(playerProvider.notifier)
              .markInProgress(caseId: caseInfo.id);
        } catch (_) {}
      });
    }
  }

  final Ref _ref;

  static InvestigationState? _initial(CaseEntity? c) {
    if (c == null) return null;
    return InvestigationState.initial(
      caseInfo: c,
      evidence: InvestigationSeed.evidenceFor(c),
      suspects: InvestigationSeed.suspectsFor(c.id),
    );
  }

  // ───────── Вкладки и просмотр улик ────────────────────────────────

  void setTab(WorkspaceTab tab) {
    final s = state;
    if (s == null) return;
    if (s.isExam && tab == WorkspaceTab.mentor) return;
    state = s.copyWith(
      activeTab: tab,
      viewedTabs: {...s.viewedTabs, tab},
    );
  }

  void touchEvidence(String evidenceId) {
    final s = state;
    if (s == null) return;
    if (s.viewedEvidenceIds.contains(evidenceId) &&
        s.selectedEvidenceId == evidenceId) {
      return;
    }
    state = s.copyWith(
      viewedEvidenceIds: {...s.viewedEvidenceIds, evidenceId},
      selectedEvidenceId: evidenceId,
    );
  }

  void clearEvidenceSelection() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(clearSelection: true);
  }

  void toggleSort() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(sortDescending: !s.sortDescending);
  }

  void toggleFlag(String evidenceId) {
    final s = state;
    if (s == null) return;
    final next = [
      for (final e in s.evidence)
        if (e.id == evidenceId) e.copyWith(flagged: !e.flagged) else e,
    ];
    final touched = {...s.viewedEvidenceIds, evidenceId};
    final flippedTo = next.firstWhere((e) => e.id == evidenceId).flagged;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.flag,
      message: flippedTo ? 'FLAG SET // $evidenceId' : 'FLAG OFF // $evidenceId',
    );
    state = s.copyWith(
      evidence: next,
      viewedEvidenceIds: touched,
      protocol: [entry, ...s.protocol],
    );
  }

  void linkSelectedEvidenceTo(String suspectId) {
    final s = state;
    if (s == null) return;
    final eid = s.selectedEvidenceId;
    if (eid == null) return;
    final next = {...s.evidenceLinks, eid: suspectId};
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.link,
      message: 'LINK // $eid → $suspectId',
    );
    state = s.copyWith(
      evidenceLinks: next,
      protocol: [entry, ...s.protocol],
    );
  }

  // ───────── ANALYSIS: статистические методы ────────────────────────

  /// Применить метод. Считает по всем улик (не filtered — игрок может
  /// явно сравнивать «до/после»). Сохраняет в `methodResults`.
  AnalysisResult applyMethod(AnalysisMethod method) {
    final s = state;
    if (s == null) {
      throw StateError('investigation not initialized');
    }
    final result = StatisticalMethods.apply(method, s.evidence);
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.method,
      message:
          'METHOD // ${method.code}: ${result.metricLabel} = ${result.metric.toStringAsFixed(2)}, '
          '${result.outliers.length} outlier(s)',
    );
    state = s.copyWith(
      methodResults: {...s.methodResults, method: result},
      activeMethod: method,
      protocol: [entry, ...s.protocol],
    );
    return result;
  }

  void selectMethod(AnalysisMethod method) {
    final s = state;
    if (s == null) return;
    if (!s.methodResults.containsKey(method)) return;
    state = s.copyWith(activeMethod: method);
  }

  void removeMethod(AnalysisMethod method) {
    final s = state;
    if (s == null) return;
    final next = {...s.methodResults}..remove(method);
    state = s.copyWith(
      methodResults: next,
      activeMethod: s.activeMethod == method ? null : s.activeMethod,
      clearActiveMethod: s.activeMethod == method,
    );
  }

  // ───────── DATA: фильтр и derived columns ─────────────────────────

  void setValueFilter({required num min, required num max}) {
    final s = state;
    if (s == null) return;
    if (max < min) return;
    final f = ValueFilter(min: min, max: max);
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.filter,
      message: 'FILTER // value ∈ [$min, $max] — скрыто '
          '${s.evidence.length - s.evidence.where((e) => f.contains(e.value)).length}',
    );
    state = s.copyWith(
      valueFilter: f,
      protocol: [entry, ...s.protocol],
    );
  }

  void clearValueFilter() {
    final s = state;
    if (s == null || s.valueFilter == null) return;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.filter,
      message: 'FILTER OFF',
    );
    state = s.copyWith(
      clearValueFilter: true,
      protocol: [entry, ...s.protocol],
    );
  }

  void toggleDerivedColumn(DerivedColumn col) {
    final s = state;
    if (s == null) return;
    final next = {...s.derivedColumns};
    final added = !next.contains(col);
    if (added) {
      next.add(col);
    } else {
      next.remove(col);
    }
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.derived,
      message: '${added ? 'ADD' : 'REMOVE'} COL // ${col.label} (${col.formula})',
    );
    state = s.copyWith(
      derivedColumns: next,
      protocol: [entry, ...s.protocol],
    );
  }

  // ───────── NETWORK: pathfinding ───────────────────────────────────

  void setPathEndpoints({String? from, String? to}) {
    final s = state;
    if (s == null) return;
    final newFrom = from ?? s.pathFrom;
    final newTo = to ?? s.pathTo;
    if (newFrom == null || newTo == null) {
      state = s.copyWith(
        pathFrom: from,
        pathTo: to,
      );
      return;
    }
    final graph = SuspectGraph.build(
      suspects: s.suspects,
      evidence: s.evidence,
      evidenceLinks: s.evidenceLinks,
    );
    final path = graph.shortestPath(newFrom, newTo);
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.path,
      message: path == null
          ? 'PATH // $newFrom ✕ $newTo (нет связи)'
          : 'PATH // ${path.join(' → ')} (длина ${path.length - 1})',
    );
    state = s.copyWith(
      pathFrom: newFrom,
      pathTo: newTo,
      shortestPath: path,
      protocol: [entry, ...s.protocol],
    );
  }

  void clearPath() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(clearPath: true);
  }

  // ───────── Подсказки и лайфхак ────────────────────────────────────

  bool get mentorAvailable {
    final s = state;
    if (s == null) return false;
    return !s.isExam;
  }

  String? requestHint() {
    final s = state;
    if (s == null || s.isExam) return null;
    if (s.revealedHintStages.contains(s.currentStage)) return null;
    final hints = s.caseInfo.theoryHints;
    final i = InvestigationStage.values.indexOf(s.currentStage);
    if (i < 0 || i >= hints.length) return null;
    final text = hints[i];
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.hint,
      message: 'HINT // ${s.currentStage.code} — $text',
    );
    state = s.copyWith(
      revealedHintStages: {...s.revealedHintStages, s.currentStage},
      protocol: [entry, ...s.protocol],
    );
    _ref.read(playerProvider.notifier).chargeHint(
          amount: _MentorCost.hintXp,
          reputationLoss: _MentorCost.hintRep,
        );
    return text;
  }

  String? requestLifehack() {
    final s = state;
    if (s == null || s.isExam || s.lifehackUsed) return null;
    final guns = s.evidence.where((e) => e.isSmokingGun).toList();
    if (guns.isEmpty) return null;
    final gun = guns.first;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: s.currentStage,
      kind: ProtocolKind.lifehack,
      message:
          'LIFEHACK // smoking-gun = ${gun.id}, value=${gun.value}, suspect=${gun.suspectId}',
    );
    state = s.copyWith(
      lifehackUsed: true,
      selectedEvidenceId: gun.id,
      viewedEvidenceIds: {...s.viewedEvidenceIds, gun.id},
      protocol: [entry, ...s.protocol],
    );
    _ref.read(playerProvider.notifier).chargeHint(
          amount: _MentorCost.lifehackXp,
          reputationLoss: _MentorCost.lifehackRep,
        );
    return gun.id;
  }

  // ───────── Этапы / вердикт / откат ────────────────────────────────

  void advanceStage() {
    final s = state;
    if (s == null) return;
    if (s.currentStage == InvestigationStage.verdict) {
      requestVerdict();
      return;
    }
    if (!s.canAdvance) return;
    final stages = InvestigationStage.values;
    final idx = stages.indexOf(s.currentStage);
    final next = idx + 1 < stages.length ? stages[idx + 1] : s.currentStage;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: next,
      kind: ProtocolKind.stage,
      message: 'STAGE // ${s.currentStage.code} → ${next.code}',
    );
    state = s.copyWith(
      currentStage: next,
      completedStages: {...s.completedStages, s.currentStage},
      protocol: [entry, ...s.protocol],
    );
  }

  void requestVerdict() {
    final s = state;
    if (s == null) return;
    if (!s.canAdvance && s.currentStage != InvestigationStage.verdict) return;
    state = s.copyWith(
      verdictRequested: true,
      currentStage: InvestigationStage.verdict,
      completedStages: {...s.completedStages, s.currentStage},
    );
  }

  void cancelVerdict() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(verdictRequested: false);
  }

  /// Подача вердикта. Возвращает true если правильно.
  bool submitVerdict({required String suspectId, required num value}) {
    final s = state;
    if (s == null) return false;
    final correct = s.caseInfo.isVerdictCorrect(
      suspectId: suspectId,
      value: value,
    );
    final outcome = correct ? CaseOutcome.solved : CaseOutcome.failed;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: InvestigationStage.verdict,
      kind: ProtocolKind.verdict,
      message: 'VERDICT // suspect=$suspectId, value=$value → ${outcome.label}',
    );
    state = s.copyWith(
      verdictRequested: false,
      outcome: outcome,
      completedStages: {...s.completedStages, InvestigationStage.verdict},
      protocol: [entry, ...s.protocol],
    );
    // Бонус за «элегантное решение»: правильный метод применён.
    final usedSolutionMethod = s.methodResults.containsKey(s.caseInfo.solutionMethod);
    final reward = correct && usedSolutionMethod
        ? (s.caseInfo.rewardXp * 1.25).round()
        : s.caseInfo.rewardXp;
    _ref.read(playerProvider.notifier).recordOutcome(
          caseId: s.caseInfo.id,
          caseCode: s.caseInfo.code,
          caseTitle: s.caseInfo.title,
          outcome: outcome,
          rewardXp: reward,
        );
    return correct;
  }

  void rollback() {
    final s = state;
    if (s == null || s.isExam) return;
    final stages = InvestigationStage.values;
    final idx = stages.indexOf(s.currentStage);
    final prev = idx > 0 ? stages[idx - 1] : s.currentStage;
    final entry = ProtocolEntry(
      timestamp: DateTime.now(),
      stage: prev,
      kind: ProtocolKind.stage,
      message: 'ROLLBACK // ${s.currentStage.code} → ${prev.code}',
    );
    state = s.copyWith(
      currentStage: prev,
      clearOutcome: true,
      verdictRequested: false,
      completedStages: {...s.completedStages}..remove(prev),
      protocol: [entry, ...s.protocol],
    );
    _ref.read(playerProvider.notifier).registerRollback();
  }

  void toggleMentor() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(mentorVisible: !s.mentorVisible);
  }
}

final investigationProvider = StateNotifierProvider.family
    .autoDispose<InvestigationController, InvestigationState?, String>(
  (ref, caseId) {
    final async = ref.watch(caseListProvider);
    final c = async.maybeWhen(
      data: (list) =>
          list.firstWhere((x) => x.id == caseId, orElse: () => list.first),
      orElse: () => null,
    );
    return InvestigationController(ref, c);
  },
);
