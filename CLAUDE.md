# CLAUDE.md — правила работы с проектом "Тень числа"

## О проекте
Flutter-приложение `detective` ("Тень числа", Shadow of Number) — детективный симулятор для математиков. Первичная платформа — Windows. Концепция и сюжетные блоки лежат в `C:\Users\Sergey\Downloads\ИП 1.pptx` и `text_dlya_IP.docx`. Референсы стилистики скопированы в `C:\VS_Code\style_refs\image1..9.png`.

## Архитектура (обязательна)
Clean Architecture со срезами по фичам: `lib/features/<name>/{data,domain,presentation}`. Общие вещи — в `lib/core/{theme,router,widgets,constants,utils,errors}`. Не складывать UI/виджеты в `core/widgets`, если они специфичны для одной фичи — такие должны жить внутри `features/<name>/presentation/widgets`.

## State management
`flutter_riverpod` + `riverpod_generator`. Use cases чистые (без флаттера), репозитории — абстракции в `domain`, реализации — в `data`.

## Стиль кода
- Без комментариев-описаний WHAT. Допустим короткий комментарий WHY рядом с не-очевидным решением (одна строка).
- Никаких `// TODO` без задачи в трекере.
- Имена: классы `UpperCamelCase`, файлы `snake_case.dart`, провайдеры `<feature>Provider`.
- Все цвета — через `AppColors`, все размеры/тайминги — через `AppMetrics`. Не вводить хардкод-цвета в виджетах.

## Дизайн-язык
- Тёмная киберпанк-палитра, неоновый циан (`AppColors.neonCyan`) и магента (`AppColors.magenta`).
- Шрифты: `Orbitron` (display), `Rajdhani` (titles), `JetBrains Mono` (data/labels), `Inter` (body) — через `google_fonts`.
- Базовая подложка экрана — `HudBackground` (grid + particles + scanline). Панели — `NeonPanel`. Кнопки — `GlowButton`. Анимации текста — `GlitchText` + `flutter_animate`.
- Анимации обязаны быть плавными (`AppMetrics.easeOutExpo`, длительности из `AppMetrics`). Не использовать линейные кривые.

## Производительность
- Любые повторяющиеся анимации делаются через `AnimationController` с `IgnorePointer`, не через `setState` в `Timer`.
- `CustomPainter` для фоновых эффектов — без аллокаций в `paint()`.
- `const`-конструкторы по умолчанию. Listenable-перерисовки локализуем `AnimatedBuilder`-ом.

## Команды
```powershell
cd C:\VS_Code\Detective
flutter pub get
flutter run -d windows
flutter analyze
flutter test
dart run build_runner build --delete-conflicting-outputs
```

## Что НЕ делать
- Не плодить новые слои абстракций "на будущее".
- Не переписывать `core/theme` под Material 2 — проект на M3.
- Не возвращать дефолтные `MaterialApp` цвета — всё через `AppTheme.dark()`.
- Не использовать `MediaQuery` для адаптации, если можно `LayoutBuilder`.
