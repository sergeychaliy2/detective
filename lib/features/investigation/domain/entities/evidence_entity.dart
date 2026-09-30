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
    this.suspectId,
    this.isSmokingGun = false,
  });

  final String id;
  final DateTime timestamp;
  final EvidenceKind kind;
  final String source;
  final String summary;
  final num value;

  /// Указывает на подозреваемого, к которому ассоциирована улика
  /// (для smoking-gun-улики совпадает с solutionSuspectId).
  final String? suspectId;

  /// Истинно для одной улики, чьё значение совпадает с solutionValue.
  /// Лайфхак подсвечивает именно её.
  final bool isSmokingGun;

  @override
  List<Object?> get props => [
        id,
        timestamp,
        kind,
        source,
        summary,
        value,
        suspectId,
        isSmokingGun,
      ];
}
