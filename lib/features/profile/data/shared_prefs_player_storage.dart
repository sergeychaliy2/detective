import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/player_state.dart';
import '../domain/repositories/player_storage.dart';

/// Реализация PlayerStorage поверх shared_preferences.
/// Хранит сериализованный JSON под одним ключом.
class SharedPrefsPlayerStorage implements PlayerStorage {
  SharedPrefsPlayerStorage({SharedPreferences? prefs}) : _prefs = prefs;

  static const _key = 'player_state_v1';
  SharedPreferences? _prefs;

  Future<SharedPreferences> _ensure() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  @override
  Future<PlayerState?> load() async {
    final p = await _ensure();
    return PlayerState.tryDecode(p.getString(_key));
  }

  @override
  Future<void> save(PlayerState state) async {
    final p = await _ensure();
    await p.setString(_key, state.encode());
  }
}

/// In-memory заглушка, полезна в тестах и для отключения persistence.
class InMemoryPlayerStorage implements PlayerStorage {
  PlayerState? _cached;

  @override
  Future<PlayerState?> load() async => _cached;

  @override
  Future<void> save(PlayerState state) async {
    _cached = state;
  }
}
