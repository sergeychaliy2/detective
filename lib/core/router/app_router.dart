import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/case_board/presentation/pages/case_board_page.dart';
import '../../features/investigation/presentation/pages/investigation_page.dart';
import '../../features/main_menu/presentation/pages/main_menu_page.dart';
import '../../features/mentor/presentation/pages/mentor_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

class AppRouter {
  AppRouter._();

  /// Глобальный ключ root-навигатора. WindowChrome использует его,
  /// чтобы показать confirm-диалог: сам WindowChrome сидит ВЫШЕ
  /// навигатора (через MaterialApp.builder), поэтому Navigator.of в
  /// его контексте не работает.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(const SplashPage()),
      ),
      GoRoute(
        path: '/menu',
        pageBuilder: (context, state) => _fadePage(const MainMenuPage()),
      ),
      GoRoute(
        path: '/cases',
        pageBuilder: (context, state) => _fadePage(const CaseBoardPage()),
      ),
      GoRoute(
        path: '/case/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _fadePage(InvestigationPage(caseId: id));
        },
      ),
      GoRoute(
        path: '/mentor',
        pageBuilder: (context, state) => _fadePage(const MentorPage()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => _fadePage(const ProfilePage()),
      ),
    ],
  );

  static CustomTransitionPage<void> _fadePage(Widget child) {
    return CustomTransitionPage<void>(
      child: child,
      transitionDuration: const Duration(milliseconds: 450),
      transitionsBuilder: (context, animation, secondary, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }
}
