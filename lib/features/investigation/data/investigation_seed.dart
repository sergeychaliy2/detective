import 'dart:math';

import '../../case_board/domain/entities/case_entity.dart';
import '../domain/entities/evidence_entity.dart';
import '../domain/entities/suspect_entity.dart';

/// Процедурный сидер: для каждого дела генерирует фоновый шум улик и
/// "сажает" единственную smoking-gun-улику со значением solutionValue,
/// привязанную к solutionSuspectId.
///
/// Cид RNG получаем из caseId+title — расследование одно и то же
/// между запусками (для воспроизводимости), но числа гарантированно
/// разные между делами и не совпадают со статикой из ИП.
class InvestigationSeed {
  InvestigationSeed._();

  static const _evidenceCount = 28;

  static List<EvidenceEntity> evidenceFor(CaseEntity c) {
    if (c.id == 'sn-007') return _benfordTransactions(c);
    final rng = Random('${c.id}|${c.title}'.hashCode);
    final base = DateTime(2026, 5, 1, 9);
    final kinds = EvidenceKind.values;
    final solutionKind = kinds[c.solutionEvidenceKindIndex.clamp(0, kinds.length - 1)];

    // Распределяем подозреваемых-носителей улик по индексам, чтобы у
    // каждой улики был "владелец" — для NETWORK-визуализации.
    final suspectIds = ['S1', 'S2', 'S3', 'S4'];

    // Выбираем индекс smoking-gun — фиксированный для воспроизводимости.
    final gunIndex = rng.nextInt(_evidenceCount);

    return List.generate(_evidenceCount, (i) {
      final kind = i == gunIndex ? solutionKind : kinds[rng.nextInt(kinds.length)];
      final isGun = i == gunIndex;
      final assignedSuspect = isGun
          ? c.solutionSuspectId
          : suspectIds[rng.nextInt(suspectIds.length)];

      // Значение улики:
      // — smoking-gun: ровно solutionValue
      // — обычная улика того же типа, что и ответ: значение из шумового
      //   распределения (mean ± std), чтобы выброс выделялся
      // — улика другого типа: рандом для разнообразия таблицы
      num value;
      if (isGun) {
        value = c.solutionValue;
      } else if (kind == solutionKind) {
        value = (c.noiseMean + _gauss(rng) * c.noiseStd)
            .clamp(0, double.infinity);
        value = (value as double).round();
      } else {
        value = rng.nextInt(99999);
      }

      return EvidenceEntity(
        id: 'EV-${i.toString().padLeft(4, '0')}',
        timestamp: base.add(Duration(minutes: i * 47 + rng.nextInt(120))),
        kind: kind,
        source: _sourceFor(kind, rng),
        summary: _summaryFor(kind, rng, value),
        value: value,
        suspectId: assignedSuspect,
        isSmokingGun: isGun,
      );
    });
  }

  static List<SuspectEntity> suspectsFor(String caseId) {
    if (caseId == 'sn-006') return _sn006Suspects;
    if (caseId == 'sn-007') return _sn007Suspects;
    return _defaultSuspects;
  }

  /// Суммы дела «Анатомия фальшивки»: выдуманы человеком — первые цифры
  /// скучкованы на 4/5/7, «1» и «2» отсутствуют. Классических выбросов нет
  /// (все 3–8 тыс ₽ → Z-score молчит), но χ² Бенфорда ≈ 48 >> 15.51.
  static const _benfordAmounts = <int>[
    3200, 3500, 3800, //                         d=3 ×3
    4100, 4300, 4500, 4600, 4800, 4200, 4700, 4900, // d=4 ×8
    5100, 5200, 5400, 5600, 5800, 5300, 5500, //  d=5 ×7
    6100, 6400, //                                d=6 ×2
    7100, 7200, 7400, 7600, 7800, 7300, //        d=7 ×6
    8100, 8300, //                                d=8 ×2
  ];

  static List<EvidenceEntity> _benfordTransactions(CaseEntity c) {
    final rng = Random('${c.id}|${c.title}'.hashCode);
    final base = DateTime(2026, 3, 2, 9);
    // smoking-gun — типичная «средняя» фальшивка на 4 800 ₽: образец
    // рукотворной суммы. Значение НЕ равно solutionValue — подлог доказывает
    // распределение первых цифр всего массива, а не одна строка.
    const gunIndex = 7;
    return List.generate(_benfordAmounts.length, (i) {
      final value = _benfordAmounts[i];
      final isGun = i == gunIndex;
      final firstDigit = value ~/ 1000;
      // Рукотворные суммы (4/5/7) вешаем на бухгалтера, остальное — на админа.
      final assigned = isGun
          ? c.solutionSuspectId
          : (firstDigit == 4 || firstDigit == 5 || firstDigit == 7)
              ? 'S1'
              : 'S2';
      return EvidenceEntity(
        id: 'EV-${i.toString().padLeft(4, '0')}',
        timestamp: base.add(Duration(minutes: i * 53 + rng.nextInt(40))),
        kind: EvidenceKind.transaction,
        source: 'BANK_LEDGER',
        summary: 'Перевод $value ₽ → ООО «${_shellName(rng)}» (контрагент-однодневка)',
        value: value,
        suspectId: assigned,
        isSmokingGun: isGun,
      );
    });
  }

  static String _shellName(Random rng) {
    const a = ['Прайм', 'Гелиос', 'Аркада', 'Вектор', 'Орион', 'Стандарт', 'Меридиан', 'Капитал'];
    const b = ['Снаб', 'Трейд', 'Логистик', 'Сервис', 'Групп', 'Холдинг', 'Маркет'];
    return '${a[rng.nextInt(a.length)]}-${b[rng.nextInt(b.length)]}';
  }

  static const _sn007Suspects = [
    SuspectEntity(
      id: 'S1',
      codename: 'БУХГАЛТЕР',
      role: 'Илья Зорин, главный бухгалтер',
      bio: 'Обвиняется в растрате 5 000 000 ₽ через сотни мелких переводов '
          'фирмам-однодневкам. Утверждает, что строки в базу добавил хакер.',
      threatLevel: 5,
      alibi: 'Ссылается на взлом. Но журнал БД фиксирует только его учётную '
          'запись: все спорные строки введены вручную, изнутри.',
      connectedEvidence: ['EV-0007', 'EV-0011', 'EV-0020'],
    ),
    SuspectEntity(
      id: 'S2',
      codename: 'АДМИНИСТРАТОР',
      role: 'Марк Вейс, системный администратор',
      bio: 'На него указывает версия о «хакере»: имел технический доступ '
          'к серверу расходов.',
      threatLevel: 2,
      alibi: 'Логи доступа чисты: внешних подключений и аномальных сессий '
          'в период вброса нет. Версия о взломе не подтверждается.',
      connectedEvidence: ['EV-0000', 'EV-0018', 'EV-0026'],
    ),
  ];

  static const _sn006Suspects = [
    SuspectEntity(
      id: 'S1',
      codename: 'ЖУРНАЛИСТ',
      role: 'Артём Ковалёв, репортёр-расследователь',
      bio: 'Обвиняется в растрате. Утверждает, что подставлен. '
          'В момент спорной транзакции находился на борту рейса SU 2408.',
      threatLevel: 1,
      alibi: 'Авиарейс SU 2408 Москва — Берлин, 18:40–21:10. '
          'Без интернета. Подтверждено бортпроводником и телеметрией телефона.',
      connectedEvidence: ['EV-0001', 'EV-0008', 'EV-0015'],
    ),
    SuspectEntity(
      id: 'S2',
      codename: 'РЕВИЗОР',
      role: 'Павел Дорогин, директор фонда',
      bio: 'Единственный сотрудник с правами администратора базы расходов. '
          'Мотив: скрыть собственные растраты, переложив вину на журналиста.',
      threatLevel: 5,
      alibi: 'Алиби отсутствует. VPN-логи подтверждают доступ к серверу '
          'в момент появления спорной транзакции.',
      connectedEvidence: ['EV-0003', 'EV-0011', 'EV-0019'],
    ),
  ];

  static const _defaultSuspects = [
    SuspectEntity(
      id: 'S1',
      codename: 'ШЕРИФ',
      role: 'Финансовый директор',
      bio: 'Имеет доступ к корпоративному счёту и истории транзакций. Холоден, методичен.',
      threatLevel: 4,
      alibi: 'Командировка в день вывода средств. Алиби подтверждено отелем.',
      connectedEvidence: ['EV-0003', 'EV-0011', 'EV-0021'],
    ),
    SuspectEntity(
      id: 'S2',
      codename: 'ПАЛОМНИК',
      role: 'IT-администратор',
      bio: 'Знает архитектуру системы изнутри. Конфликт с руководством.',
      threatLevel: 5,
      alibi: 'Был на работе, но без свидетелей.',
      connectedEvidence: ['EV-0007', 'EV-0014', 'EV-0019', 'EV-0025'],
    ),
    SuspectEntity(
      id: 'S3',
      codename: 'СВИДЕТЕЛЬ',
      role: 'Аналитик отдела рисков',
      bio: 'Первой обнаружила аномалию и сообщила в службу безопасности.',
      threatLevel: 2,
      alibi: 'Работала из дома, есть VPN-логи.',
      connectedEvidence: ['EV-0001', 'EV-0005'],
    ),
    SuspectEntity(
      id: 'S4',
      codename: 'ТЕНЬ',
      role: 'Бывший сотрудник',
      bio: 'Уволен месяцем ранее. Сохранил доступ к части систем.',
      threatLevel: 3,
      alibi: 'Алиби отсутствует.',
      connectedEvidence: ['EV-0012', 'EV-0017'],
    ),
  ];

  /// Box-Muller — стандартное нормальное.
  static double _gauss(Random rng) {
    final u1 = rng.nextDouble().clamp(1e-9, 1.0);
    final u2 = rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  static String _sourceFor(EvidenceKind kind, Random rng) {
    switch (kind) {
      case EvidenceKind.transaction:
        return 'BANK_LEDGER';
      case EvidenceKind.message:
        return 'CHAT_DUMP_${rng.nextInt(7) + 1}';
      case EvidenceKind.log:
        return 'SYS_LOG_${['AUTH', 'ACL', 'GW'][rng.nextInt(3)]}';
      case EvidenceKind.contact:
        return 'PHONE_RECORD';
      case EvidenceKind.test:
        return 'LAB_REPORT_${rng.nextInt(20)}';
      case EvidenceKind.document:
        return 'DOC_${rng.nextInt(99)}';
    }
  }

  static String _summaryFor(EvidenceKind kind, Random rng, num value) {
    switch (kind) {
      case EvidenceKind.transaction:
        return 'Перевод ≈ $value → счёт-получатель ##${rng.nextInt(99999)}';
      case EvidenceKind.message:
        return 'Сообщение между фигурантами. Маркеры: спешка, обиняки.';
      case EvidenceKind.log:
        return 'Подключение с нетипового IP. Сессия ${rng.nextInt(9999)}.';
      case EvidenceKind.contact:
        return 'Звонок ${rng.nextInt(58) + 1} мин. Геолокация совпадает.';
      case EvidenceKind.test:
        return 'Результат теста: Ct = $value, p < 0.0${rng.nextInt(9) + 1}.';
      case EvidenceKind.document:
        return 'Поправка к протоколу #$value. Подпись расходится с эталоном.';
    }
  }
}
