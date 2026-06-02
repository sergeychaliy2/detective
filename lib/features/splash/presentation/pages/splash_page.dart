import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../core/widgets/text/glitch_text.dart';

/// Splash: boot-sequence наставника, появление логотипа "ТЕНЬ ЧИСЛА",
/// затем автопереход в главное меню.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _bootLines = <String>[
    '> initializing kernel.shadow ...',
    '> linking mathematical core ...',
    '> calibrating mentor protocols ...',
    '> decrypting evidence vault ...',
    '> system online.',
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 5400), () {
      if (mounted) context.go('/menu');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: HudBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HolographicGlow(
                    radius: 360,
                    child: GlitchText(
                      'ТЕНЬ ЧИСЛА',
                      style: theme.textTheme.displayLarge?.copyWith(
                        fontSize: 64,
                        letterSpacing: 12,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 900.ms, curve: Curves.easeOut)
                        .scale(
                          begin: const Offset(0.92, 0.92),
                          end: const Offset(1, 1),
                          duration: 1200.ms,
                          curve: Curves.easeOutExpo,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'SHADOW OF NUMBER',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 8,
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 700.ms),
                  const SizedBox(height: 56),
                  SizedBox(
                    height: 110,
                    child: DefaultTextStyle(
                      style: theme.textTheme.labelMedium!.copyWith(
                        color: AppColors.neonCyan,
                        height: 1.8,
                      ),
                      child: AnimatedTextKit(
                        isRepeatingAnimation: false,
                        animatedTexts: [
                          for (final line in _bootLines)
                            TypewriterAnimatedText(
                              line,
                              speed: const Duration(milliseconds: 28),
                            ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 900.ms),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 240,
                    child: _LoadingBar()
                        .animate()
                        .fadeIn(delay: 1200.ms, duration: 500.ms),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingBar extends StatefulWidget {
  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.panelBg,
                border: Border.all(
                  color: AppColors.neonCyan.withValues(alpha: 0.5),
                  width: 0.6,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.neonGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan,
                        blurRadius: 8,
                        spreadRadius: -1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'LOAD ${(t * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.neonCyan,
                    letterSpacing: 3,
                  ),
            ),
          ],
        );
      },
    );
  }
}
