import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Этапы расследования из концепции ИП:
/// "От гипотезы до приговора" — нелинейное следствие в 5 шагов.
enum InvestigationStage {
  intake(
    code: 'I',
    title: 'ПРИЁМ ДАННЫХ',
    description: 'Доступ к массиву информации: переписки, транзакции, логи.',
    icon: Icons.cloud_download_outlined,
    color: AppColors.hologramBlue,
  ),
  cleanup(
    code: 'II',
    title: 'СОПРОТИВЛЕНИЕ СРЕДЫ',
    description: 'Очистка дубликатов, восстановление пропусков, отсев шума.',
    icon: Icons.cleaning_services_outlined,
    color: AppColors.electricBlue,
  ),
  analysis(
    code: 'III',
    title: 'АНАЛИЗ',
    description: 'Статистика, теория графов, криптография в действии.',
    icon: Icons.insights_outlined,
    color: AppColors.neonCyan,
  ),
  suspects(
    code: 'IV',
    title: 'ПОДОЗРЕВАЕМЫЕ',
    description: 'Сопоставление улик с фигурантами дела.',
    icon: Icons.groups_2_outlined,
    color: AppColors.violet,
  ),
  verdict(
    code: 'V',
    title: 'ВЕРДИКТ',
    description: 'Точка невозврата: предъявление финальной улики-цифры.',
    icon: Icons.gavel_rounded,
    color: AppColors.magenta,
  );

  const InvestigationStage({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String code;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

/// Вкладки рабочего пространства расследования.
enum WorkspaceTab {
  data(label: 'DATA', icon: Icons.table_chart_outlined),
  analysis(label: 'ANALYSIS', icon: Icons.show_chart_rounded),
  network(label: 'NETWORK', icon: Icons.hub_outlined),
  suspects(label: 'SUSPECTS', icon: Icons.fingerprint),
  mentor(label: 'MENTOR', icon: Icons.psychology_alt_outlined);

  const WorkspaceTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}
