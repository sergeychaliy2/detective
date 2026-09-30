import 'package:detective/features/investigation/domain/entities/evidence_entity.dart';
import 'package:detective/features/investigation/domain/entities/suspect_entity.dart';
import 'package:detective/features/investigation/domain/services/graph_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

SuspectEntity _s(String id, List<String> conn) => SuspectEntity(
      id: id,
      codename: id,
      role: '',
      bio: '',
      threatLevel: 1,
      alibi: '',
      connectedEvidence: conn,
    );

EvidenceEntity _ev(String id, String? owner) => EvidenceEntity(
      id: id,
      timestamp: DateTime(2026),
      kind: EvidenceKind.transaction,
      source: '',
      summary: '',
      value: 0,
      suspectId: owner,
    );

void main() {
  group('SuspectGraph', () {
    test('пустые рёбра — degree всех = 0, нет shortest path', () {
      final g = SuspectGraph.build(
        suspects: [_s('A', []), _s('B', [])],
        evidence: const [],
        evidenceLinks: const {},
      );
      expect(g.degree()['A'], 0);
      expect(g.degree()['B'], 0);
      expect(g.shortestPath('A', 'B'), isNull);
    });

    test('пересечение connectedEvidence создаёт ребро', () {
      final g = SuspectGraph.build(
        suspects: [
          _s('A', ['EV-1', 'EV-2']),
          _s('B', ['EV-2', 'EV-3']),
          _s('C', ['EV-9']),
        ],
        evidence: const [],
        evidenceLinks: const {},
      );
      expect(g.degree()['A'], 1);
      expect(g.degree()['B'], 1);
      expect(g.degree()['C'], 0);
      expect(g.shortestPath('A', 'B'), ['A', 'B']);
      expect(g.shortestPath('A', 'C'), isNull);
    });

    test('player evidenceLinks добавляют динамические рёбра', () {
      final g = SuspectGraph.build(
        suspects: [_s('A', []), _s('B', []), _s('C', [])],
        evidence: [_ev('EV-1', 'A')],
        evidenceLinks: const {'EV-1': 'B'},
      );
      expect(g.shortestPath('A', 'B'), ['A', 'B']);
      // через A: A — B, B — C нет, ожидаем null.
      expect(g.shortestPath('B', 'C'), isNull);
    });

    test('shortest path длины 2 через промежуточный узел', () {
      // A—B—C (два ребра)
      final g = SuspectGraph.build(
        suspects: [
          _s('A', ['EV-1']),
          _s('B', ['EV-1', 'EV-2']),
          _s('C', ['EV-2']),
        ],
        evidence: const [],
        evidenceLinks: const {},
      );
      final path = g.shortestPath('A', 'C');
      expect(path, isNotNull);
      expect(path!.first, 'A');
      expect(path.last, 'C');
      expect(path.length, 3);
      expect(path[1], 'B');
    });

    test('betweenness промежуточного узла > endpoint', () {
      // Линия A—B—C: B на пути (A,C). Endpoint узлы — нет.
      final g = SuspectGraph.build(
        suspects: [
          _s('A', ['EV-1']),
          _s('B', ['EV-1', 'EV-2']),
          _s('C', ['EV-2']),
        ],
        evidence: const [],
        evidenceLinks: const {},
      );
      final bw = g.betweenness();
      expect(bw['B']!, greaterThan(bw['A']!));
      expect(bw['B']!, greaterThan(bw['C']!));
    });
  });
}
