import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/analysis_method.dart';
import '../domain/entities/analysis_result.dart';
import '../domain/entities/investigation_stage.dart';
import '../domain/entities/investigation_state.dart';
import '../domain/services/statistical_methods.dart';

/// Сохраняет и восстанавливает прогресс расследования между сессиями.
/// Ключ: `inv_snap_<caseId>`. Удаляется при финальном исходе (solved/failed).
class InvestigationPersistence {
  InvestigationPersistence._();

  // Увеличивать при изменении формата — старые сохранения будут сброшены.
  static const _schemaVersion = 3;

  static const _prefix = 'inv_snap_';
  static String _key(String caseId) => '$_prefix$caseId';

  // ── Save ──────────────────────────────────────────────────────────────

  static Future<void> save(String caseId, InvestigationState s) async {
    if (s.outcome != null) {
      // Финальный исход — удалить снапшот, следующий старт будет чистым
      await clear(caseId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final data = <String, dynamic>{
      'version': _schemaVersion,
      'currentStage': s.currentStage.name,
      'activeTab': s.activeTab.name,
      'completedStages':
          s.completedStages.map((e) => e.name).toList(),
      'viewedEvidenceIds': s.viewedEvidenceIds.toList(),
      'evidenceLinks': s.evidenceLinks,
      'revealedHintStages':
          s.revealedHintStages.map((e) => e.name).toList(),
      'lifehackUsed': s.lifehackUsed,
      'sortDescending': s.sortDescending,
      'selectedEvidenceId': s.selectedEvidenceId,
      'appliedMethods':
          s.methodResults.keys.map((m) => m.name).toList(),
      'activeMethod': s.activeMethod?.name,
      'whatIfTried': s.whatIfTried,
      'revealedConclusions':
          s.revealedConclusions.map((m) => m.name).toList(),
      'accusedSuspectId': s.accusedSuspectId,
      'clearedSuspectIds': s.clearedSuspectIds.toList(),
    };
    await prefs.setString(_key(caseId), jsonEncode(data));
  }

  // ── Load + apply ──────────────────────────────────────────────────────

  /// Загружает снапшот и возвращает обновлённое состояние.
  /// Возвращает [base] без изменений, если снапшота нет или он повреждён.
  static Future<InvestigationState> restore(
    String caseId,
    InvestigationState base,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(caseId));
    if (raw == null) return base;

    late final Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return base;
    }

    // Устаревший формат — сбрасываем, чтобы избежать некорректного состояния.
    final version = data['version'] as int? ?? 1;
    if (version < _schemaVersion) {
      await clear(caseId);
      return base;
    }

    // ── Парсим поля ────────────────────────────────────────────────────
    final stageName = data['currentStage'] as String?;
    final tabName = data['activeTab'] as String?;
    final completedNames =
        (data['completedStages'] as List?)?.cast<String>() ?? [];
    final viewedIds =
        (data['viewedEvidenceIds'] as List?)?.cast<String>().toSet() ?? {};
    final rawLinks = data['evidenceLinks'];
    final links = rawLinks is Map
        ? rawLinks.cast<String, String>()
        : <String, String>{};
    final hintNames =
        (data['revealedHintStages'] as List?)?.cast<String>() ?? [];
    final lifehackUsed = (data['lifehackUsed'] as bool?) ?? false;
    final sortDescending = (data['sortDescending'] as bool?) ?? false;
    final selectedId = data['selectedEvidenceId'] as String?;
    final appliedNames =
        (data['appliedMethods'] as List?)?.cast<String>() ?? [];
    final activeMethodName = data['activeMethod'] as String?;
    final whatIfTried = (data['whatIfTried'] as bool?) ?? false;
    final revealedNames =
        (data['revealedConclusions'] as List?)?.cast<String>() ?? [];
    final accusedSuspectId = data['accusedSuspectId'] as String?;
    final clearedSuspectIds =
        (data['clearedSuspectIds'] as List?)?.cast<String>().toSet() ??
            <String>{};

    // ── Резолвим enum'ы ────────────────────────────────────────────────
    InvestigationStage resolveStage(String? name, InvestigationStage fallback) =>
        InvestigationStage.values
            .firstWhere((e) => e.name == name, orElse: () => fallback);

    final currentStage =
        resolveStage(stageName, InvestigationStage.intake);
    final activeTab = WorkspaceTab.values
        .firstWhere((e) => e.name == tabName, orElse: () => WorkspaceTab.data);
    final completedStages =
        completedNames.map((n) => resolveStage(n, InvestigationStage.intake)).toSet();
    final revealedHintStages =
        hintNames.map((n) => resolveStage(n, InvestigationStage.intake)).toSet();

    final evidence = base.evidence;

    // ── Пересчитываем methodResults из сохранённого списка ─────────────
    final methodResults = <AnalysisMethod, AnalysisResult>{};
    for (final name in appliedNames) {
      final matches = AnalysisMethod.values.where((m) => m.name == name);
      if (matches.isEmpty) continue;
      final method = matches.first;
      try {
        methodResults[method] = StatisticalMethods.apply(method, evidence);
      } catch (_) {}
    }

    final revealedConclusions = <AnalysisMethod>{};
    for (final name in revealedNames) {
      final matches = AnalysisMethod.values.where((m) => m.name == name);
      if (matches.isNotEmpty) revealedConclusions.add(matches.first);
    }

    AnalysisMethod? activeMethod;
    if (activeMethodName != null) {
      activeMethod = AnalysisMethod.values.firstWhere(
        (m) => m.name == activeMethodName,
        orElse: () => AnalysisMethod.zScore,
      );
    }

    return base.copyWith(
      currentStage: currentStage,
      activeTab: activeTab,
      completedStages: completedStages,
      viewedEvidenceIds: viewedIds,
      evidence: evidence,
      evidenceLinks: links,
      revealedHintStages: revealedHintStages,
      lifehackUsed: lifehackUsed,
      sortDescending: sortDescending,
      selectedEvidenceId: selectedId,
      methodResults: methodResults,
      activeMethod: activeMethod,
      whatIfTried: whatIfTried,
      revealedConclusions: revealedConclusions,
      accusedSuspectId: accusedSuspectId,
      clearedSuspectIds: clearedSuspectIds,
    );
  }

  static Future<void> clear(String caseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(caseId));
  }
}
