import 'package:equatable/equatable.dart';

import 'investigation_stage.dart';

enum ProtocolKind {
  flag('ОТМЕТКА', '⚑'),
  link('ПРИВЯЗКА', '⇄'),
  hint('ПОДСКАЗКА', '?'),
  lifehack('ЛАЙФХАК', '!'),
  stage('ПЕРЕХОД', '→'),
  method('МЕТОД', 'fx'),
  filter('ФИЛЬТР', '∩'),
  derived('КОЛОНКА', 'Δ'),
  path('ПУТЬ', '⇢'),
  verdict('ВЕРДИКТ', '§');

  const ProtocolKind(this.label, this.glyph);
  final String label;
  final String glyph;
}

/// Запись в протоколе расследования: что и почему сделал игрок.
/// Лента отображается в правом райле во время дела и в OutcomeOverlay.
class ProtocolEntry extends Equatable {
  const ProtocolEntry({
    required this.timestamp,
    required this.stage,
    required this.kind,
    required this.message,
  });

  final DateTime timestamp;
  final InvestigationStage stage;
  final ProtocolKind kind;
  final String message;

  @override
  List<Object?> get props => [timestamp, stage, kind, message];
}
