import 'package:detective/features/mentor/presentation/pages/mentor_page.dart';
import 'package:detective/features/profile/data/shared_prefs_player_storage.dart';
import 'package:detective/features/profile/presentation/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Smoke-тест произвольной страницы без splash-таймера и go_router-цикла.
/// Проверяем, что страница строится, тема применяется и нет исключений
/// на первом кадре. Полный boot-сценарий через splash тестируется e2e
/// на реальном устройстве, в widget-test это слишком брittle из-за
/// repeating-анимаций.
void main() {
  testWidgets('MentorPage builds without exceptions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const MentorPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerStorageProvider.overrideWithValue(InMemoryPlayerStorage()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
