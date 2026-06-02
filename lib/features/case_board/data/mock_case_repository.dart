import '../domain/entities/case_entity.dart';
import '../domain/repositories/case_repository.dart';
import '../../investigation/domain/entities/analysis_method.dart';
import '../../investigation/domain/entities/evidence_entity.dart';

/// Сид-данные дел. На MVP это in-memory источник; в будущем здесь
/// окажется загрузка из ассетов / API / редактора преподавателя.
///
/// Каждое дело несёт solutionValue + solutionEvidenceKindIndex —
/// процедурный сидер посадит "улику-цифру" в один из EvidenceEntity
/// именно того типа, и игрок должен её опознать.
class MockCaseRepository implements CaseRepository {
  const MockCaseRepository();

  @override
  Future<List<CaseEntity>> fetchCases() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return [
      CaseEntity(
        id: 'sn-001',
        code: 'SN-001',
        title: 'ШЕПОТ В ДАННЫХ',
        brief:
            'В 10 000 транзакций корпоративного банка спрятана цепочка вывода средств. '
            'Найдите аномалию и спасите невиновного от тюрьмы.',
        theme: CaseTheme.finance,
        difficulty: CaseDifficulty.trainee,
        status: CaseStatus.available,
        rewardXp: 120,
        dataPoints: 10000,
        suspects: 4,
        evidenceTypes: const ['Логи транзакций', 'Переписка', 'Геометки'],
        solutionSuspectId: 'S2',
        solutionValue: 4200,
        solutionTolerance: 50,
        solutionEvidenceKindIndex: EvidenceKind.transaction.index,
        solutionMethod: AnalysisMethod.zScore,
        solutionRationale:
            'Аномальная транзакция выпадает из 3σ распределения штатных переводов. '
            'Сумма ≈ 4200 — единственный платёж, ушедший на счёт-получатель, '
            'связанный с IT-администратором (ПАЛОМНИК).',
        theoryHints: const [
          'Постройте паспорт колонок: типы, диапазоны, пропуски. Не считайте средние раньше времени.',
          'Дубликаты по timestamp + сумма — возможный шум синхронизации систем. Уберите.',
          'Распределение transaction.value скошено: используйте медиану/MAD, а не среднее.',
          'Сопоставьте FLAGGED-транзакции с алиби фигурантов. Совпадение во времени = улика.',
          'Финальная цифра — ровно одна транзакция, не входящая в 3σ-полосу штатных операций.',
        ],
        noiseMean: 1850,
        noiseStd: 520,
      ),
      CaseEntity(
        id: 'sn-002',
        code: 'SN-002',
        title: 'НУЛЕВОЙ ПАЦИЕНТ',
        brief:
            'Эпидемиологическая вспышка в закрытом городе. По датасету анализов '
            'и графу контактов определите источник заражения.',
        theme: CaseTheme.biostatistics,
        difficulty: CaseDifficulty.practice,
        status: CaseStatus.available,
        rewardXp: 280,
        dataPoints: 24380,
        suspects: 7,
        evidenceTypes: const ['Тесты PCR', 'Граф контактов', 'Журналы клиник'],
        solutionSuspectId: 'S1',
        solutionValue: 17,
        solutionTolerance: 1,
        solutionEvidenceKindIndex: EvidenceKind.test.index,
        solutionMethod: AnalysisMethod.mad,
        solutionRationale:
            'Цикл амплификации (Ct) = 17 — самый низкий в выборке, что указывает '
            'на максимальную вирусную нагрузку. Носитель — ШЕРИФ. MAD устойчив '
            'к нескольким артефактным замерам и точно изолирует аномально низкий Ct.',
        theoryHints: const [
          'PCR Ct ≤ 20 = высокая нагрузка. Сортируйте улики типа TEST по value.',
          'Удалите ложноположительные с Ct > 35 — это шум.',
          'Постройте distribution Ct, найдите outlier слева. Это и есть нулевой пациент.',
          'Свяжите outlier с фигурантом через граф контактов в NETWORK.',
          'Финальное значение — Ct самой ранней пробы носителя.',
        ],
        noiseMean: 28,
        noiseStd: 4,
      ),
      CaseEntity(
        id: 'sn-003',
        code: 'SN-003',
        title: 'ТЕНЬ ИЗБИРАТЕЛЯ',
        brief:
            'Результаты регионального голосования отклоняются от теоретического '
            'распределения. Найдите участки с фальсификацией.',
        theme: CaseTheme.sociology,
        difficulty: CaseDifficulty.practice,
        status: CaseStatus.available,
        rewardXp: 320,
        dataPoints: 7421,
        suspects: 12,
        evidenceTypes: const ['Протоколы', 'Хронология', 'Социальные сети'],
        solutionSuspectId: 'S4',
        solutionValue: 312,
        solutionTolerance: 5,
        solutionEvidenceKindIndex: EvidenceKind.document.index,
        solutionMethod: AnalysisMethod.benford,
        solutionRationale:
            'Закон Бенфорда: первая цифра должна распределяться неравномерно. '
            'На участке #312 первые цифры распределены равномерно — признак подделки.',
        theoryHints: const [
          'Распределение явок по нормальному закону — фальшь шифруется выбросами.',
          'Объедините дубликаты протоколов; ручные правки = подозрение.',
          'Проверьте закон Бенфорда на первых цифрах протоколов.',
          'Связь "ТЕНЬ" + участок #312 видна по геометкам в NETWORK.',
          'Цифра вердикта — номер участка с самым явным нарушением Бенфорда.',
        ],
        noiseMean: 380,
        noiseStd: 90,
      ),
      CaseEntity(
        id: 'sn-004',
        code: 'SN-004',
        title: 'ПОСЛЕДНИЙ ОБВАЛ',
        brief:
            'Серия подозрительных коротких позиций предшествует падению акций '
            'технологической компании. Кто знал заранее?',
        theme: CaseTheme.econometrics,
        difficulty: CaseDifficulty.exam,
        status: CaseStatus.available,
        rewardXp: 540,
        dataPoints: 56210,
        suspects: 9,
        evidenceTypes: const ['Биржевые тики', 'Корпоративные мейлы', 'Контракты'],
        solutionSuspectId: 'S2',
        solutionValue: 87,
        solutionTolerance: 2,
        solutionEvidenceKindIndex: EvidenceKind.transaction.index,
        solutionMethod: AnalysisMethod.iqr,
        solutionRationale:
            'Объём short-позиций за 87 минут до публикации убытков превышает '
            'дневную медиану в 14 раз. Только ПАЛОМНИК имел доступ к pre-release.',
        theoryHints: const [],
        noiseMean: 32,
        noiseStd: 11,
      ),
      CaseEntity(
        id: 'sn-005',
        code: 'SN-005',
        title: 'РАСШИФРОВАННЫЙ',
        brief:
            'Перехваченные сообщения зашифрованы шифром Виженера с подменой ключей. '
            'Восстановите ключ и прочтите сообщение.',
        theme: CaseTheme.cryptography,
        difficulty: CaseDifficulty.exam,
        status: CaseStatus.locked,
        rewardXp: 620,
        dataPoints: 1840,
        suspects: 3,
        evidenceTypes: const ['Шифротексты', 'Лог-файлы', 'Аудио'],
        solutionSuspectId: 'S3',
        solutionValue: 41,
        solutionTolerance: 0,
        solutionEvidenceKindIndex: EvidenceKind.message.index,
        solutionMethod: AnalysisMethod.spearman,
        solutionRationale:
            'Длина ключа Виженера = 41, найдена анализом индекса совпадений Casiski.',
        theoryHints: const [],
        noiseMean: 16,
        noiseStd: 6,
      ),
      CaseEntity(
        id: 'sn-006',
        code: 'SN-006',
        title: 'ПЕРВОЕ ПРИКОСНОВЕНИЕ',
        brief:
            'Туториал-дело. Наставник проведёт за руку через приём данных, '
            'очистку и базовый статистический анализ.',
        theme: CaseTheme.finance,
        difficulty: CaseDifficulty.trainee,
        status: CaseStatus.available,
        rewardXp: 80,
        dataPoints: 1200,
        suspects: 2,
        evidenceTypes: const ['Чеки', 'Переписка'],
        solutionSuspectId: 'S1',
        solutionValue: 1100,
        solutionTolerance: 10,
        solutionEvidenceKindIndex: EvidenceKind.transaction.index,
        solutionMethod: AnalysisMethod.zScore,
        solutionRationale:
            'Единственный чек на сумму ≈ 1100, выпавший из штатной полосы '
            '(остальные равномерно в 200–500).',
        theoryHints: const [
          'Откройте таблицу DATA, прочтите все чеки. Запомните типичный диапазон.',
          'Проставьте FLAG на любом чеке, выходящем за привычный диапазон.',
          'Откройте ANALYSIS — гистограмма мгновенно покажет выброс.',
          'В SUSPECTS привяжите чек-выброс к ШЕРИФУ.',
          'Вердикт: ШЕРИФ + 1100. Это была репетиция.',
        ],
        noiseMean: 320,
        noiseStd: 110,
      ),
    ];
  }
}
