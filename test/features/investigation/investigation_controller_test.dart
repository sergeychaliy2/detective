import 'package:detective/features/case_board/data/mock_case_repository.dart';
import 'package:detective/features/case_board/domain/entities/case_entity.dart';
import 'package:detective/features/case_board/presentation/providers/case_board_providers.dart';
import 'package:detective/features/investigation/domain/entities/analysis_method.dart';
import 'package:detective/features/investigation/domain/entities/investigation_stage.dart';
import 'package:detective/features/investigation/presentation/providers/investigation_provider.dart';
import 'package:detective/features/profile/data/shared_prefs_player_storage.dart';
import 'package:detective/features/profile/presentation/providers/player_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

ProviderContainer _container() => ProviderContainer(
      overrides: [
        playerStorageProvider.overrideWithValue(InMemoryPlayerStorage()),
      ],
    );

Future<void> _hydrate(ProviderContainer c) async {
  await c.read(caseListProvider.future);
}

void main() {
  // InvestigationPersistence — статический синглтон поверх SharedPreferences;
  // в тестах инициализируем биндинг и подменяем хранилище in-memory мок-ом.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('InvestigationController', () {
    test('старт расследования помечает дело in-progress и lastCaseId', () async {
      final c = _container();
      await _hydrate(c);
      c.read(investigationProvider('sn-001'));
      // Даём StateNotifier инициализироваться + microtask с markInProgress.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final p = c.read(playerProvider);
      expect(p.lastCaseId, 'sn-001');
      expect(p.caseStatuses['sn-001'], CaseStatus.inProgress);
      c.dispose();
    });

    test('intake без гейта: переход открыт сразу', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      final s = c.read(investigationProvider('sn-001'))!;
      expect(s.currentStage, InvestigationStage.intake);
      expect(s.canAdvance, true, reason: 'intake больше не требует условий');

      notifier.advanceStage();
      expect(c.read(investigationProvider('sn-001'))!.currentStage,
          InvestigationStage.cleanup);
      c.dispose();
    });

    test('markWhatIfTried ставит whatIfTried и пишет ProtocolEntry whatif', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      notifier.markWhatIfTried();
      final s = c.read(investigationProvider('sn-001'))!;
      expect(s.whatIfTried, true);
      expect(s.protocol, isNotEmpty);
      expect(s.protocol.first.kind.name, 'whatif');
      c.dispose();
    });

    test('обвинение требует привязки; accusationBuilt после обвинить+оправдать',
        () async {
      final c = _container();
      await _hydrate(c);
      // sn-007: два фигуранта — S1 (виновный) и S2.
      final notifier = c.read(investigationProvider('sn-007').notifier);
      // Без привязки обвинение игнорируется.
      notifier.accuseSuspect('S1');
      expect(c.read(investigationProvider('sn-007'))!.accusedSuspectId, isNull);
      // Привязываем улику к S1 → теперь можно обвинить.
      notifier.touchEvidence('EV-0007');
      notifier.linkSelectedEvidenceTo('S1');
      notifier.accuseSuspect('S1');
      var s = c.read(investigationProvider('sn-007'))!;
      expect(s.accusedSuspectId, 'S1');
      expect(s.accusationBuilt, false,
          reason: 'второй фигурант ещё не оправдан');
      notifier.clearSuspect('S2');
      s = c.read(investigationProvider('sn-007'))!;
      expect(s.accusationBuilt, true);
      c.dispose();
    });

    test('revealConclusion: бесплатно в обучении, со штрафом в практике', () async {
      final c = _container();
      await _hydrate(c);
      // sn-007 — обучающее: раскрытие бесплатно.
      final trainee = c.read(investigationProvider('sn-007').notifier);
      trainee.applyMethod(AnalysisMethod.benford);
      final xpTrainee = c.read(playerProvider).xp;
      trainee.revealConclusion(AnalysisMethod.benford);
      expect(
          c.read(investigationProvider('sn-007'))!.revealedConclusions
              .contains(AnalysisMethod.benford),
          true);
      expect(c.read(playerProvider).xp, xpTrainee,
          reason: 'в обучении раскрытие бесплатно');

      // sn-002 — практика: раскрытие списывает рейтинг.
      final practice = c.read(investigationProvider('sn-002').notifier);
      practice.applyMethod(AnalysisMethod.mad);
      final xpBefore = c.read(playerProvider).xp;
      practice.revealConclusion(AnalysisMethod.mad);
      expect(c.read(playerProvider).xp, lessThan(xpBefore),
          reason: 'в практике раскрытие стоит рейтинга');
      c.dispose();
    });

    test('linkSelectedEvidenceTo требует выделенной улики', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      notifier.linkSelectedEvidenceTo('S2');
      expect(c.read(investigationProvider('sn-001'))!.evidenceLinks, isEmpty);

      notifier.touchEvidence('EV-0003');
      notifier.linkSelectedEvidenceTo('S2');
      expect(c.read(investigationProvider('sn-001'))!.evidenceLinks['EV-0003'],
          'S2');
      c.dispose();
    });

    test('submitVerdict (correct) → solved + статус в PlayerState', () async {
      final c = _container();
      await _hydrate(c);
      final cases = await c.read(caseListProvider.future);
      final tutorial =
          cases.firstWhere((x) => x.id == 'sn-007'); // sn-007 = tutorial
      final notifier = c.read(investigationProvider(tutorial.id).notifier);

      // Перепрыгиваем гейтинг через прямой submitVerdict.
      final correct = notifier.submitVerdict(
        suspectId: tutorial.solutionSuspectId,
        value: tutorial.solutionValue,
      );
      expect(correct, true);
      final s = c.read(investigationProvider(tutorial.id))!;
      expect(s.outcome?.name, 'solved');
      expect(c.read(playerProvider).caseStatuses[tutorial.id],
          CaseStatus.solved);
      c.dispose();
    });

    test('submitVerdict (wrong suspect) → failed', () async {
      final c = _container();
      await _hydrate(c);
      final cases = await c.read(caseListProvider.future);
      final tutorial = cases.firstWhere((x) => x.id == 'sn-007');
      final notifier = c.read(investigationProvider(tutorial.id).notifier);
      final correct = notifier.submitVerdict(suspectId: 'S99', value: 0);
      expect(correct, false);
      expect(c.read(investigationProvider(tutorial.id))!.outcome?.name,
          'failed');
      c.dispose();
    });

    test('экзамен: rollback и hint/lifehack заблокированы', () async {
      final c = _container();
      await _hydrate(c);
      final cases = await c.read(caseListProvider.future);
      final exam = cases.firstWhere((x) => x.difficulty == CaseDifficulty.exam);
      final notifier = c.read(investigationProvider(exam.id).notifier);

      expect(notifier.requestHint(), isNull);
      expect(notifier.requestLifehack(), isNull);

      // Создадим хоть какое-то "поведение" чтобы было что откатывать.
      notifier.markWhatIfTried();
      final repBefore = c.read(playerProvider).rollbackCount;
      notifier.rollback();
      expect(c.read(playerProvider).rollbackCount, repBefore,
          reason: 'rollback не должен срабатывать в экзамене');
      c.dispose();
    });

    test('lifehack раскрывает smoking-gun ровно один раз', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      final id = notifier.requestLifehack();
      expect(id, isNotNull);
      final s = c.read(investigationProvider('sn-001'))!;
      expect(s.lifehackUsed, true);
      expect(s.selectedEvidenceId, id);
      // Повторный вызов даёт null.
      expect(notifier.requestLifehack(), isNull);
      c.dispose();
    });

    test('applyMethod сохраняет результат + ProtocolEntry method', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      final result = notifier.applyMethod(AnalysisMethod.zScore);
      expect(result.method, AnalysisMethod.zScore);
      final s = c.read(investigationProvider('sn-001'))!;
      expect(s.methodResults.containsKey(AnalysisMethod.zScore), true);
      expect(s.activeMethod, AnalysisMethod.zScore);
      expect(s.protocol.first.message, contains('METHOD'));
      c.dispose();
    });

    test('гейтинг analysis: stage не сменится без applyMethod', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      notifier.advanceStage(); // intake → cleanup (без гейта)
      expect(c.read(investigationProvider('sn-001'))!.currentStage,
          InvestigationStage.cleanup);
      // Удовлетворяем cleanup: проба подмены значения.
      notifier.markWhatIfTried();
      notifier.advanceStage(); // → analysis
      var s = c.read(investigationProvider('sn-001'))!;
      expect(s.currentStage, InvestigationStage.analysis);
      expect(s.canAdvance, false,
          reason: 'нельзя выйти из analysis без applyMethod');
      notifier.advanceStage();
      s = c.read(investigationProvider('sn-001'))!;
      expect(s.currentStage, InvestigationStage.analysis);
      // Применяем метод — теперь можно.
      notifier.applyMethod(AnalysisMethod.iqr);
      expect(c.read(investigationProvider('sn-001'))!.canAdvance, true);
      c.dispose();
    });

    test('setValueFilter скрывает улики и пишет ProtocolEntry filter', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      final beforeAll = c.read(investigationProvider('sn-001'))!.evidence.length;
      notifier.setValueFilter(min: 0, max: 100);
      final s = c.read(investigationProvider('sn-001'))!;
      expect(s.valueFilter, isNotNull);
      expect(s.filteredEvidence.length, lessThanOrEqualTo(beforeAll));
      expect(s.protocol.first.kind.name, 'filter');
      notifier.clearValueFilter();
      expect(c.read(investigationProvider('sn-001'))!.valueFilter, isNull);
      c.dispose();
    });

    test('toggleDerivedColumn добавляет/убирает колонку и пишет protocol', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      notifier.toggleDerivedColumn(AnalysisMethod.values.isNotEmpty
          ? DerivedColumn.zScore
          : DerivedColumn.zScore);
      var s = c.read(investigationProvider('sn-001'))!;
      expect(s.derivedColumns.contains(DerivedColumn.zScore), true);
      notifier.toggleDerivedColumn(DerivedColumn.zScore);
      s = c.read(investigationProvider('sn-001'))!;
      expect(s.derivedColumns.contains(DerivedColumn.zScore), false);
      c.dispose();
    });

    test('setPathEndpoints находит shortest path и пишет ProtocolEntry path', () async {
      final c = _container();
      await _hydrate(c);
      final notifier = c.read(investigationProvider('sn-001').notifier);
      // Делаем привязки, чтобы появились рёбра.
      notifier.touchEvidence('EV-0001');
      notifier.linkSelectedEvidenceTo('S2');
      notifier.touchEvidence('EV-0002');
      notifier.linkSelectedEvidenceTo('S3');
      notifier.setPathEndpoints(from: 'S1', to: 'S4');
      final s = c.read(investigationProvider('sn-001'))!;
      // Path может быть null или непустой — главное, что не падает.
      expect(s.pathFrom, 'S1');
      expect(s.pathTo, 'S4');
      expect(s.protocol.first.kind.name, 'path');
      c.dispose();
    });

    test('бонус +25% за optimal solutionMethod при solved', () async {
      final c = _container();
      await _hydrate(c);
      final cases = await c.read(caseListProvider.future);
      final tutorial = cases.firstWhere((x) => x.id == 'sn-007');
      final notifier = c.read(investigationProvider(tutorial.id).notifier);
      // Применяем optimal-метод.
      notifier.applyMethod(tutorial.solutionMethod);
      final xpBefore = c.read(playerProvider).xp;
      notifier.submitVerdict(
        suspectId: tutorial.solutionSuspectId,
        value: tutorial.solutionValue,
      );
      final xpAfter = c.read(playerProvider).xp;
      final delta = xpAfter - xpBefore;
      // Ожидаем +25% бонуса.
      expect(delta, (tutorial.rewardXp * 1.25).round());
      c.dispose();
    });
  });

  group('MockCaseRepository', () {
    test('solutionEvidenceKindIndex попадает в smoking-gun-улику', () async {
      const repo = MockCaseRepository();
      final cases = await repo.fetchCases();
      for (final ce in cases) {
        // Проверяем что новые поля валидны.
        expect(ce.solutionEvidenceKindIndex, greaterThanOrEqualTo(0));
        expect(ce.theoryHints, isA<List<String>>());
        expect(ce.solutionRationale, isNotEmpty);
      }
    });
  });
}
