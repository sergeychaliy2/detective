import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/window/window_chrome.dart';

class ShadowOfNumberApp extends ConsumerWidget {
  const ShadowOfNumberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Тень числа',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: AppRouter.router,
      builder: (context, child) =>
          WindowChrome(child: child ?? const SizedBox.shrink()),
    );
  }
}
