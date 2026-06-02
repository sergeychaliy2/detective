import 'package:equatable/equatable.dart';

class SuspectEntity extends Equatable {
  const SuspectEntity({
    required this.id,
    required this.codename,
    required this.role,
    required this.bio,
    required this.threatLevel,
    required this.alibi,
    required this.connectedEvidence,
  });

  final String id;
  final String codename;
  final String role;
  final String bio;
  final int threatLevel; // 1..5
  final String alibi;
  final List<String> connectedEvidence;

  @override
  List<Object?> get props => [
        id,
        codename,
        role,
        bio,
        threatLevel,
        alibi,
        connectedEvidence,
      ];
}
