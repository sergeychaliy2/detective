import 'dart:collection';

import '../entities/evidence_entity.dart';
import '../entities/suspect_entity.dart';

/// Простой неориентированный граф подозреваемых: рёбра возникают там,
/// где есть пересечение по уликам — статическое (`connectedEvidence`)
/// или динамическое (привязки игрока через `evidenceLinks`).
class SuspectGraph {
  SuspectGraph._({
    required this.nodes,
    required this.adjacency,
    required this.weights,
  });

  /// Собирает граф из текущего состояния расследования.
  factory SuspectGraph.build({
    required List<SuspectEntity> suspects,
    required List<EvidenceEntity> evidence,
    required Map<String, String> evidenceLinks,
  }) {
    final nodes = suspects.map((s) => s.id).toList(growable: false);
    final adjacency = <String, Set<String>>{
      for (final id in nodes) id: <String>{},
    };
    final weights = <String, int>{};

    void addEdge(String a, String b) {
      if (a == b) return;
      if (!adjacency.containsKey(a) || !adjacency.containsKey(b)) return;
      adjacency[a]!.add(b);
      adjacency[b]!.add(a);
      final key = _edgeKey(a, b);
      weights[key] = (weights[key] ?? 0) + 1;
    }

    // Статика: пересечение connectedEvidence.
    for (var i = 0; i < suspects.length; i++) {
      for (var j = i + 1; j < suspects.length; j++) {
        final shared = suspects[i]
            .connectedEvidence
            .toSet()
            .intersection(suspects[j].connectedEvidence.toSet());
        for (var k = 0; k < shared.length; k++) {
          addEdge(suspects[i].id, suspects[j].id);
        }
      }
    }

    // Динамика: каждая привязка игрока даёт ребро между «настоящим»
    // владельцем улики и подозреваемым, на которого игрок её повесил.
    for (final entry in evidenceLinks.entries) {
      EvidenceEntity? ev;
      for (final e in evidence) {
        if (e.id == entry.key) {
          ev = e;
          break;
        }
      }
      if (ev?.suspectId == null) continue;
      addEdge(ev!.suspectId!, entry.value);
    }

    return SuspectGraph._(
      nodes: nodes,
      adjacency: adjacency,
      weights: weights,
    );
  }

  final List<String> nodes;
  final Map<String, Set<String>> adjacency;

  /// Веса рёбер, ключ — `_edgeKey(a, b)`.
  final Map<String, int> weights;

  // ───────── Метрики ────────────────────────────────────────────────

  /// Степень — количество соседей.
  Map<String, int> degree() => {
        for (final id in nodes) id: adjacency[id]?.length ?? 0,
      };

  /// Нормализованная betweenness centrality.
  /// Для каждой пары (s, t) находим shortest path и каждой промежуточной
  /// вершине добавляем +1 / pairs.
  Map<String, double> betweenness() {
    final result = {for (final id in nodes) id: 0.0};
    var pairs = 0;
    for (var i = 0; i < nodes.length; i++) {
      for (var j = i + 1; j < nodes.length; j++) {
        final path = shortestPath(nodes[i], nodes[j]);
        if (path == null) continue;
        pairs++;
        // intermediate-узлы — все, кроме endpoints.
        for (var k = 1; k < path.length - 1; k++) {
          result[path[k]] = (result[path[k]] ?? 0) + 1;
        }
      }
    }
    if (pairs == 0) return result;
    for (final id in nodes) {
      result[id] = (result[id] ?? 0) / pairs;
    }
    return result;
  }

  /// BFS shortest path между двумя узлами. null если нет связи.
  List<String>? shortestPath(String from, String to) {
    if (!adjacency.containsKey(from) || !adjacency.containsKey(to)) return null;
    if (from == to) return [from];
    final visited = <String>{from};
    final parent = <String, String>{};
    final queue = Queue<String>()..add(from);
    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      for (final next in adjacency[cur] ?? const <String>{}) {
        if (visited.add(next)) {
          parent[next] = cur;
          if (next == to) {
            final path = <String>[to];
            var v = to;
            while (parent.containsKey(v)) {
              v = parent[v]!;
              path.add(v);
            }
            return path.reversed.toList();
          }
          queue.add(next);
        }
      }
    }
    return null;
  }

  int edgeWeight(String a, String b) => weights[_edgeKey(a, b)] ?? 0;

  static String _edgeKey(String a, String b) =>
      a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';
}
