import '../entities/player_state.dart';

/// Контракт persistence-слоя профиля игрока.
abstract interface class PlayerStorage {
  Future<PlayerState?> load();
  Future<void> save(PlayerState state);
}
