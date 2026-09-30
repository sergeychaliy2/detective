import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../case_board/domain/entities/case_entity.dart';
import '../../data/shared_prefs_player_storage.dart';
import '../../domain/entities/player_state.dart';
import '../../domain/repositories/player_storage.dart';

const PlayerState _defaultPlayer = PlayerState(
  agent: 'KASHIRINA.K',
  xp: 742,
  reputation: 88,
  rollbackCount: 0,
  history: [],
);

class PlayerController extends StateNotifier<PlayerState> {
  PlayerController(this._storage) : super(_defaultPlayer) {
    _bootstrap();
  }

  final PlayerStorage _storage;

  Future<void> _bootstrap() async {
    final loaded = await _storage.load();
    if (loaded != null) state = loaded;
  }

  void _emit(PlayerState next) {
    state = next;
    unawaited(_storage.save(next));
  }

  void recordOutcome({
    required String caseId,
    required String caseCode,
    required String caseTitle,
    required CaseOutcome outcome,
    required int rewardXp,
  }) {
    final delta = switch (outcome) {
      CaseOutcome.solved => rewardXp,
      CaseOutcome.failed => -(rewardXp ~/ 2),
      CaseOutcome.rolledBack => -30,
    };
    final repDelta = switch (outcome) {
      CaseOutcome.solved => 6,
      CaseOutcome.failed => -10,
      CaseOutcome.rolledBack => -2,
    };
    final newStatus = switch (outcome) {
      CaseOutcome.solved => CaseStatus.solved,
      CaseOutcome.failed => CaseStatus.failed,
      CaseOutcome.rolledBack => CaseStatus.inProgress,
    };
    _emit(state.copyWith(
      xp: (state.xp + delta).clamp(0, 1 << 30),
      reputation: (state.reputation + repDelta).clamp(0, 100),
      caseStatuses: {...state.caseStatuses, caseId: newStatus},
      clearLastCaseId: outcome == CaseOutcome.solved,
      history: [
        CaseHistoryEntry(
          caseId: caseId,
          caseCode: caseCode,
          caseTitle: caseTitle,
          outcome: outcome,
          xpDelta: delta,
          timestamp: DateTime.now(),
        ),
        ...state.history,
      ],
    ));
  }

  /// Игрок открыл дело. Запоминаем caseId как «продолжить» и помечаем
  /// дело in-progress, если оно ещё не закрыто.
  void markInProgress({required String caseId}) {
    final cur = state.caseStatuses[caseId];
    final shouldMark = cur != CaseStatus.solved;
    _emit(state.copyWith(
      lastCaseId: caseId,
      caseStatuses: shouldMark
          ? {...state.caseStatuses, caseId: CaseStatus.inProgress}
          : state.caseStatuses,
    ));
  }

  /// Списывает XP за подсказку (и не уводит репутацию ниже нуля).
  void chargeHint({required int amount, required int reputationLoss}) {
    _emit(state.copyWith(
      xp: (state.xp - amount).clamp(0, 1 << 30),
      reputation: (state.reputation - reputationLoss).clamp(0, 100),
    ));
  }

  /// Списывает рейтинг за раскрытие словесного вывода метода (в уровне практики).
  void chargeReveal({required int amount, required int reputationLoss}) {
    _emit(state.copyWith(
      xp: (state.xp - amount).clamp(0, 1 << 30),
      reputation: (state.reputation - reputationLoss).clamp(0, 100),
    ));
  }

  void registerRollback() {
    _emit(state.copyWith(
      xp: (state.xp - 30).clamp(0, 1 << 30),
      reputation: (state.reputation - 2).clamp(0, 100),
      rollbackCount: state.rollbackCount + 1,
    ));
  }
}

/// По умолчанию в приложение прокидывается shared_preferences-impl;
/// в тестах — InMemoryPlayerStorage через override.
final playerStorageProvider = Provider<PlayerStorage>(
  (ref) => SharedPrefsPlayerStorage(),
);

final playerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  return PlayerController(ref.watch(playerStorageProvider));
});
