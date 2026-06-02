import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/presentation/providers/player_provider.dart';
import '../../data/mock_case_repository.dart';
import '../../domain/entities/case_entity.dart';
import '../../domain/repositories/case_repository.dart';

final caseRepositoryProvider = Provider<CaseRepository>(
  (ref) => const MockCaseRepository(),
);

/// "Сырой" список дел из репозитория.
final caseListProvider = FutureProvider<List<CaseEntity>>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  return repo.fetchCases();
});

/// Дела с применённым overlay статусов из PlayerState.caseStatuses.
/// На UI всегда смотреть сюда — не на caseListProvider напрямую.
final overlayedCasesProvider = Provider<AsyncValue<List<CaseEntity>>>((ref) {
  final async = ref.watch(caseListProvider);
  final statuses = ref.watch(
    playerProvider.select((s) => s.caseStatuses),
  );
  return async.whenData(
    (cases) => [
      for (final c in cases)
        statuses.containsKey(c.id) ? c.copyWith(status: statuses[c.id]) : c,
    ],
  );
});

/// null = "все уровни".
final difficultyFilterProvider = StateProvider<CaseDifficulty?>((_) => null);

final selectedCaseIdProvider = StateProvider<String?>((_) => null);

final filteredCasesProvider = Provider<AsyncValue<List<CaseEntity>>>((ref) {
  final async = ref.watch(overlayedCasesProvider);
  final filter = ref.watch(difficultyFilterProvider);
  return async.whenData(
    (cases) => filter == null
        ? cases
        : cases.where((c) => c.difficulty == filter).toList(),
  );
});

final selectedCaseProvider = Provider<CaseEntity?>((ref) {
  final id = ref.watch(selectedCaseIdProvider);
  final async = ref.watch(overlayedCasesProvider);
  return async.maybeWhen(
    data: (cases) => id == null
        ? (cases.isNotEmpty ? cases.first : null)
        : cases.firstWhere(
            (c) => c.id == id,
            orElse: () => cases.first,
          ),
    orElse: () => null,
  );
});
