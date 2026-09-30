import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/analysis_method.dart';
import '../../../domain/entities/investigation_stage.dart';
import '../../../domain/entities/investigation_state.dart';
import '../../providers/investigation_provider.dart';

/// Шаги строго соответствуют этапам расследования.
/// Порядок ВАЖЕН — индексы используются для механизма catch-up.
/// Конкретные методы анализа (шаги applyMethod1/2) задаёт `_TutorialScript`.
enum _TStep {
  welcome,        // 0
  // INTAKE
  exploreData,    // 1  бегло смотрим улики (без гейта)
  intakeDone,     // 2  нажать СЛЕДУЮЩИЙ ЭТАП
  // CLEANUP — лаборатория WHAT-IF
  whatIf,         // 3  пробуем подмену значения
  cleanupDone,    // 4  нажать СЛЕДУЮЩИЙ ЭТАП
  // ANALYSIS
  openAnalysis,   // 5  переходим на вкладку ANALYSIS
  applyMethod1,   // 6  применяем первый метод
  method1Result,  // 7  разбор результата (ручной ПОНЯТНО)
  applyMethod2,   // 8  применяем второй метод (он же solutionMethod)
  method2Result,  // 9  разбор результата (ручной ПОНЯТНО)
  analysisDone,   // 10 нажать СЛЕДУЮЩИЙ ЭТАП
  // SUSPECTS — обвинить + оправдать
  accuse,         // 11 привязать улику и обвинить виновного
  clearSuspect,   // 12 снять подозрение с остальных
  suspectsDone,   // 13 нажать СЛЕДУЮЩИЙ ЭТАП
  // VERDICT
  submitVerdict,  // 14 вводим фигуранта + улику-цифру
  complete,       // 15
}

/// Сценарий туториала под конкретное дело: тексты шагов + какие два
/// метода применяются на этапе АНАЛИЗ (порядок важен для авто-перехода).
class _TutorialScript {
  const _TutorialScript({
    required this.method1,
    required this.method2,
    required this.steps,
  });

  /// Первый применяемый метод (шаг applyMethod1).
  final AnalysisMethod method1;

  /// Второй применяемый метод (шаг applyMethod2) — обычно solutionMethod.
  final AnalysisMethod method2;

  final Map<_TStep, _StepConfig> steps;
}

class _StepConfig {
  const _StepConfig({
    required this.icon,
    required this.stepLabel,
    required this.title,
    required this.body,
    this.mathNote,
    this.pointer,
    this.theoryChapter,
    this.showAcknowledge = false,
  });

  final IconData icon;
  final String stepLabel;
  final String title;
  final String body;
  final String? mathNote;
  final String? pointer;

  /// Название главы теории наставника — рендерится ссылкой «Полная теория →»,
  /// открывает раздел НАСТАВНИК (/mentor).
  final String? theoryChapter;
  final bool showAcknowledge;
}

const _sn006Steps = <_TStep, _StepConfig>{
  // ── Вводная ───────────────────────────────────────────────────────────────
  _TStep.welcome: _StepConfig(
    icon: Icons.gavel_rounded,
    stepLabel: 'ДЕЛО SN-006',
    title: 'ПОДДЕЛЬНЫЙ ЧЕК',
    body: 'Журналист Артём Ковалёв обвиняется в растрате из благотворительного '
        'фонда. Главная улика: его «средние расходы» внезапно выросли в 72 раза. '
        'Защита кричит о подставе — якобы в базу вброшена одна фальшивая '
        'транзакция на 1 000 000 ₽.\n\n'
        'Ваша задача: доказать это математически. Если он невиновен — '
        'числа это покажут.',
  ),

  // ── ЭТАП 1: Приём данных ──────────────────────────────────────────────────
  _TStep.exploreData: _StepConfig(
    icon: Icons.table_chart_outlined,
    stepLabel: 'ЭТАП 1 / 5  ПРИЁМ ДАННЫХ',
    title: 'ИЗУЧИТЕ РАСХОДЫ ЖУРНАЛИСТА',
    body: 'Полистайте записи в таблице DATA: что стоит обычный расход? '
        'Гейта нет — как осмотритесь, жмите СЛЕДУЮЩИЙ ЭТАП.',
    mathNote: 'Первый шаг — построить «паспорт данных»: понять типичный '
        'диапазон трат (это будет наша «норма»). Без нормы нельзя '
        'определить, что является аномалией.',
    pointer: 'Таблица DATA — кликайте по строкам',
    theoryChapter: 'Среднее и медиана',
  ),

  _TStep.intakeDone: _StepConfig(
    icon: Icons.check_circle_outline,
    stepLabel: 'ЭТАП 1 / 5  ГОТОВО',
    title: 'ПАСПОРТ ДАННЫХ ПОСТРОЕН',
    body: 'Видите картину? Большинство расходов — 400–600 ₽. '
        'Одна запись — 1 000 000 ₽ (в ~2000 раз больше).\n\n'
        'Обвинение считает среднее по всем записям — из-за одной суммы '
        'оно раздувается до ~36 000 ₽. Но это — не журналист стал '
        'тратить больше. Сейчас докажем это.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП» в шапке.',
    mathNote: 'Одно гигантское число портит среднее. '
        'Но есть более честный инструмент — медиана. '
        'Она не боится выбросов. Скоро увидим.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП — правый верхний угол',
  ),

  // ── ЭТАП 2: Сопротивление среды ───────────────────────────────────────────
  _TStep.whatIf: _StepConfig(
    icon: Icons.science_outlined,
    stepLabel: 'ЭТАП 2 / 5  СОПРОТИВЛЕНИЕ СРЕДЫ',
    title: 'ЛАБОРАТОРИЯ WHAT-IF',
    body: 'В таблице DATA — зелёная панель WHAT-IF. Двигайте ползунок: подставьте '
        'одной записи огромную сумму и смотрите, как ведут себя среднее и медиана.',
    mathNote: 'Среднее = (Σx)/n: один гигант тащит его на себя. Медиана берёт '
        'серединное значение и почти не двигается. Именно так подброшенный '
        'миллион раздул «средние расходы» журналиста — а медиана осталась прежней.',
    pointer: 'DATA → панель WHAT-IF → тащите ползунок',
    theoryChapter: 'Среднее и медиана',
  ),

  _TStep.cleanupDone: _StepConfig(
    icon: Icons.check_circle_outline,
    stepLabel: 'ЭТАП 2 / 5  ГОТОВО',
    title: 'УСТОЙЧИВОСТЬ ПОНЯТНА',
    body: 'Вы увидели вживую: один выброс ломает среднее, а медиана держится. '
        'Теперь докажем это на реальных данных.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    mathNote: 'Эта чувствительность среднего — ключ дела: обвинение считало '
        'именно среднее. На этапе АНАЛИЗ ответим точными числами.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 3: Анализ ────────────────────────────────────────────────────────
  _TStep.openAnalysis: _StepConfig(
    icon: Icons.show_chart_rounded,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ',
    title: 'ОТКРЫВАЕМ МАТЕМАТИКУ',
    body: 'Нажмите вкладку ANALYSIS в левой панели. '
        'Здесь два метода, которые вместе докажут подлог.',
    mathNote: 'Обвинение опирается на среднее арифметическое — '
        'оно легко обмануть. Мы ответим медианой и Z-оценкой.',
    pointer: '← Левая панель, вкладка с графиком (ANALYSIS)',
  ),

  _TStep.applyMethod1: _StepConfig(
    icon: Icons.functions_outlined,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ — ШАГ 1',
    title: 'СРЕДНЕЕ ПРОТИВ МЕДИАНЫ',
    body: 'Найдите ОПИСАТЕЛЬНАЯ СТАТИСТИКА (DESCRIBE) и нажмите «ПРИМЕНИТЬ». '
        'Метод выдаёт числа; словесный вывод откроется по кнопке «РАСКРЫТЬ ВЫВОД» '
        '(в обучении — бесплатно).',
    mathNote: 'DESCRIBE вычислит и среднее, и медиану:\n\n'
        '  Среднее = (27 × 500 + 1 000 000) / 28 ≈ 36 196 ₽\n'
        '  Медиана ≈ 500 ₽\n\n'
        'Если mean >> median — в данных спрятан «монстр».',
    pointer: 'Список методов → DESCRIBE → ПРИМЕНИТЬ',
    theoryChapter: 'Среднее и медиана',
  ),

  _TStep.method1Result: _StepConfig(
    icon: Icons.analytics_outlined,
    stepLabel: 'РЕЗУЛЬТАТ  DESCRIBE',
    title: 'МЕДИАНА РАЗОБЛАЧАЕТ ПОДЛОГ',
    body: 'Видите разрыв?\n\n'
        '  • Медиана ≈ 500 ₽  →  реальные траты не изменились\n'
        '  • Среднее ≈ 36 000 ₽  →  один выброс взорвал показатель\n\n'
        'Это первое математическое доказательство: '
        'поведение журналиста не изменилось. Изменился один вброс.',
    mathNote: 'Медиана — 50-й перцентиль: она берёт «серединное» значение '
        'в отсортированном списке, игнорируя крайности. '
        'Среднее «сдвигается» даже от одного выброса — медиана нет.\n\n'
        'mean >> median → в массиве есть аномалия справа.',
    showAcknowledge: true,
  ),

  _TStep.applyMethod2: _StepConfig(
    icon: Icons.functions_outlined,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ — ШАГ 2',
    title: 'ИЗОЛИРУЕМ ФАЛЬШИВКУ',
    body: 'Теперь найдите Z-SCORE и нажмите «ПРИМЕНИТЬ». '
        'Он укажет точно, какая запись является выбросом.',
    mathNote: 'Z-оценка считает: насколько каждое значение удалено '
        'от среднего в единицах σ (стандартного отклонения)?\n\n'
        '  Z = (x − μ) / σ\n\n'
        '  Для фальшивки:\n'
        '  Z = (1 000 000 − 500) / 80 ≈ 12 494\n\n'
        '  |Z| > 3 → выброс. 12 494 — математически невозможно случайно.',
    pointer: 'Список методов → Z-SCORE → ПРИМЕНИТЬ',
    theoryChapter: 'Z-оценка и правило 3σ',
  ),

  _TStep.method2Result: _StepConfig(
    icon: Icons.gavel_rounded,
    stepLabel: 'РЕЗУЛЬТАТ  Z-SCORE',
    title: 'Z ≈ 12 494 — ЭТО НЕ СЛУЧАЙНОСТЬ',
    body: 'Z-SCORE нашёл одну точку с |Z| >> 3. Все остальные — в норме.\n\n'
        'Транзакция на 1 000 000 ₽ — не просто «крупная». '
        'Она статистически невозможна в этом датасете.',
    mathNote: 'Правило 3σ: 99.7% нормальных данных в диапазоне μ ± 3σ. '
        'Наш "чек" — в 12 494σ от нормы.\n\n'
        'Вероятность случайного Z = 12 494 — это p ≈ 0 (нулей после '
        'запятой больше, чем атомов во Вселенной). '
        'Вброс доказан.',
    showAcknowledge: true,
  ),

  _TStep.analysisDone: _StepConfig(
    icon: Icons.verified_outlined,
    stepLabel: 'ЭТАП 3 / 5  ГОТОВО',
    title: 'ПОДЛОГ ДОКАЗАН',
    body: 'Два метода согласны:\n\n'
        '  • Медиана ≠ среднее → в массиве выброс\n'
        '  • Z ≈ 12 494 → математически невозможно случайно\n\n'
        'Мы знаем ЧТО аномально. Следующий вопрос — КТО это сделал.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    mathNote: 'Уберите фальшивую транзакцию — среднее мгновенно '
        'вернётся к 500 ₽. Это и есть финальное доказательство.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 4: Подозреваемые ─────────────────────────────────────────────────
  _TStep.accuse: _StepConfig(
    icon: Icons.gavel_outlined,
    stepLabel: 'ЭТАП 4 / 5  ПОДОЗРЕВАЕМЫЕ',
    title: 'ОБВИНИТЕ ВИНОВНОГО',
    body: 'Соберите обвинение:\n'
        '1. Кликните транзакцию 1 000 000 ₽ в DATA (или в протоколе)\n'
        '2. В SUSPECTS у РЕВИЗОРА нажмите «ПРИВЯЗАТЬ УЛИКУ»\n'
        '3. Затем нажмите «ОБВИНИТЬ»',
    mathNote: 'РЕВИЗОР (Дорогин П.В.) — директор фонда, единственный с правами '
        'администратора базы. Привязанная улика — обоснование обвинения, без '
        'неё кнопка ОБВИНИТЬ неактивна.',
    pointer: 'DATA → клик → SUSPECTS → ПРИВЯЗАТЬ → ОБВИНИТЬ',
    theoryChapter: 'Z-оценка и правило 3σ',
  ),

  _TStep.clearSuspect: _StepConfig(
    icon: Icons.verified_user_outlined,
    stepLabel: 'ЭТАП 4 / 5  ПОДОЗРЕВАЕМЫЕ',
    title: 'СНИМИТЕ ПОДОЗРЕНИЕ',
    body: 'Теперь оправдайте журналиста: на его карточке нажмите '
        '«СНЯТЬ ПОДОЗР.». Его алиби железное.',
    mathNote: 'В момент вброса журналист был на борту рейса SU 2408 без '
        'интернета. Обвинять можно одного — с остальных нужно явно снять '
        'подозрение, иначе дело не закрыть.',
    pointer: 'SUSPECTS → ЖУРНАЛИСТ → СНЯТЬ ПОДОЗР.',
  ),

  _TStep.suspectsDone: _StepConfig(
    icon: Icons.group_outlined,
    stepLabel: 'ЭТАП 4 / 5  ГОТОВО',
    title: 'ОБВИНЕНИЕ СОБРАНО',
    body: 'РЕВИЗОР обвинён, журналист вне подозрений. '
        'Математика + доступ + алиби сошлись.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 5: Вердикт ───────────────────────────────────────────────────────
  _TStep.submitVerdict: _StepConfig(
    icon: Icons.gavel_rounded,
    stepLabel: 'ЭТАП 5 / 5  ВЕРДИКТ',
    title: 'ВЫНЕСИТЕ ВЕРДИКТ',
    body: 'Нажмите «ВЫНЕСТИ ВЕРДИКТ» в шапке. РЕВИЗОР уже выбран (вы его '
        'обвинили). В поле «УЛИКА-ЦИФРА» наберите 1000000 и жмите ПРЕДЪЯВИТЬ.',
    mathNote: 'Доказательство: без транзакции 1 000 000 ₽ '
        'среднее = 500 ₽. С ней = 36 000 ₽. '
        'Один вброс — и человек выглядит виновным. '
        'Медиана и Z-оценка разоблачили подлог.',
    pointer: '↑ Кнопка ВЫНЕСТИ ВЕРДИКТ → поле УЛИКА-ЦИФРА',
  ),

  // ── Финал ─────────────────────────────────────────────────────────────────
  _TStep.complete: _StepConfig(
    icon: Icons.emoji_events_outlined,
    stepLabel: 'ДЕЛО ЗАКРЫТО',
    title: 'ЖУРНАЛИСТ ОПРАВДАН',
    body: 'Вы доказали невиновность математически:\n\n'
        '1. ПРИЁМ — типичный расход 400–600 ₽, один аномальный 1 000 000 ₽\n'
        '2. ОЧИСТКА — WHAT-IF: один выброс ломает среднее, медиана устойчива\n'
        '3. АНАЛИЗ — DESCRIBE: медиана ≠ среднему (выброс есть)\n'
        '           Z-SCORE: Z ≈ 12 494 (вброс доказан)\n'
        '4. SUSPECT — РЕВИЗОР обвинён (доступ к БД), журналист оправдан (алиби)\n'
        '5. ВЕРДИКТ — РЕВИЗОР + 1 000 000 ₽\n\n'
        'Инструменты: среднее, медиана, Z-оценка. '
        'Школьная математика спасла человека.',
  ),
};

// ── Дело SN-007 «АНАТОМИЯ ФАЛЬШИВКИ» — Закон Бенфорда ──────────────────────
// Контраст с SN-006: здесь НЕТ выброса. Z-score молчит — каждая сумма
// правдоподобна. Подлог виден только в распределении первых цифр.
const _sn007Steps = <_TStep, _StepConfig>{
  _TStep.welcome: _StepConfig(
    icon: Icons.receipt_long_outlined,
    stepLabel: 'ДЕЛО SN-007',
    title: 'АНАТОМИЯ ФАЛЬШИВКИ',
    body: 'Главбух Илья Зорин обвиняется в краже 5 000 000 ₽ из компании: '
        'сотни мелких переводов (по 3–8 тыс ₽) на фирмы-однодневки. '
        'Он клянётся, что это реальная оплата канцелярии и курьеров, '
        'а фальшивые строки в базу вбросил хакер.\n\n'
        'Ваша задача: доказать, выдуман этот массив человеком или нет. '
        'Здесь нет суммы-«монстра» — обычный детектор выбросов бессилен.',
  ),

  // ── ЭТАП 1: Приём данных ──────────────────────────────────────────────────
  _TStep.exploreData: _StepConfig(
    icon: Icons.table_chart_outlined,
    stepLabel: 'ЭТАП 1 / 5  ПРИЁМ ДАННЫХ',
    title: 'ИЗУЧИТЕ РЕЕСТР ПЕРЕВОДОВ',
    body: 'Полистайте строки в таблице DATA. Каждая сумма выглядит безобидно — '
        '4 800 ₽, 5 200 ₽, 7 100 ₽. Гейта нет — как осмотритесь, жмите далее.',
    mathNote: 'По одной транзакции подлог не виден — любая сумма '
        'правдоподобна. Поэтому ищем не одно «чудовище», а закономерность '
        'во всём массиве: отпечаток, который числа оставляют сами.',
    pointer: 'Таблица DATA — кликайте по строкам',
    theoryChapter: 'Закон Бенфорда',
  ),

  _TStep.intakeDone: _StepConfig(
    icon: Icons.check_circle_outline,
    stepLabel: 'ЭТАП 1 / 5  ГОТОВО',
    title: 'НИ ОДНОГО ВЫБРОСА',
    body: 'Заметили? Все суммы — 3–8 тыс ₽. Гигантских платежей нет, '
        'среднее и медиана почти совпадают. Классическая Z-оценка тут '
        'промолчит — выбивающейся точки не существует.\n\n'
        'Но люди не умеют выдумывать «естественные» числа. Есть закон, '
        'который ловит именно это.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    mathNote: 'Закон Бенфорда официально применяют в аудите и '
        'криминалистике: естественные числа подчиняются строгому закону '
        'первой цифры. Выдуманные — нет.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП — правый верхний угол',
  ),

  // ── ЭТАП 2: Сопротивление среды ───────────────────────────────────────────
  _TStep.whatIf: _StepConfig(
    icon: Icons.science_outlined,
    stepLabel: 'ЭТАП 2 / 5  СОПРОТИВЛЕНИЕ СРЕДЫ',
    title: 'ЛАБОРАТОРИЯ WHAT-IF',
    body: 'В DATA откройте зелёную панель WHAT-IF и потяните ползунок. Так '
        'выглядел бы массив, будь в нём «чудовище» — среднее бы улетело. '
        'Запомните этот эффект.',
    mathNote: 'Подмена показывает, что детекторы выбросов ищут именно такие '
        'спайки. Но в нашем реестре их НЕТ: все суммы 3–8 тыс ₽, среднее ≈ '
        'медиане. Значит, обычная проверка промолчит — подлог придётся ловить иначе.',
    pointer: 'DATA → панель WHAT-IF → тащите ползунок',
    theoryChapter: 'Среднее и медиана',
  ),

  _TStep.cleanupDone: _StepConfig(
    icon: Icons.check_circle_outline,
    stepLabel: 'ЭТАП 2 / 5  ГОТОВО',
    title: 'ВЫБРОСА ЗДЕСЬ НЕТ',
    body: 'Вы увидели, как выглядел бы выброс — и убедились, что в реестре его '
        'нет. Значит, ловим закономерность, а не одну точку.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    mathNote: 'Сначала убедимся, что обычная проверка (Z-score) молчит. '
        'Потом включим Закон Бенфорда.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 3: Анализ ────────────────────────────────────────────────────────
  _TStep.openAnalysis: _StepConfig(
    icon: Icons.show_chart_rounded,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ',
    title: 'ОТКРЫВАЕМ МАТЕМАТИКУ',
    body: 'Нажмите вкладку ANALYSIS в левой панели. '
        'Сначала покажем, что детектор выбросов ничего не находит — '
        'и только потом поймаем подлог Бенфордом.',
    mathNote: 'Защита уверена в себе именно потому, что каждая сумма '
        'по отдельности невинна. Их ошибка — массив в целом.',
    pointer: '← Левая панель, вкладка с графиком (ANALYSIS)',
  ),

  _TStep.applyMethod1: _StepConfig(
    icon: Icons.functions_outlined,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ — ШАГ 1',
    title: 'ДЕТЕКТОР ВЫБРОСОВ МОЛЧИТ',
    body: 'Найдите Z-ОЦЕНКА (Z-SCORE) и нажмите «ПРИМЕНИТЬ». Посмотрим на числа: '
        'выбьется ли хоть одна транзакция. Вывод можно открыть кнопкой «РАСКРЫТЬ ВЫВОД».',
    mathNote: 'Z-оценка ищет точки дальше 3σ от среднего:\n\n'
        '  z = (x − μ) / σ\n\n'
        'Все суммы в диапазоне 3–8 тыс ₽ — ни одна не уходит за 3σ. '
        'Ожидаемо ноль выбросов.',
    pointer: 'Список методов → Z-SCORE → ПРИМЕНИТЬ',
    theoryChapter: 'Z-оценка и правило 3σ',
  ),

  _TStep.method1Result: _StepConfig(
    icon: Icons.search_off_outlined,
    stepLabel: 'РЕЗУЛЬТАТ  Z-SCORE',
    title: '0 ВЫБРОСОВ — И ЭТО ВАЖНО',
    body: 'Z-SCORE не нашёл ничего: |z| < 3 у всех записей. '
        'Каждая транзакция по отдельности — нормальная.\n\n'
        'Вот почему обычная проверка ничего не находит и защита '
        'спокойна. Но массив всё равно может быть выдуман. '
        'Докажем это иначе.',
    mathNote: 'Урок: отсутствие выбросов ≠ отсутствие подлога. '
        'Outlier-методы видят «чудовищ», но слепы к рукотворной '
        'структуре множества. Нужен другой инструмент.',
    showAcknowledge: true,
  ),

  _TStep.applyMethod2: _StepConfig(
    icon: Icons.bar_chart_rounded,
    stepLabel: 'ЭТАП 3 / 5  АНАЛИЗ — ШАГ 2',
    title: 'СНИМАЕМ ОТПЕЧАТКИ ЦИФР',
    body: 'Теперь найдите BENFORD (ЗАКОН БЕНФОРДА) и нажмите «ПРИМЕНИТЬ». '
        'Метод посчитает, как часто каждая цифра 1…9 стоит на первом месте. '
        'Числа видны сразу; словесный вывод — по кнопке «РАСКРЫТЬ ВЫВОД».',
    mathNote: 'Закон первой цифры:\n\n'
        '  P(d) = log₁₀(1 + 1/d)\n\n'
        'В природе «1» открывает число в ~30% случаев, «2» — в ~18%, '
        'а «9» — всего в ~4%. χ² измеряет, насколько реальность '
        'отклонилась от этого закона.',
    pointer: 'Список методов → BENFORD → ПРИМЕНИТЬ',
    theoryChapter: 'Закон Бенфорда',
  ),

  _TStep.method2Result: _StepConfig(
    icon: Icons.gavel_rounded,
    stepLabel: 'РЕЗУЛЬТАТ  BENFORD',
    title: 'χ² ≈ 48 — ПОДЛОГ ДОКАЗАН',
    body: 'Распределение критически не совпало с законом:\n\n'
        '  • Цифры «1» и «2» почти отсутствуют\n'
        '  • На 4, 5 и 7 приходится ≈75% всех сумм\n\n'
        'χ² ≈ 48 при критическом пороге 15.51. Реальные траты так не '
        'выглядят. Вор думал «буду переводить средненько, по 4–5–7 тысяч» '
        'и выдал себя — он не знал законов статистики.',
    mathNote: 'На графике зелёная кривая — эталон Бенфорда. Красные '
        'сегменты столбцов 4/5/7 торчат над ней: это избыток — лишние, '
        'несуществующие переводы. Вероятность, что естественные данные '
        'дадут такой перекос случайно, стремится к нулю. '
        'Массив сфабрикован вручную.',
    showAcknowledge: true,
  ),

  _TStep.analysisDone: _StepConfig(
    icon: Icons.verified_outlined,
    stepLabel: 'ЭТАП 3 / 5  ГОТОВО',
    title: 'МАССИВ ВЫДУМАН',
    body: 'Два метода дали согласованный вывод:\n\n'
        '  • Z-SCORE: 0 выбросов → отдельные суммы невинны\n'
        '  • BENFORD: χ² ≈ 48 → весь массив сфальсифицирован\n\n'
        'Мы знаем, что данные выдуманы. Следующий вопрос — КТО их выдумал.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    mathNote: 'Естественные финансовые данные охватывают много порядков '
        'и всегда тяготеют к Бенфорду. Узкий «коридор» 3–8 тыс с пиками '
        'на 4/5/7 — подпись человека, а не экономики.',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 4: Подозреваемые ─────────────────────────────────────────────────
  _TStep.accuse: _StepConfig(
    icon: Icons.gavel_outlined,
    stepLabel: 'ЭТАП 4 / 5  ПОДОЗРЕВАЕМЫЕ',
    title: 'ОБВИНИТЕ БУХГАЛТЕРА',
    body: 'Соберите обвинение:\n'
        '1. Кликните фальшивый перевод в DATA (или в протоколе)\n'
        '2. В SUSPECTS у БУХГАЛТЕРА нажмите «ПРИВЯЗАТЬ УЛИКУ»\n'
        '3. Затем нажмите «ОБВИНИТЬ»',
    mathNote: 'Журнал БД фиксирует только учётную запись бухгалтера, внешних '
        'подключений в момент вброса нет. Числа «из головы» — его почерк. '
        'Привязанная улика обосновывает обвинение.',
    pointer: 'DATA → клик → SUSPECTS → ПРИВЯЗАТЬ → ОБВИНИТЬ',
    theoryChapter: 'Закон Бенфорда',
  ),

  _TStep.clearSuspect: _StepConfig(
    icon: Icons.verified_user_outlined,
    stepLabel: 'ЭТАП 4 / 5  ПОДОЗРЕВАЕМЫЕ',
    title: 'СНИМИТЕ ПОДОЗРЕНИЕ',
    body: 'Оправдайте АДМИНИСТРАТОРА: на его карточке нажмите «СНЯТЬ ПОДОЗР.». '
        'Версия о «хакере» не выдержала проверки логами.',
    mathNote: 'Логи доступа администратора чисты: внешних подключений и '
        'аномальных сессий в период вброса нет. Обвинять можно одного — '
        'с остальных снимаем подозрение.',
    pointer: 'SUSPECTS → АДМИНИСТРАТОР → СНЯТЬ ПОДОЗР.',
  ),

  _TStep.suspectsDone: _StepConfig(
    icon: Icons.group_outlined,
    stepLabel: 'ЭТАП 4 / 5  ГОТОВО',
    title: 'ОБВИНЕНИЕ СОБРАНО',
    body: 'БУХГАЛТЕР обвинён, администратор вне подозрений. '
        'Фальшивые цифры + ручной ввод + чистые логи = дело готово.\n\n'
        '↗  Нажмите «СЛЕДУЮЩИЙ ЭТАП».',
    pointer: '↑ Кнопка СЛЕДУЮЩИЙ ЭТАП',
  ),

  // ── ЭТАП 5: Вердикт ───────────────────────────────────────────────────────
  _TStep.submitVerdict: _StepConfig(
    icon: Icons.gavel_rounded,
    stepLabel: 'ЭТАП 5 / 5  ВЕРДИКТ',
    title: 'ВЫНЕСИТЕ ВЕРДИКТ',
    body: 'Нажмите «ВЫНЕСТИ ВЕРДИКТ». БУХГАЛТЕР уже выбран (вы его обвинили). '
        'В поле «УЛИКА-ЦИФРА» наберите сами 5000000 — размер растраты — и жмите '
        'ПРЕДЪЯВИТЬ. Этого числа нет ни в одной строке: его доказывает χ², а '
        'называете его вы.',
    mathNote: 'Доказательство неопровержимо: χ² ≈ 48 показывает, что '
        'весь массив переводов выдуман. «Однодневки» получали '
        'несуществующие платежи, а 5 млн ₽ осели у бухгалтера.',
    pointer: '↑ Кнопка ВЫНЕСТИ ВЕРДИКТ → поле УЛИКА-ЦИФРА',
  ),

  // ── Финал ─────────────────────────────────────────────────────────────────
  _TStep.complete: _StepConfig(
    icon: Icons.emoji_events_outlined,
    stepLabel: 'ДЕЛО ЗАКРЫТО',
    title: 'БУХГАЛТЕР ИЗОБЛИЧЁН',
    body: 'Вы поймали ложь чистой статистикой:\n\n'
        '1. ПРИЁМ — сотни мелких «безобидных» переводов\n'
        '2. ОЧИСТКА — WHAT-IF: выброса нет, среднее ≈ медиане\n'
        '3. АНАЛИЗ — Z-SCORE молчит (0 выбросов)\n'
        '           BENFORD: χ² ≈ 48 (подлог доказан)\n'
        '4. SUSPECT — БУХГАЛТЕР обвинён (ручной ввод), админ оправдан (чистые логи)\n'
        '5. ВЕРДИКТ — БУХГАЛТЕР + 5 000 000 ₽\n\n'
        'Закон Бенфорда: математика видит ложь сквозь любой объём данных. '
        'Выдумать «естественную» случайность человек не может.',
  ),
};

// ── Реестр сценариев по делам ──────────────────────────────────────────────
const _scripts = <String, _TutorialScript>{
  'sn-006': _TutorialScript(
    method1: AnalysisMethod.descriptive,
    method2: AnalysisMethod.zScore,
    steps: _sn006Steps,
  ),
  'sn-007': _TutorialScript(
    method1: AnalysisMethod.zScore,
    method2: AnalysisMethod.benford,
    steps: _sn007Steps,
  ),
};

// ──────────────────────────────────────────────────────────────────────────

class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key, required this.caseId});

  final String caseId;

  static bool showFor(String caseId) => _scripts.containsKey(caseId);

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  _TStep _step = _TStep.welcome;
  bool _dismissed = false;
  bool _positionInitialized = false;
  Offset _position = Offset.zero;

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  static const _panelWidth = 390.0;

  _TutorialScript get _script => _scripts[widget.caseId]!;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _initPosition(Size size) {
    if (_positionInitialized) return;
    _position = Offset(size.width - _panelWidth - 20, size.height - 420);
    _positionInitialized = true;
  }

  void _advance(_TStep next) {
    if (!mounted || _dismissed) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _step = next);
  }

  void _dismiss() {
    if (!mounted) return;
    setState(() => _dismissed = true);
  }

  // Если пользователь нажал СЛЕДУЮЩИЙ ЭТАП раньше, чем туториал ожидал,
  // подтягиваемся к актуальной стадии расследования.
  void _catchUp(InvestigationState s) {
    if (_dismissed) return;
    final i = _step.index;
    final stage = s.currentStage;
    _TStep? jump;
    if (stage == InvestigationStage.cleanup && i < _TStep.whatIf.index) {
      jump = _TStep.whatIf;
    } else if (stage == InvestigationStage.analysis &&
        i < _TStep.openAnalysis.index) {
      jump = _TStep.openAnalysis;
    } else if (stage == InvestigationStage.suspects &&
        i < _TStep.accuse.index) {
      jump = _TStep.accuse;
    } else if (stage == InvestigationStage.verdict &&
        i < _TStep.submitVerdict.index) {
      jump = _TStep.submitVerdict;
    }
    if (jump != null) setState(() => _step = jump!);
  }

  void _checkAutoAdvance(InvestigationState? ns) {
    if (ns == null || _dismissed) return;

    _catchUp(ns);

    _TStep? next;
    switch (_step) {
      case _TStep.exploreData:
        if (ns.viewedEvidenceIds.length >= 3) next = _TStep.intakeDone;
      case _TStep.intakeDone:
        if (ns.currentStage == InvestigationStage.cleanup) next = _TStep.whatIf;
      case _TStep.whatIf:
        if (ns.whatIfTried) next = _TStep.cleanupDone;
      case _TStep.cleanupDone:
        if (ns.currentStage == InvestigationStage.analysis) next = _TStep.openAnalysis;
      case _TStep.openAnalysis:
        if (ns.activeTab == WorkspaceTab.analysis) next = _TStep.applyMethod1;
      case _TStep.applyMethod1:
        if (ns.methodResults.containsKey(_script.method1)) {
          next = _TStep.method1Result;
        }
      // method1Result: ручной переход — ПОНЯТНО → applyMethod2
      case _TStep.applyMethod2:
        if (ns.methodResults.containsKey(_script.method2)) {
          next = _TStep.method2Result;
        }
      // method2Result: ручной переход — ПОНЯТНО → analysisDone
      case _TStep.analysisDone:
        if (ns.currentStage == InvestigationStage.suspects) next = _TStep.accuse;
      case _TStep.accuse:
        if (ns.accusedSuspectId != null) next = _TStep.clearSuspect;
      case _TStep.clearSuspect:
        if (ns.accusationBuilt) next = _TStep.suspectsDone;
      case _TStep.suspectsDone:
        if (ns.currentStage == InvestigationStage.verdict) next = _TStep.submitVerdict;
      case _TStep.submitVerdict:
        if (ns.outcome != null) next = _TStep.complete;
      default:
        break;
    }

    if (next != null) _advance(next);
  }

  VoidCallback? _acknowledgeCallback() {
    switch (_step) {
      case _TStep.method1Result:
        return () => _advance(_TStep.applyMethod2);
      case _TStep.method2Result:
        return () => _advance(_TStep.analysisDone);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    ref.listen(
      investigationProvider(widget.caseId),
      (_, next) => _checkAutoAdvance(next),
    );

    final size = MediaQuery.sizeOf(context);
    _initPosition(size);

    final cfg = _script.steps[_step]!;
    final isWelcome = _step == _TStep.welcome;
    final isComplete = _step == _TStep.complete;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      width: _panelWidth,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: _DraggablePanel(
          onDrag: (delta) {
            setState(() {
              _position = Offset(
                (_position.dx + delta.dx).clamp(0.0, size.width - _panelWidth),
                (_position.dy + delta.dy).clamp(0.0, size.height - 120.0),
              );
            });
          },
          child: _TutorialBubble(
            cfg: cfg,
            isWelcome: isWelcome,
            isComplete: isComplete,
            onStart: isWelcome ? () => _advance(_TStep.exploreData) : null,
            onAcknowledge: cfg.showAcknowledge ? _acknowledgeCallback() : null,
            onDone: isComplete ? _dismiss : null,
            onSkip: _dismiss,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────

class _DraggablePanel extends StatelessWidget {
  const _DraggablePanel({required this.onDrag, required this.child});

  final void Function(Offset delta) onDrag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onPanUpdate: (d) => onDrag(d.delta),
          child: MouseRegion(
            cursor: SystemMouseCursors.move,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.neonCyan.withValues(alpha: 0.12),
                border: Border(
                  top: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                  left: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                  right: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.drag_handle_rounded,
                      size: 16,
                      color: AppColors.neonCyan.withValues(alpha: 0.55)),
                  const SizedBox(width: 6),
                  Text(
                    'НАСТАВНИК  •  перетащите',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.neonCyan.withValues(alpha: 0.5),
                          letterSpacing: 1.5,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.cfg,
    required this.isWelcome,
    required this.isComplete,
    this.onStart,
    this.onAcknowledge,
    this.onDone,
    required this.onSkip,
  });

  final _StepConfig cfg;
  final bool isWelcome;
  final bool isComplete;
  final VoidCallback? onStart;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onDone;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.neonCyan;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.5)),
          left: BorderSide(color: accent.withValues(alpha: 0.5)),
          right: BorderSide(color: accent.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 28,
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.voidBlack.withValues(alpha: 0.94),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────
          Row(
            children: [
              Icon(cfg.icon, color: accent, size: 15),
              const SizedBox(width: 7),
              Text(
                cfg.stepLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: accent,
                  letterSpacing: 1.8,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (!isWelcome && !isComplete)
                GestureDetector(
                  onTap: onSkip,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(Icons.close,
                        color: AppColors.textMuted, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Title ────────────────────────────────────────────────────
          Text(
            cfg.title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 1.8,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),

          // ── Body ─────────────────────────────────────────────────────
          Text(
            cfg.body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
          ),

          // ── Math note ────────────────────────────────────────────────
          if (cfg.mathNote != null) ...[
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: const BoxDecoration(
                color: Color(0x0DFFB23F),
                border: Border(
                  left: BorderSide(color: AppColors.amberWarning, width: 2),
                ),
              ),
              child: Text(
                cfg.mathNote!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.amberWarning.withValues(alpha: 0.85),
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                ),
              ),
            ),
          ],

          // ── Pointer ──────────────────────────────────────────────────
          if (cfg.pointer != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(Icons.near_me_outlined,
                    color: accent.withValues(alpha: 0.65), size: 11),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    cfg.pointer!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent.withValues(alpha: 0.65),
                      letterSpacing: 1,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Theory link ──────────────────────────────────────────────
          if (cfg.theoryChapter != null) ...[
            const SizedBox(height: 9),
            _TutorialTheoryLink(chapter: cfg.theoryChapter!),
          ],

          // ── Action buttons ───────────────────────────────────────────
          if (isWelcome || isComplete || onAcknowledge != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (isWelcome) ...[
                  _Btn(
                    label: 'НАЧАТЬ РАССЛЕДОВАНИЕ',
                    color: accent,
                    onTap: onStart ?? () {},
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(width: 8),
                  _Btn(
                    label: 'ПРОПУСТИТЬ',
                    color: AppColors.textMuted,
                    onTap: onSkip,
                    outlined: true,
                  ),
                ] else if (isComplete) ...[
                  _Btn(
                    label: 'ЗАКРЫТЬ',
                    color: AppColors.jadeSuccess,
                    onTap: onDone ?? onSkip,
                    icon: Icons.check_rounded,
                  ),
                ] else if (onAcknowledge != null) ...[
                  _Btn(
                    label: 'ПОНЯТНО →',
                    color: accent,
                    onTap: onAcknowledge!,
                    icon: Icons.arrow_forward,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────

/// Ссылка на полную теорию в разделе НАСТАВНИК — те же ссылки, что и в
/// MentorTab, но прямо в туториале.
class _TutorialTheoryLink extends StatefulWidget {
  const _TutorialTheoryLink({required this.chapter});
  final String chapter;

  @override
  State<_TutorialTheoryLink> createState() => _TutorialTheoryLinkState();
}

class _TutorialTheoryLinkState extends State<_TutorialTheoryLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.neonCyan;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push('/mentor'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: _hover ? 0.1 : 0.04),
            border: Border.all(
              color: accent.withValues(alpha: _hover ? 0.6 : 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_stories_outlined,
                  color: accent, size: 14),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Полная теория: «${widget.chapter}» →',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: accent,
                    letterSpacing: 1,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  const _Btn({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.outlined = false,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final bool outlined;

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.outlined
                ? Colors.transparent
                : widget.color.withValues(alpha: _hover ? 0.2 : 0.1),
            border: Border.all(
              color: widget.color
                  .withValues(alpha: widget.outlined ? 0.35 : 0.7),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.color, size: 13),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: widget.color,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
