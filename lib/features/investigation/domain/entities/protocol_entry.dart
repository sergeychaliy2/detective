import 'package:equatable/equatable.dart';

import 'investigation_stage.dart';

enum ProtocolKind {
  whatif('ПОДМЕНА', '≈'),
  link('ПРИВЯЗКА', '⇄'),
  accuse('ОБВИНЕНИЕ', '§'),
  clear('ОПРАВДАНИЕ', '✓'),
  reveal('ВЫВОД', '✶'),
  hint('ПОДСКАЗКА', '?'),
  lifehack('ЛАЙФХАК', '!'),
  stage('ПЕРЕХОД', '→'),
  method('МЕТОД', 'fx'),
  filter('ФИЛЬТР', '∩'),
  derived('КОЛОНКА', 'Δ'),
  path('ПУТЬ', '⇢'),
  verdict('ВЕРДИКТ', '⚖');

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
    this.evidenceId,
  });

  final DateTime timestamp;
  final InvestigationStage stage;
  final ProtocolKind kind;
  final String message;

  /// Улика, к которой относится запись (если есть). Делает строку протокола
  /// кликабельной — выделить улику и быстро привязать к фигуранту.
  final String? evidenceId;

  @override
  List<Object?> get props => [timestamp, stage, kind, message, evidenceId];
}
