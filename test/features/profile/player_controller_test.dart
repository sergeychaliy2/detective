import 'package:detective/features/case_board/domain/entities/case_entity.dart';
import 'package:detective/features/profile/data/shared_prefs_player_storage.dart';
import 'package:detective/features/profile/domain/entities/player_state.dart';
import 'package:detective/features/profile/presentation/providers/player_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlayerController', () {
    late InMemoryPlayerStorage storage;
    late PlayerController c;

    setUp(() {
      storage = InMemoryPlayerStorage();
      c = PlayerController(storage);
    });

    test('начальное состояние — KASHIRINA.K, 742 XP, без истории', () {
      expect(c.state.agent, 'KASHIRINA.K');
      expect(c.state.xp, 742);
      expect(c.state.history, isEmpty);
      expect(c.state.lastCaseId, isNull);
    });

    test('recordOutcome (solved) добавляет +rewardXp, +6 reputation и solved-статус', () {
      final beforeXp = c.state.xp;
      final beforeRep = c.state.reputation;
      c.recordOutcome(
        caseId: 'sn-001',
        caseCode: 'SN-001',
        caseTitle: 'TEST',
        outcome: CaseOutcome.solved,
        rewardXp: 200,
      );
      expect(c.state.xp, beforeXp + 200);
      expect(c.state.reputation, beforeRep + 6);
      expect(c.state.history, hasLength(1));
      expect(c.state.history.first.outcome, CaseOutcome.solved);
      expect(c.state.caseStatuses['sn-001'], CaseStatus.solved);
      expect(c.state.solvedCount, 1);
      expect(c.state.failedCount, 0);
      expect(c.state.accuracy, 100);
    });

    test('recordOutcome (failed) списывает rewardXp/2 и -10 reputation', () {
      c.recordOutcome(
        caseId: 'sn-001',
        caseCode: 'SN-001',
        caseTitle: 'TEST',
        outcome: CaseOutcome.failed,
        rewardXp: 200,
      );
      expect(c.state.xp, 742 - 100);
      expect(c.state.reputation, 88 - 10);
      expect(c.state.caseStatuses['sn-001'], CaseStatus.failed);
    });

    test('markInProgress ставит lastCaseId и in-progress статус', () {
      c.markInProgress(caseId: 'sn-001');
      expect(c.state.lastCaseId, 'sn-001');
      expect(c.state.caseStatuses['sn-001'], CaseStatus.inProgress);
    });

    test('markInProgress не перезаписывает solved-статус', () {
      c.recordOutcome(
        caseId: 'sn-001',
        caseCode: 'SN-001',
        caseTitle: 'TEST',
        outcome: CaseOutcome.solved,
        rewardXp: 100,
      );
      c.markInProgress(caseId: 'sn-001');
      expect(c.state.caseStatuses['sn-001'], CaseStatus.solved);
    });

    test('solved очищает lastCaseId; failed — нет', () {
      c.markInProgress(caseId: 'sn-001');
      c.recordOutcome(
        caseId: 'sn-001',
        caseCode: 'SN-001',
        caseTitle: 'T',
        outcome: CaseOutcome.failed,
        rewardXp: 100,
      );
      expect(c.state.lastCaseId, 'sn-001');

      c.recordOutcome(
        caseId: 'sn-002',
        caseCode: 'SN-002',
        caseTitle: 'T2',
        outcome: CaseOutcome.solved,
        rewardXp: 100,
      );
      expect(c.state.lastCaseId, isNull);
    });

    test('rollback: -30 XP, -2 rep, +1 rollbackCount', () {
      c.registerRollback();
      expect(c.state.xp, 742 - 30);
      expect(c.state.reputation, 88 - 2);
      expect(c.state.rollbackCount, 1);
    });

    test('rank растёт по XP-порогам', () {
      expect(c.state.copyWith(xp: 0).rank, 'CADET');
      expect(c.state.copyWith(xp: 250).rank, 'JUNIOR');
      expect(c.state.copyWith(xp: 1500).rank, 'ANALYST');
      expect(c.state.copyWith(xp: 2500).rank, 'SENIOR ANALYST');
      expect(c.state.copyWith(xp: 9000).rank, 'CHIEF INVESTIGATOR');
    });

    test('chargeHint клампит XP/репутацию по нулю', () {
      final low = PlayerController(storage)
        ..state = const PlayerState(
          agent: 'X',
          xp: 5,
          reputation: 1,
          rollbackCount: 0,
          history: [],
        );
      low.chargeHint(amount: 100, reputationLoss: 100);
      expect(low.state.xp, 0);
      expect(low.state.reputation, 0);
    });

    test('persistence: state сохраняется в storage и читается обратно', () async {
      c.recordOutcome(
        caseId: 'sn-001',
        caseCode: 'SN-001',
        caseTitle: 'TEST',
        outcome: CaseOutcome.solved,
        rewardXp: 50,
      );
      // Дать unawaited save завершиться.
      await Future<void>.delayed(Duration.zero);
      final loaded = await storage.load();
      expect(loaded, isNotNull);
      expect(loaded!.xp, 742 + 50);
      expect(loaded.history, hasLength(1));
      expect(loaded.caseStatuses['sn-001'], CaseStatus.solved);
    });

    test('JSON round-trip сохраняет все ключевые поля', () {
      final original = c.state.copyWith(
        xp: 1234,
        reputation: 67,
        lastCaseId: 'sn-003',
        caseStatuses: {'sn-003': CaseStatus.inProgress},
        history: [
          CaseHistoryEntry(
            caseId: 'sn-003',
            caseCode: 'SN-003',
            caseTitle: 'X',
            outcome: CaseOutcome.solved,
            xpDelta: 100,
            timestamp: DateTime.parse('2026-05-15T10:00:00.000'),
          ),
        ],
      );
      final restored = PlayerState.tryDecode(original.encode());
      expect(restored, isNotNull);
      expect(restored, equals(original));
    });
  });
}
