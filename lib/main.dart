import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'features/profile/data/shared_prefs_player_storage.dart';
import 'features/profile/presentation/providers/player_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  // Preload shared_preferences до runApp — чтобы на первом кадре уже
  // отрисовать сохранённый PlayerState без вспышки дефолтных XP.
  final prefs = await SharedPreferences.getInstance();

  // Кастомный HUD-фрейм окна (только для Windows/macOS/Linux desktop).
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    await windowManager.ensureInitialized();

    const opts = WindowOptions(
      title: 'Тень числа',
      backgroundColor: Color(0xFF03060D),
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
      skipTaskbar: false,
    );

    await windowManager.waitUntilReadyToShow(opts, () async {
      await windowManager.setPreventClose(true);
      await windowManager.setMinimumSize(const Size(1100, 700));
      await windowManager.show();
      await windowManager.focus();
    });
    // setFullScreen вне waitUntilReadyToShow — чтобы Win32 успел
    // отдать фрейм окна, иначе fullscreen может молча не сработать.
    await windowManager.setFullScreen(true);
  }

  runApp(
    ProviderScope(
      overrides: [
        playerStorageProvider.overrideWithValue(
          SharedPrefsPlayerStorage(prefs: prefs),
        ),
      ],
      child: const ShadowOfNumberApp(),
    ),
  );
}
