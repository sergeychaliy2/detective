import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/buttons/glow_button.dart';
import '../../../../../core/widgets/panels/neon_panel.dart';
import '../../../../../core/widgets/text/glitch_text.dart';
import '../../../../case_board/domain/entities/case_entity.dart';
import '../../../domain/entities/analysis_method.dart';
import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/evidence_entity.dart';
import '../../../domain/entities/suspect_entity.dart';

/// Overlay вердикта: игрок выбирает подозреваемого + улику-цифру.
/// Источник цифры — либо outlier из применённого метода (правильный путь),
/// либо ручной ввод (override).
class VerdictOverlay extends StatefulWidget {
  const VerdictOverlay({
    super.key,
    required this.caseInfo,
    required this.suspects,
    required this.evidence,
    required this.evidenceLinks,
    required this.methodResults,
    required this.onCancel,
    required this.onSubmit,
  });

  final CaseEntity caseInfo;
  final List<SuspectEntity> suspects;
  final List<EvidenceEntity> evidence;
  final Map<String, String> evidenceLinks;
  final Map<AnalysisMethod, AnalysisResult> methodResults;
  final VoidCallback onCancel;
  final void Function(String suspectId, num value) onSubmit;

  @override
  State<VerdictOverlay> createState() => _VerdictOverlayState();
}

class _VerdictOverlayState extends State<VerdictOverlay> {
  String? _suspectId;
  final _valueController = TextEditingController();
  bool _manualMode = false;
  String? _selectedCandidateKey;

  @override
  void initState() {
    super.initState();
    _manualMode = widget.methodResults.isEmpty;
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  bool get _isReady {
    if (_suspectId == null) return false;
    final v = num.tryParse(_valueController.text.replaceAll(',', '.'));
    return v != null;
  }

  /// Уникальные кандидаты — выбросы из всех применённых методов,
  /// сгруппированные по evidence.id (один outlier может быть найден
  /// несколькими методами — мы их объединим).
  List<_Candidate> _buildCandidates() {
    final byId = <String, _Candidate>{};
    widget.methodResults.forEach((method, result) {
      for (final hit in result.outliers) {
        final id = hit.evidence.id;
        final c = byId[id];
        if (c == null) {
          byId[id] = _Candidate(
            evidence: hit.evidence,
            methods: {method: hit.scoreLabel},
          );
        } else {
          c.methods[method] = hit.scoreLabel;
        }
      }
    });
    final list = byId.values.toList()
      ..sort((a, b) => b.methods.length.compareTo(a.methods.length));
    return list;
  }

  String _suspectFor(EvidenceEntity e) =>
      widget.evidenceLinks[e.id] ?? e.suspectId ?? '?';

  void _pickCandidate(_Candidate c) {
    setState(() {
      _selectedCandidateKey = c.evidence.id;
      _suspectId = _suspectFor(c.evidence);
      _valueController.text = '${c.evidence.value}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = _buildCandidates();

    return ColoredBox(
      color: AppColors.voidBlack.withValues(alpha: 0.92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: NeonPanel(
              borderColor: AppColors.magenta,
              glow: 24,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'POINT OF NO RETURN',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.magenta, letterSpacing: 5),
                      ),
                      const Spacer(),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: widget.onCancel,
                          child: const Icon(Icons.close,
                              color: AppColors.textSecondary, size: 22),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlitchText(
                    'ВЫНЕСТИ ВЕРДИКТ',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 32,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Подозреваемый + улика-цифра. Цифра должна быть обоснована — '
                    'выбирай кандидата из применённых статистических методов '
                    '(или нажми OVERRIDE и введи вручную).',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 6,
                          child: candidates.isEmpty
                              ? _NoMethodsHint(theme: theme)
                              : _CandidatesPanel(
                                  candidates: candidates,
                                  selectedKey: _selectedCandidateKey,
                                  suspectFor: _suspectFor,
                                  onPick: _pickCandidate,
                                  manualMode: _manualMode,
                                  onToggleManual: () => setState(() {
                                    _manualMode = !_manualMode;
                                    if (_manualMode) {
                                      _selectedCandidateKey = null;
                                    }
                                  }),
                                ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 4,
                          child: _SuspectsAndValue(
                            suspects: widget.suspects,
                            currentSuspect: _suspectId,
                            onPickSuspect: (id) =>
                                setState(() => _suspectId = id),
                            valueController: _valueController,
                            allowEditValue: candidates.isEmpty || _manualMode,
                            onValueChanged: () => setState(() {
                              _selectedCandidateKey = null;
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      GlowButton(
                        label: 'ОТМЕНА',
                        icon: Icons.close,
                        color: AppColors.textSecondary,
                        onPressed: widget.onCancel,
                        width: 200,
                      ),
                      const Spacer(),
                      GlowButton(
                        label: 'ПРЕДЪЯВИТЬ',
                        icon: Icons.gavel,
                        color: AppColors.magenta,
                        accent: AppColors.neonCyan,
                        onPressed: _isReady
                            ? () => widget.onSubmit(
                                  _suspectId!,
                                  num.parse(_valueController.text
                                      .replaceAll(',', '.')),
                                )
                            : null,
                        width: 280,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 320.ms)
        .scale(
          begin: const Offset(0.96, 0.96),
          end: const Offset(1, 1),
          duration: 380.ms,
          curve: Curves.easeOutExpo,
        );
  }
}

class _Candidate {
  _Candidate({required this.evidence, required this.methods});
  final EvidenceEntity evidence;
  final Map<AnalysisMethod, String> methods;
}

class _CandidatesPanel extends StatelessWidget {
  const _CandidatesPanel({
    required this.candidates,
    required this.selectedKey,
    required this.suspectFor,
    required this.onPick,
    required this.manualMode,
    required this.onToggleManual,
  });

  final List<_Candidate> candidates;
  final String? selectedKey;
  final String Function(EvidenceEntity) suspectFor;
  final ValueChanged<_Candidate> onPick;
  final bool manualMode;
  final VoidCallback onToggleManual;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.deepNavy.withValues(alpha: 0.45),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'КАНДИДАТЫ ИЗ МЕТОДОВ  //  ${candidates.length}',
                style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 3),
              ),
              const Spacer(),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: onToggleManual,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: manualMode
                          ? AppColors.crimsonError.withValues(alpha: 0.18)
                          : Colors.transparent,
                      border: Border.all(
                        color: manualMode
                            ? AppColors.crimsonError
                            : AppColors.crimsonError.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      manualMode ? 'OVERRIDE: ON' : 'OVERRIDE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.crimsonError,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: candidates.isEmpty
                ? Center(
                    child: Text(
                      'Нет outliers. Возвращайся в ANALYSIS и применяй метод.',
                      style: theme.textTheme.labelMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final c = candidates[i];
                      return _CandidateRow(
                        candidate: c,
                        suspectId: suspectFor(c.evidence),
                        selected: selectedKey == c.evidence.id,
                        disabled: manualMode,
                        onTap: () => onPick(c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CandidateRow extends StatefulWidget {
  const _CandidateRow({
    required this.candidate,
    required this.suspectId,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final _Candidate candidate;
  final String suspectId;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  State<_CandidateRow> createState() => _CandidateRowState();
}

class _CandidateRowState extends State<_CandidateRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = widget.candidate.evidence;
    final color = widget.selected ? AppColors.magenta : AppColors.neonCyan;
    return MouseRegion(
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: Opacity(
          opacity: widget.disabled ? 0.45 : 1,
          child: AnimatedContainer(
            duration: AppMetrics.fast,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? color.withValues(alpha: 0.18)
                  : _hover
                      ? color.withValues(alpha: 0.08)
                      : Colors.transparent,
              border: Border.all(
                color: color.withValues(alpha: widget.selected ? 1 : 0.4),
                width: widget.selected ? 1.4 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      e.id,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.hologramBlue,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'value=${e.value}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '→ ${widget.suspectId}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.violet,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final entry in widget.candidate.methods.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: entry.key.color.withValues(alpha: 0.12),
                          border: Border.all(
                            color: entry.key.color.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          '${entry.key.code}: ${entry.value}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: entry.key.color,
                            letterSpacing: 1.5,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuspectsAndValue extends StatelessWidget {
  const _SuspectsAndValue({
    required this.suspects,
    required this.currentSuspect,
    required this.onPickSuspect,
    required this.valueController,
    required this.allowEditValue,
    required this.onValueChanged,
  });

  final List<SuspectEntity> suspects;
  final String? currentSuspect;
  final ValueChanged<String> onPickSuspect;
  final TextEditingController valueController;
  final bool allowEditValue;
  final VoidCallback onValueChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('ПОДОЗРЕВАЕМЫЙ',
            style:
                theme.textTheme.labelMedium?.copyWith(letterSpacing: 3)),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in suspects)
                  _SuspectChip(
                    codename: s.codename,
                    role: s.role,
                    selected: currentSuspect == s.id,
                    onTap: () => onPickSuspect(s.id),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text('УЛИКА-ЦИФРА',
            style:
                theme.textTheme.labelMedium?.copyWith(letterSpacing: 3)),
        const SizedBox(height: 6),
        _NumericField(
          controller: valueController,
          enabled: allowEditValue,
          onChanged: onValueChanged,
        ),
        const SizedBox(height: 6),
        Text(
          allowEditValue
              ? 'Свободный ввод: подача без обоснования = риск ошибки.'
              : 'Цифра подставлена из метода. Для ручного ввода → OVERRIDE.',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _NoMethodsHint extends StatelessWidget {
  const _NoMethodsHint({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.amberWarning.withValues(alpha: 0.06),
        border: Border.all(
          color: AppColors.amberWarning.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.amberWarning, size: 18),
              const SizedBox(width: 8),
              Text(
                'МЕТОДЫ НЕ ПРИМЕНЕНЫ',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.amberWarning,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Доказательная вкладка пуста: ни одного outlier-кандидата нет. '
            'Можно подать вердикт «вслепую» (введи число вручную справа), '
            'но математической поддержки у такого решения нет.',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SuspectChip extends StatefulWidget {
  const _SuspectChip({
    required this.codename,
    required this.role,
    required this.selected,
    required this.onTap,
  });

  final String codename;
  final String role;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SuspectChip> createState() => _SuspectChipState();
}

class _SuspectChipState extends State<_SuspectChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.selected ? AppColors.magenta : AppColors.neonCyan;
    final active = widget.selected || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMetrics.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? color.withValues(alpha: 0.16)
                : Colors.transparent,
            border: Border.all(
              color: color.withValues(alpha: active ? 1 : 0.4),
              width: widget.selected ? 1.4 : 0.8,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : const [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.codename,
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: color, letterSpacing: 2),
              ),
              const SizedBox(height: 2),
              Text(widget.role, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.panelBg,
        border: Border.all(
          color: enabled
              ? AppColors.neonCyan.withValues(alpha: 0.5)
              : AppColors.textMuted.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.numbers,
            color: enabled ? AppColors.neonCyan : AppColors.textMuted,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,-]')),
              ],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: enabled
                        ? AppColors.neonCyan
                        : AppColors.textPrimary,
                    letterSpacing: 2,
                  ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '0.00',
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}
