import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/backgrounds/hud_background.dart';
import '../../../../core/widgets/effects/holographic_glow.dart';
import '../../../../core/widgets/panels/neon_panel.dart';
import '../../../../core/widgets/text/glitch_text.dart';
import '../../../investigation/domain/entities/investigation_stage.dart';
import '../../../main_menu/presentation/widgets/status_bar.dart';

/// Теоретические главы наставника — математические методы следствия.
class _TheoryChapterData {
  const _TheoryChapterData({
    required this.number,
    required this.title,
    required this.teaser,
    required this.formula,
    required this.body,
    required this.profTip,
    required this.cases,
    required this.color,
  });

  final String number;
  final String title;
  final String teaser;
  final String formula;
  final String body;
  final String profTip;
  final List<String> cases;
  final Color color;
}

final _chapters = <_TheoryChapterData>[
  _TheoryChapterData(
    number: 'I',
    title: 'Среднее и медиана',
    teaser: 'Два портрета одного числового ряда — и почему они врут по-разному',
    formula: 'x̄ = (x₁+x₂+…+xₙ) / n\nмедиана = x₍ₙ₊₁₎/₂  при нечётном n',
    body: 'Среднее — демократичный показатель: голосует каждое число. Проблема в том, что одна аномалия способна "перетащить" результат на себя. Пример: транзакции 100, 120, 110, 4 500, 130. Среднее = 992 — число, которого нет ни в одной реальной транзакции. Медиана же берёт буквально "серединный" элемент отсортированного ряда — здесь это 120, что прекрасно описывает типичный платёж.\n\nКогда применять:\n• Среднее — когда данные симметричны, выбросов мало, и важны все значения.\n• Медиана — когда данные скошены (histogram с длинным "хвостом"), есть подозрительные аномалии.',
    profTip:
        'Если среднее и медиана сильно расходятся — перед вами либо выброс, либо намеренно подделанное значение. Именно это расхождение часто и есть улика.',
    cases: ['SN-001', 'SN-002', 'SN-007'],
    color: AppColors.neonCyan,
  ),
  _TheoryChapterData(
    number: 'II',
    title: 'Z-оценка и правило 3σ',
    teaser: 'Как измерить "аномальность" любого числа в единицах нормы',
    formula: 'Z = (x − μ) / σ\n\n|Z| > 3  →  аномалия (0.3% данных)',
    body: 'Z-оценка переводит любое значение в "расстояние от среднего", измеренное стандартными отклонениями. Независимо от единиц — рублей, баллов, секунд — Z всегда одинаков: 0 в центре, ±1 в привычной зоне, ±3 на границе нормы.\n\nПравило трёх сигм: в нормальном распределении 99.7% всех значений укладываются в μ ± 3σ. Значит, если |Z| > 3 — это событие встречается реже одного раза в 370. Каждое такое число заслуживает объяснения.\n\nАлгоритм применения:\n1. Посчитать μ и σ по всей выборке\n2. Найти все точки с |Z| > 3\n3. Сопоставить каждую точку с фигурантами дела',
    profTip:
        'Z-оценка ломается, если самих выбросов много — они смещают μ и раздувают σ, маскируя друг друга. В таком случае переходите к MAD (следующая глава).',
    cases: ['SN-001', 'SN-007'],
    color: AppColors.hologramBlue,
  ),
  _TheoryChapterData(
    number: 'III',
    title: 'MAD — бронежилет аналитика',
    teaser: 'Устойчивая альтернатива Z-оценке при множественных аномалиях',
    formula: 'MAD = медиана{ |xᵢ − медиана(x)| }\n\nZ_mad = 0.6745 × (x − медиана) / MAD\n|Z_mad| > 3.5  →  аномалия',
    body: 'MAD (Median Absolute Deviation) — это медиана абсолютных отклонений от медианы. Сложно произносить, просто считать, и почти невозможно обмануть.\n\nПочему MAD лучше σ в грязных данных: σ усредняет квадраты отклонений — большой выброс поднимает σ так, что другие выбросы перестают казаться аномалиями. MAD берёт медиану отклонений — единственный выброс не может сдвинуть её больше чем на одну позицию.\n\nПрактически: если в ваших данных 5 фальшивых транзакций, Z-оценка "съедается" ими. MAD находит все пять — по очереди или сразу.',
    profTip:
        'Множитель 0.6745 нужен для согласованности с σ при нормальном распределении. Без него MAD занижал бы оценки. С ним — работает идентично Z-оценке там, где данные чисты, и лучше неё там, где нет.',
    cases: ['SN-002'],
    color: AppColors.electricBlue,
  ),
  _TheoryChapterData(
    number: 'IV',
    title: 'Закон Бенфорда',
    teaser: 'Математический детектор лжи: реальные данные не начинаются с цифр равномерно',
    formula: 'P(d) = log₁₀(1 + 1/d)\n\n1→30.1%  2→17.6%  3→12.5%\n4→9.7%   5→7.9%   6→6.7%\n7→5.8%   8→5.1%   9→4.6%',
    body: 'В 1938 году физик Фрэнк Бенфорд заметил странность: в реальных числовых данных цифра 1 встречается первой почти в 30% случаев. Цифра 9 — лишь в 4.6%. Это не совпадение — это математический закон, следующий из логарифмической шкалы.\n\nКакие данные ему подчиняются: финансовые транзакции, численность населения, физические константы, электроизмерения. Любые данные, охватывающие несколько порядков величин.\n\nКакие не подчиняются: телефонные номера, почтовые индексы, данные с фиксированным диапазоном.\n\nКак применять: подсчитать реальное распределение первых цифр, сравнить с теоретическим через χ² (хи-квадрат) тест. Значительное отклонение — признак фальсификации.\n\nПсихология мошенника: люди, придумывая числа, инстинктивно стремятся к равномерности — по одной на каждую цифру. Именно это их и выдаёт.',
    profTip:
        'Закон Бенфорда работает лучше всего на наборах от 100 записей и более. На малых выборках случайные колебания маскируют нарушения. И наоборот: идеальное соответствие закону в маленькой выборке тоже подозрительно.',
    cases: ['SN-003'],
    color: AppColors.amberWarning,
  ),
  _TheoryChapterData(
    number: 'V',
    title: 'IQR — надёжный коридор нормы',
    teaser: 'Метод boxplot: находит аномалии без предположения о форме распределения',
    formula: 'Q1 = 25-й перцентиль\nQ3 = 75-й перцентиль\nIQR = Q3 − Q1\n\nАномалии: < Q1 − 1.5·IQR\n           > Q3 + 1.5·IQR',
    body: 'IQR (межквартильный размах) — это ширина "средней половины" данных. 50% всех значений лежат внутри коридора [Q1, Q3]. Умножив IQR на 1.5 и расширив коридор с обеих сторон, мы получаем "заборы" Тьюки (Tukey fences) — классическую аномалию boxplot.\n\nГлавное преимущество: IQR ничего не предполагает о форме распределения. Z-оценка требует нормальности. IQR — нет. Он одинаково эффективен на скошенных, двугорбых, и любых других распределениях.\n\nПример: Q1=100, Q3=300, IQR=200\n  нижняя граница = 100 − 300 = −200\n  верхняя граница = 300 + 300 = 600\n  Значение 1200 — аномалия.\n  Значение −50 — тоже аномалия.',
    profTip:
        'Коэффициент 1.5 — это соглашение Тьюки, а не магическое число. При более строгом поиске используют 3×IQR. При более мягком — 1.0×IQR. Выбирайте в зависимости от того, сколько "ложных тревог" вы готовы принять.',
    cases: ['SN-004'],
    color: AppColors.violet,
  ),
  _TheoryChapterData(
    number: 'VI',
    title: 'Корреляция Спирмена',
    teaser: 'Измерить монотонную связь без требований к линейности',
    formula: 'rs = 1 − (6·Σdᵢ²) / (n·(n²−1))\n\ndᵢ = разность рангов\nrs ∈ [−1, +1]',
    body: 'Корреляция Спирмена спрашивает: когда растёт переменная A — переменная B тоже растёт (или падает) монотонно? Не обязательно линейно — главное, что порядок сохраняется.\n\nАлгоритм:\n1. Заменить каждое значение его рангом (1, 2, 3…)\n2. Посчитать разность рангов dᵢ для каждой пары\n3. Применить формулу\n\nИнтерпретация:\n  rs = +1.0 → идеальная монотонная связь (оба растут)\n  rs = 0.0  → связи нет\n  rs = −1.0 → идеальная обратная связь (один растёт — другой падает)\n\nОтличие от Пирсона: Пирсон измеряет линейную связь и уязвим к выбросам. Спирмен работает через ранги — поэтому устойчив к аномалиям и не требует нормальности.',
    profTip:
        'В следствии корреляция Спирмена помогает ответить на вопрос "была ли синхронная активность?": росла ли частота сообщений одновременно с суммами переводов? Если rs > 0.7 — это уже не совпадение.',
    cases: ['SN-005'],
    color: AppColors.magenta,
  ),
  _TheoryChapterData(
    number: 'VII',
    title: 'Граф как улика',
    teaser: 'Теория графов превращает сеть связей в математически точный след',
    formula: 'G = (V, E)\nV — вершины (фигуранты)\nE — рёбра (связи)\n\ndeg(v) = количество рёбер вершины',
    body: 'Граф — это математическая модель сети. Вершины (узлы) — это фигуранты, устройства, счета. Рёбра — связи: переводы, переписка, геопересечения. Как только данные переведены в граф, к ним применим мощный арсенал теории.\n\nКлючевые метрики:\n• Степень deg(v) — сколько прямых связей у вершины. Высокая степень → ключевой игрок.\n• BFS / Дейкстра — кратчайший путь между двумя узлами. Это цепочка передачи информации или денег.\n• Betweenness centrality — насколько часто вершина оказывается на кратчайших путях между всеми остальными. Высокое значение → "мост" или посредник.\n\nОрганизатор схемы часто прячется за посредников, снижая свою прямую степень. Но его betweenness centrality остаётся высокой — убрать его и граф рассыплется.',
    profTip:
        'Ищите вершины с высокой betweenness centrality и относительно низкой степенью — это классический паттерн "координатора в тени". Он мало с кем связан напрямую, но все ключевые пути проходят через него.',
    cases: ['SN-002', 'SN-003'],
    color: AppColors.jadeSuccess,
  ),
];

class MentorPage extends StatefulWidget {
  const MentorPage({super.key});

  @override
  State<MentorPage> createState() => _MentorPageState();
}

class _MentorPageState extends State<MentorPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HudBackground(
        child: SafeArea(
          child: Column(
            children: [
              const StatusBar(agent: 'KASHIRINA.K', session: 'A-001'),
              const _Header(),
              // Section selector
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
                child: _SectionTabs(controller: _tab),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StagesSection(),
                    _TheorySection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Section tabs ─────────────────────────────────

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TabBar(
      controller: controller,
      indicatorColor: AppColors.neonCyan,
      indicatorWeight: 2,
      labelColor: AppColors.neonCyan,
      unselectedLabelColor: AppColors.textMuted,
      labelStyle:
          theme.textTheme.labelMedium?.copyWith(letterSpacing: 3),
      tabs: const [
        Tab(text: 'ЭТАПЫ СЛЕДСТВИЯ'),
        Tab(text: 'МАТЕМАТИЧЕСКАЯ БАЗА'),
      ],
    );
  }
}

// ─────────────────────────── Stages section ───────────────────────────────

class _StagesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < InvestigationStage.values.length; i++) ...[
            _StageCard(
              stage: InvestigationStage.values[i],
              index: i,
              principle: _principle(InvestigationStage.values[i]),
            ),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  String _principle(InvestigationStage s) {
    switch (s) {
      case InvestigationStage.intake:
        return 'На первом шаге — оценить размер выборки, типы и диапазоны полей. '
            'Грязные данные превращают красивые формулы в ложные доказательства. '
            'Не считайте средние раньше, чем построите паспорт колонок.';
      case InvestigationStage.cleanup:
        return 'Сопротивление среды — шум, дубликаты, аномалии форматов. '
            'Применяйте преобразования с подтверждением: после каждой чистки '
            'сравнивайте распределение «до/после». Если форма изменилась радикально — '
            'вы выбросили сигнал вместе с шумом.';
      case InvestigationStage.analysis:
        return 'Здесь работает арсенал: статистика, графы, криптография. '
            'Выбирайте метод под вопрос, а не наоборот. Дисперсия отвечает на '
            '«насколько разброс?», корреляция Спирмена — на «есть ли монотонная связь?». '
            'Это разные вопросы.';
      case InvestigationStage.suspects:
        return 'Сильная связь ≠ виновность. Учитывайте мотив, доступ и алиби. '
            'Принцип минимального объяснения: если шум объясняет данные так же '
            'хорошо — у вас нет улики.';
      case InvestigationStage.verdict:
        return 'Финальный этап. Подсказок больше нет. Вы должны сформулировать '
            'обвинение одной «уликой-цифрой»: число и интервал доверия, '
            'отделяющие подозреваемого от всех остальных. Ошибка стоит репутации.';
    }
  }
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.index,
    required this.principle,
  });

  final InvestigationStage stage;
  final int index;
  final String principle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeonPanel(
      borderColor: stage.color,
      glow: 12,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: stage.color.withValues(alpha: 0.12),
              border: Border.all(color: stage.color),
            ),
            child: Icon(stage.icon, color: stage.color, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      stage.code,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: stage.color,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      stage.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(letterSpacing: 1.6),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                  child: AnimatedTextKit(
                    isRepeatingAnimation: false,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        principle,
                        speed: const Duration(milliseconds: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: (200 + 80 * index).ms, duration: 480.ms)
        .slideY(
          begin: 0.04,
          end: 0,
          delay: (200 + 80 * index).ms,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─────────────────────────── Theory section ───────────────────────────────

class _TheorySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '«Метод — это инструмент. Вопрос — это компас. '
            'Без компаса инструментом можно навредить»',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 480.ms),
          const SizedBox(height: 20),
          for (var i = 0; i < _chapters.length; i++) ...[
            _ChapterCard(chapter: _chapters[i], index: i),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _ChapterCard extends StatefulWidget {
  const _ChapterCard({required this.chapter, required this.index});
  final _TheoryChapterData chapter;
  final int index;

  @override
  State<_ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<_ChapterCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = widget.chapter;

    return NeonPanel(
      borderColor: ch.color,
      glow: _expanded ? 18 : 8,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header (always visible) ──────────────────────────────────
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                color: _expanded
                    ? ch.color.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chapter number badge
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: ch.color.withValues(alpha: 0.12),
                        border: Border.all(color: ch.color),
                      ),
                      child: Center(
                        child: Text(
                          ch.number,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: ch.color,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ch.title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ch.teaser,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Case badges
                          Wrap(
                            spacing: 8,
                            children: ch.cases.map((code) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ch.color.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: ch.color.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  code,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: ch.color,
                                    letterSpacing: 2,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ch.color,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Expanded body ────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: _ExpandedBody(chapter: ch, fadeAnim: _fadeAnim),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            sizeCurve: Curves.easeOut,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
            delay: (80 + 60 * widget.index).ms, duration: 480.ms)
        .slideY(
          begin: 0.03,
          end: 0,
          delay: (80 + 60 * widget.index).ms,
          duration: 480.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.chapter,
    required this.fadeAnim,
  });

  final _TheoryChapterData chapter;
  final Animation<double> fadeAnim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ch = chapter;

    return FadeTransition(
      opacity: fadeAnim,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Divider
            Container(height: 1, color: ch.color.withValues(alpha: 0.25)),
            const SizedBox(height: 18),

            // Formula box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: ch.color.withValues(alpha: 0.06),
                border: Border.all(color: ch.color.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ФОРМУЛА',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: ch.color,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ch.formula,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'JetBrainsMono',
                      color: ch.color,
                      height: 1.8,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Main body
            Text(
              ch.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.75,
              ),
            ),
            const SizedBox(height: 18),

            // Prof tip box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.06),
                border: Border(
                  left: BorderSide(
                    color: AppColors.amberWarning,
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology_alt_outlined,
                        color: AppColors.amberWarning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ИНСАЙТ ПРОФЕССОРА',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.amberWarning,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ch.profTip,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Cases label
            Row(
              children: [
                Text(
                  'ПРИМЕНЯЕТСЯ В ДЕЛАХ:',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  children: ch.cases.map((code) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ch.color.withValues(alpha: 0.12),
                        border: Border.all(color: ch.color),
                      ),
                      child: Text(
                        code,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: ch.color,
                          letterSpacing: 2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Header ───────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = context.canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () =>
                      canPop ? context.pop() : context.go('/menu'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chevron_left,
                          color: AppColors.neonCyan, size: 22),
                      const SizedBox(width: 4),
                      Text(
                        canPop ? 'НАЗАД' : 'МЕНЮ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.neonCyan,
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Container(
                width: 1,
                height: 18,
                color: AppColors.neonCyan.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 28),
              Text(
                '// MENTOR PROTOCOL',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 4),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              HolographicGlow(
                radius: 260,
                color: AppColors.magenta.withValues(alpha: 0.5),
                child: GlitchText(
                  'НАСТАВНИК',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 48,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'JUST-IN-TIME GUIDANCE',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }
}
