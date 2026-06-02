import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../router/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../buttons/glow_button.dart';
import '../panels/neon_panel.dart';
import 'title_bar.dart';

/// Оборачивает приложение в кастомный HUD-фрейм:
/// сверху traffic-light titlebar, снизу — основной child. Перехватывает
/// системный close-event и показывает confirm-диалог в стиле HUD.
///
/// Должен находиться ВНУТРИ MaterialApp (через `builder:`), иначе
/// confirm-диалог не сможет использовать Navigator.
class WindowChrome extends StatefulWidget {
  const WindowChrome({super.key, required this.child});

  final Widget child;

  @override
  State<WindowChrome> createState() => _WindowChromeState();
}

class _WindowChromeState extends State<WindowChrome> with WindowListener {
  bool _confirmOpen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() {
    // Системный close уже перехвачен через setPreventClose(true) в main.
    // Показываем confirm; реальное закрытие — только через destroy().
    _requestClose();
  }

  Future<void> _requestClose() async {
    if (_confirmOpen) return;
    final navContext = AppRouter.navigatorKey.currentContext;
    if (navContext == null) {
      // Навигатор ещё не смонтирован — дать выйти молча.
      await windowManager.destroy();
      return;
    }
    _confirmOpen = true;
    final confirmed = await showDialog<bool>(
      context: navContext,
      useRootNavigator: true,
      barrierColor: AppColors.voidBlack.withValues(alpha: 0.78),
      barrierDismissible: true,
      builder: (ctx) => const _ExitConfirmDialog(),
    );
    _confirmOpen = false;
    if (confirmed == true) {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ColoredBox вместо Material — Material 3 распространяет hover-tint
    // вниз по дереву, из-за чего наведение на любую кнопку «серило» всю
    // обёртку. ColoredBox чисто рендерит фон без интерактивной логики.
    return ColoredBox(
      color: AppColors.voidBlack,
      child: Column(
        children: [
          WindowTitleBar(onCloseRequest: _requestClose),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: NeonPanel(
            borderColor: AppColors.crimsonError,
            glow: 24,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.power_settings_new,
                        color: AppColors.crimsonError, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      '// SESSION TERMINATION',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.crimsonError,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'ЗАВЕРШИТЬ СЕАНС?',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontSize: 30,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Текущий прогресс расследования сохранён в защищённое хранилище. '
                  'Все незаконченные дела можно продолжить через OP/02 — ПРОДОЛЖИТЬ.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: GlowButton(
                        label: 'ОСТАТЬСЯ',
                        icon: Icons.arrow_back,
                        color: AppColors.neonCyan,
                        onPressed: () => Navigator.of(context).pop(false),
                        height: 52,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: GlowButton(
                        label: 'ВЫЙТИ',
                        icon: Icons.power_settings_new,
                        color: AppColors.crimsonError,
                        accent: AppColors.magenta,
                        onPressed: () => Navigator.of(context).pop(true),
                        height: 52,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animateOpenClose(),
        ),
      ),
    );
  }
}

extension on Widget {
  // Маленький syntactic-sugar чтобы не тащить flutter_animate сюда.
  Widget animateOpenClose() => AnimatedSize(
        duration: AppMetrics.normal,
        curve: AppMetrics.easeOutExpo,
        child: this,
      );
}
