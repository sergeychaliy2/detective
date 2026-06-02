import 'package:equatable/equatable.dart';

enum EvidenceKind {
  transaction('TRANSACTION'),
  message('MESSAGE'),
  log('LOG'),
  contact('CONTACT'),
  test('TEST'),
  document('DOCUMENT');

  const EvidenceKind(this.label);
  final String label;
}

class EvidenceEntity extends Equatable {
  const EvidenceEntity({
    required this.id,
    required this.timestamp,
    required this.kind,
    required this.source,
    required this.summary,
    required this.value,
    required this.flagged,
    this.suspectId,
    this.isSmokingGun = false,
  });

  final String id;
  final DateTime timestamp;
  final EvidenceKind kind;
  final String source;
  final String summary;
  final num value;
  final bool flagged;

  /// Указывает на подозреваемого, к которому ассоциирована улика
  /// (для smoking-gun-улики совпадает с solutionSuspectId).
  final String? suspectId;

  /// Истинно для одной улики, чьё значение совпадает с solutionValue.
  /// Лайфхак подсвечивает именно её.
  final bool isSmokingGun;

  EvidenceEntity copyWith({bool? flagged}) => EvidenceEntity(
        id: id,
        timestamp: timestamp,
        kind: kind,
        source: source,
        summary: summary,
        value: value,
        flagged: flagged ?? this.flagged,
        suspectId: suspectId,
        isSmokingGun: isSmokingGun,
      );

  @override
  List<Object?> get props => [
        id,
        timestamp,
        kind,
        source,
        summary,
        value,
        flagged,
        suspectId,
        isSmokingGun,
      ];
}
