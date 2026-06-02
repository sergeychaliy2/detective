import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

/// Кастомный HUD-titlebar в стиле macOS: traffic-light-кнопки слева
/// (close / minimize / maximize-restore) и drag-area для перетаскивания
/// окна. Подаётся в `WindowChrome`, который оборачивает весь app.
class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({
    super.key,
    required this.onCloseRequest,
    this.title = 'ТЕНЬ ЧИСЛА  //  SHADOW OF NUMBER',
  });

  /// Колбэк "пользователь нажал X". Внешний код решает, показать ли
  /// confirm-диалог и в итоге вызвать windowManager.destroy().
  final Future<void> Function() onCloseRequest;

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 40,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.voidBlack,
          border: Border(
            bottom: BorderSide(
              color: AppColors.neonCyan.withValues(alpha: 0.18),
              width: 0.6,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            _TrafficLights(onClose: onCloseRequest),
            const SizedBox(width: 18),
            Expanded(
              child: DragToMoveArea(
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCyan,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.neonCyan,
                              blurRadius: 6,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const _SessionIndicator(),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

class _SessionIndicator extends StatelessWidget {
  const _SessionIndicator();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SECURE LINK',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.magenta,
            letterSpacing: 3,
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.magenta,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.magenta,
                blurRadius: 8,
                spreadRadius: 0.4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrafficLights extends StatelessWidget {
  const _TrafficLights({required this.onClose});
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TrafficDot(
          color: AppColors.crimsonError,
          tooltip: 'ЗАВЕРШИТЬ СЕАНС',
          glyph: Icons.close,
          onTap: onClose,
        ),
        const SizedBox(width: 9),
        _TrafficDot(
          color: AppColors.amberWarning,
          tooltip: 'СВЕРНУТЬ',
          glyph: Icons.remove,
          onTap: () => windowManager.minimize(),
        ),
        const SizedBox(width: 9),
        _TrafficDot(
          color: AppColors.jadeSuccess,
          tooltip: 'РАЗВЕРНУТЬ',
          glyph: Icons.crop_square,
          onTap: () async {
            // Зелёная кнопка переключает полноэкранный режим (как в
            // macOS). Если приложение уже не в FS — разворачиваем,
            // иначе уходим в окно стандартного размера.
            final fs = await windowManager.isFullScreen();
            if (fs) {
              await windowManager.setFullScreen(false);
              await windowManager.maximize();
            } else {
              await windowManager.setFullScreen(true);
            }
          },
        ),
      ],
    );
  }
}

class _TrafficDot extends StatefulWidget {
  const _TrafficDot({
    required this.color,
    required this.tooltip,
    required this.glyph,
    required this.onTap,
  });

  final Color color;
  final String tooltip;
  final IconData glyph;
  final Future<void> Function() onTap;

  @override
  State<_TrafficDot> createState() => _TrafficDotState();
}

class _TrafficDotState extends State<_TrafficDot> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    // Tooltip из material требует Overlay (нет в иерархии до Navigator);
    // вместо него — собственный inline-лейбл, всплывающий на hover.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => widget.onTap(),
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _hover ? 0.95 : 0.85),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color,
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _hover ? 0.85 : 0.4),
                blurRadius: _hover ? 10 : 4,
                spreadRadius: _hover ? 0.6 : 0,
              ),
            ],
          ),
          child: AnimatedOpacity(
            duration: AppMetrics.fast,
            opacity: _hover ? 1 : 0,
            child: Icon(
              widget.glyph,
              size: 10,
              color: AppColors.voidBlack,
            ),
          ),
        ),
      ),
    );
  }
}
