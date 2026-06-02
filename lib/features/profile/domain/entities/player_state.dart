import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../case_board/domain/entities/case_entity.dart';

enum CaseOutcome {
  solved('СПРАВЕДЛИВЫЙ ВЕРДИКТ', '+'),
  failed('СУДЕБНАЯ ОШИБКА', '-'),
  rolledBack('ОТКАТ ПО МАШИНЕ ВРЕМЕНИ', '~');

  const CaseOutcome(this.label, this.sign);
  final String label;
  final String sign;
}

class CaseHistoryEntry extends Equatable {
  const CaseHistoryEntry({
    required this.caseId,
    required this.caseCode,
    required this.caseTitle,
    required this.outcome,
    required this.xpDelta,
    required this.timestamp,
  });

  final String caseId;
  final String caseCode;
  final String caseTitle;
  final CaseOutcome outcome;
  final int xpDelta;
  final DateTime timestamp;

  Map<String, Object?> toJson() => {
        'caseId': caseId,
        'caseCode': caseCode,
        'caseTitle': caseTitle,
        'outcome': outcome.name,
        'xpDelta': xpDelta,
        'timestamp': timestamp.toIso8601String(),
      };

  factory CaseHistoryEntry.fromJson(Map<String, Object?> j) => CaseHistoryEntry(
        caseId: j['caseId'] as String,
        caseCode: j['caseCode'] as String,
        caseTitle: j['caseTitle'] as String,
        outcome: CaseOutcome.values.firstWhere(
          (o) => o.name == j['outcome'],
          orElse: () => CaseOutcome.failed,
        ),
        xpDelta: (j['xpDelta'] as num).toInt(),
        timestamp: DateTime.parse(j['timestamp'] as String),
      );

  @override
  List<Object?> get props =>
      [caseId, caseCode, caseTitle, outcome, xpDelta, timestamp];
}

class PlayerState extends Equatable {
  const PlayerState({
    required this.agent,
    required this.xp,
    required this.reputation,
    required this.rollbackCount,
    required this.history,
    this.lastCaseId,
    this.caseStatuses = const {},
  });

  final String agent;
  final int xp;
  final int reputation;
  final int rollbackCount;
  final List<CaseHistoryEntry> history;

  /// ID последнего открытого расследования — питает OP/02 «ПРОДОЛЖИТЬ».
  final String? lastCaseId;

  /// Состояние каждого дела с точки зрения игрока. Перекрывает
  /// дефолтный статус из репозитория (которое только "available/locked").
  final Map<String, CaseStatus> caseStatuses;

  String get rank {
    if (xp >= 4000) return 'CHIEF INVESTIGATOR';
    if (xp >= 2000) return 'SENIOR ANALYST';
    if (xp >= 800) return 'ANALYST';
    if (xp >= 200) return 'JUNIOR';
    return 'CADET';
  }

  int get solvedCount =>
      history.where((h) => h.outcome == CaseOutcome.solved).length;
  int get failedCount =>
      history.where((h) => h.outcome == CaseOutcome.failed).length;
  int get totalCases => solvedCount + failedCount;

  /// Точность как % правильно закрытых из всех завершённых дел.
  int get accuracy => totalCases == 0
      ? 0
      : ((solvedCount / totalCases) * 100).round();

  PlayerState copyWith({
    int? xp,
    int? reputation,
    int? rollbackCount,
    List<CaseHistoryEntry>? history,
    String? lastCaseId,
    Map<String, CaseStatus>? caseStatuses,
    bool clearLastCaseId = false,
  }) =>
      PlayerState(
        agent: agent,
        xp: xp ?? this.xp,
        reputation: reputation ?? this.reputation,
        rollbackCount: rollbackCount ?? this.rollbackCount,
        history: history ?? this.history,
        lastCaseId: clearLastCaseId ? null : (lastCaseId ?? this.lastCaseId),
        caseStatuses: caseStatuses ?? this.caseStatuses,
      );

  Map<String, Object?> toJson() => {
        'agent': agent,
        'xp': xp,
        'reputation': reputation,
        'rollbackCount': rollbackCount,
        'lastCaseId': lastCaseId,
        'history': history.map((h) => h.toJson()).toList(),
        'caseStatuses': {
          for (final e in caseStatuses.entries) e.key: e.value.name,
        },
      };

  factory PlayerState.fromJson(Map<String, Object?> j) {
    final raw = (j['history'] as List?) ?? const [];
    final statuses = (j['caseStatuses'] as Map?) ?? const {};
    return PlayerState(
      agent: (j['agent'] as String?) ?? 'KASHIRINA.K',
      xp: (j['xp'] as num?)?.toInt() ?? 0,
      reputation: (j['reputation'] as num?)?.toInt() ?? 50,
      rollbackCount: (j['rollbackCount'] as num?)?.toInt() ?? 0,
      lastCaseId: j['lastCaseId'] as String?,
      history: [
        for (final r in raw)
          CaseHistoryEntry.fromJson(Map<String, Object?>.from(r as Map)),
      ],
      caseStatuses: {
        for (final e in statuses.entries)
          e.key as String: CaseStatus.values.firstWhere(
            (s) => s.name == e.value,
            orElse: () => CaseStatus.available,
          ),
      },
    );
  }

  String encode() => jsonEncode(toJson());

  static PlayerState? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      return PlayerState.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        agent,
        xp,
        reputation,
        rollbackCount,
        history,
        lastCaseId,
        caseStatuses,
      ];
}
