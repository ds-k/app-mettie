import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/constants/veterinary_guidelines.dart';
import '../../../../data/models/pet.dart';
import '../../../../data/models/record.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/record_repository.dart';
import '../../../../domain/dosing.dart';
import '../../../../domain/glucose.dart';
import '../../../../domain/timeline.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/labels.dart';
import '../../../view_models/dashboard_view_model.dart';
import '../../../widgets/status_pill.dart';

/// 빠른 기록 시트를 연다. [initialKinds]로 처음 펼칠 종류를 정할 수 있다.
Future<void> showRecordEntrySheet(
  BuildContext context, {
  Set<EntryKind>? initialKinds,
}) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RecordEntryBottomSheet(initialKinds: initialKinds),
  );
}

class RecordEntryBottomSheet extends ConsumerStatefulWidget {
  final Set<EntryKind>? initialKinds;

  const RecordEntryBottomSheet({super.key, this.initialKinds});

  @override
  ConsumerState<RecordEntryBottomSheet> createState() =>
      _RecordEntryBottomSheetState();
}

class _RecordEntryBottomSheetState
    extends ConsumerState<RecordEntryBottomSheet> {
  late Set<EntryKind> _kinds;
  DateTime _recordedAt = DateTime.now();

  final _glucose = TextEditingController();
  String _glucoseType = 'pre_meal';

  final _dose = TextEditingController();
  String _injectionStatus = 'given';
  bool _overrideAcknowledged = false;
  DuplicateDoseException? _serverConflict;

  final _wet = TextEditingController();
  final _dry = TextEditingController();
  String _appetite = 'good';

  final _weight = TextEditingController();

  final Set<String> _observations = {};
  final _notes = TextEditingController();

  bool _saving = false;

  List<TextEditingController> get _controllers => [
    _glucose,
    _dose,
    _wet,
    _dry,
    _weight,
    _notes,
  ];

  @override
  void initState() {
    super.initState();
    final pet = ref.read(currentPetProvider);
    _kinds = {...?widget.initialKinds};
    if (_kinds.isEmpty) {
      _kinds = {pet?.hasDiabetes == true ? EntryKind.glucose : EntryKind.meal};
    }
    if (pet?.insulinUnitIu != null) _dose.text = _fmt(pet!.insulinUnitIu!);
    for (final c in _controllers) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();

  Record? _localConflict(List<Record> records) {
    if (!_kinds.contains(EntryKind.insulin) || _injectionStatus != 'given') {
      return null;
    }
    return findConflictingDose(records, _recordedAt);
  }

  List<Record> _buildRecords(Pet pet, String userId) {
    Record base() => Record(
      id: '',
      petId: pet.id,
      writerId: userId,
      recordedAt: _recordedAt,
      createdAt: DateTime.now(),
    );
    final out = <Record>[];

    if (_kinds.contains(EntryKind.glucose) &&
        int.tryParse(_glucose.text) != null) {
      out.add(
        base().copyWith(
          glucoseValue: int.parse(_glucose.text),
          glucoseType: _glucoseType,
          measurementDevice: pet.glucoseMeter,
        ),
      );
    }
    if (_kinds.contains(EntryKind.insulin)) {
      final dose = double.tryParse(_dose.text);
      if (_injectionStatus == 'skipped' || dose != null) {
        out.add(
          base().copyWith(
            insulinDose: _injectionStatus == 'skipped' ? 0 : dose,
            insulinType: pet.insulinType,
            injectionStatus: _injectionStatus,
            doseOverride: _overrideAcknowledged,
          ),
        );
      }
    }
    if (_kinds.contains(EntryKind.meal)) {
      // 혼합 급여는 사료별로 한 건씩 저장하고 타임라인에서 한 끼로 묶는다
      for (final (type, ctrl, brand) in [
        ('wet', _wet, pet.defaultFoodWet),
        ('dry', _dry, pet.defaultFoodDry),
      ]) {
        final g = double.tryParse(ctrl.text);
        if (g == null) continue;
        out.add(
          base().copyWith(
            foodType: type,
            foodAmountG: g,
            foodBrand: brand,
            appetite: _appetite,
          ),
        );
      }
    }
    if (_kinds.contains(EntryKind.weight) &&
        double.tryParse(_weight.text) != null) {
      out.add(base().copyWith(weightKg: double.parse(_weight.text)));
    }
    if (_kinds.contains(EntryKind.observation) &&
        (_observations.isNotEmpty || _notes.text.trim().isNotEmpty)) {
      // 공통 항목은 기존 칼럼에, 나머지는 symptom_tags에 언어와 무관한 코드로 저장한다
      final tags = _observations.difference({
        'drink_more',
        'urinate_more',
        'poor_appetite',
        'vomit',
      }).toList();
      out.add(
        base().copyWith(
          waterIntake: _observations.contains('drink_more')
              ? 'increased'
              : null,
          urination: _observations.contains('urinate_more') ? 'polyuria' : null,
          appetite: _observations.contains('poor_appetite') ? 'partial' : null,
          vomitCount: _observations.contains('vomit') ? 1 : 0,
          symptomTags: tags,
          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        ),
      );
    }
    return out;
  }

  Future<void> _save(Pet pet) async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;
    final records = _buildRecords(pet, userId);
    if (records.isEmpty) {
      _snack(context.l10n.entryNothingToSave);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(recordRepositoryProvider).createRecords(records);
      if (mounted) Navigator.of(context).pop();
    } on DuplicateDoseException catch (e) {
      // 화면에 아직 반영되지 않은 가족의 투여를 서버가 잡은 경우
      setState(() {
        _serverConflict = e;
        _overrideAcknowledged = false;
      });
    } catch (e) {
      if (mounted) _snack(context.l10n.commonNetworkError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (time == null) return;
    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _serverConflict = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pet = ref.watch(currentPetProvider);
    if (pet == null) return const SizedBox.shrink();
    final records = ref.watch(recordsStreamProvider).value ?? const <Record>[];
    final userId = ref.watch(currentUserProvider)?.id ?? '';
    final localConflict = _localConflict(records);
    final hasConflict =
        _injectionStatus == 'given' &&
        (localConflict != null || _serverConflict != null);
    final count = _buildRecords(pet, userId).length;
    final blocked = hasConflict && !_overrideAcknowledged;

    final l = context.l10n;
    final kinds = [
      (EntryKind.glucose, l.kindGlucose, LucideIcons.droplet),
      if (pet.hasDiabetes)
        (EntryKind.insulin, l.kindInsulin, LucideIcons.syringe),
      (EntryKind.meal, l.kindMeal, LucideIcons.utensils),
      (EntryKind.weight, l.kindWeight, LucideIcons.scale),
      (EntryKind.observation, l.kindObservation, LucideIcons.eye),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
              child: Row(
                children: [
                  Text(
                    l.entryTitle(pet.name),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: kInk,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: l.commonClose,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: kSlate),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (kind, label, icon) in kinds)
                        FilterChip(
                          avatar: Icon(
                            icon,
                            size: 16,
                            color: _kinds.contains(kind) ? kOnDark : kCharcoal,
                          ),
                          label: Text(label),
                          selected: _kinds.contains(kind),
                          showCheckmark: false,
                          selectedColor: kInk,
                          backgroundColor: kCanvas,
                          labelStyle: TextStyle(
                            color: _kinds.contains(kind) ? kOnDark : kCharcoal,
                            fontWeight: FontWeight.w600,
                          ),
                          side: const BorderSide(color: kHairline),
                          shape: const StadiumBorder(),
                          onSelected: (on) => setState(() {
                            on ? _kinds.add(kind) : _kinds.remove(kind);
                            _serverConflict = null;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _Tile(
                    child: InkWell(
                      onTap: _pickTime,
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 18,
                            color: kSlate,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            DateFormat.MMMd(
                              l.localeName,
                            ).add_Hm().format(_recordedAt),
                            style: const TextStyle(
                              fontSize: 15,
                              color: kInk,
                              fontFeatures: kTabularFigures,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            l.entryChangeTime,
                            style: const TextStyle(
                              color: kBrandBlueDeep,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_kinds.contains(EntryKind.glucose)) _glucoseSection(pet),
                  if (_kinds.contains(EntryKind.insulin))
                    _insulinSection(pet, localConflict),
                  if (_kinds.contains(EntryKind.meal)) _mealSection(pet),
                  if (_kinds.contains(EntryKind.weight)) _weightSection(),
                  if (_kinds.contains(EntryKind.observation))
                    _observationSection(pet),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _saving || count == 0 || blocked
                        ? null
                        : () => _save(pet),
                    style: FilledButton.styleFrom(
                      backgroundColor: kBrandBlue,
                      shape: const StadiumBorder(),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: kOnDark,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            count <= 1
                                ? l.commonSave
                                : l.commonSaveCount(count),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 섹션 ───────────────────────────────────────────────────────────────────

  Widget _glucoseSection(Pet pet) {
    final v = int.tryParse(_glucose.text);
    final status = v == null ? null : GlucoseRange.forPet(pet).classify(v);
    final l = context.l10n;
    return _Section(
      title: l.kindGlucose,
      trailing: status == null ? null : StatusPill.glucose(status, l),
      children: [
        _NumberField(
          controller: _glucose,
          label: l.entryGlucoseField,
          unit: 'mg/dL',
          decimals: 0,
          maxLength: 3,
        ),
        const SizedBox(height: 10),
        _ChoiceRow(
          options: {for (final t in kGlucoseTypes) t: glucoseTypeLabel(l, t)!},
          value: _glucoseType,
          onChanged: (v) => setState(() => _glucoseType = v),
        ),
      ],
    );
  }

  Widget _insulinSection(Pet pet, Record? localConflict) {
    final concentration =
        pet.insulinConcentration ??
        VeterinaryGuidelines.concentrationOf(pet.insulinType);
    final syringe = pet.syringeType;
    final mismatch =
        concentration != null &&
        syringe != null &&
        syringe != 'pen' &&
        syringe != concentration;
    final l = context.l10n;

    return _Section(
      title: l.kindInsulin,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              pet.insulinType == null
                  ? l.entryInsulinUnset
                  : insulinDisplayName(l, pet.insulinType!),
              style: const TextStyle(fontWeight: FontWeight.w600, color: kInk),
            ),
            if (concentration != null)
              StatusPill(label: l.entryInsulinConcentration(concentration)),
            if (syringe != null)
              StatusPill(
                label: syringe == 'pen' ? l.entryPen : l.entrySyringe(syringe),
              ),
          ],
        ),
        if (mismatch) ...[
          const SizedBox(height: 8),
          _WarnBox(
            title: l.entryMismatchTitle,
            body: l.entryMismatchBody(concentration, syringe),
            color: kStatusError,
            background: kStatusErrorSoft,
          ),
        ],
        const SizedBox(height: 10),
        _ChoiceRow(
          options: {
            for (final c in const ['given', 'partial', 'skipped'])
              c: injectionStatusLabel(l, c),
          },
          value: _injectionStatus,
          onChanged: (v) => setState(() {
            _injectionStatus = v;
            _serverConflict = null;
          }),
        ),
        if (_injectionStatus != 'skipped') ...[
          const SizedBox(height: 10),
          _NumberField(
            controller: _dose,
            label: l.entryDoseField,
            unit: 'IU',
            decimals: 2,
            maxLength: 5,
          ),
        ],
        if (_injectionStatus == 'given' &&
            (localConflict != null || _serverConflict != null)) ...[
          const SizedBox(height: 10),
          _DuplicateWarning(
            local: localConflict,
            server: _serverConflict,
            acknowledged: _overrideAcknowledged,
            onAcknowledge: (v) => setState(() => _overrideAcknowledged = v),
          ),
        ],
      ],
    );
  }

  Widget _mealSection(Pet pet) {
    final l = context.l10n;
    return _Section(
      title: l.kindMeal,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _NumberField(
                controller: _wet,
                label: l.foodWet,
                unit: 'g',
                decimals: 1,
                maxLength: 5,
                hint: pet.defaultFoodWet,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumberField(
                controller: _dry,
                label: l.foodDry,
                unit: 'g',
                decimals: 1,
                maxLength: 5,
                hint: pet.defaultFoodDry,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ChoiceRow(
          options: {
            for (final c in const ['good', 'partial', 'anorexic'])
              c: appetiteLabel(l, c),
          },
          value: _appetite,
          onChanged: (v) => setState(() => _appetite = v),
        ),
      ],
    );
  }

  Widget _weightSection() {
    final l = context.l10n;
    return _Section(
      title: l.kindWeight,
      children: [
        _NumberField(
          controller: _weight,
          label: l.kindWeight,
          unit: 'kg',
          decimals: 2,
          maxLength: 5,
        ),
      ],
    );
  }

  Widget _observationSection(Pet pet) {
    final options = [
      ...kCommonObservations,
      ...(pet.isCat ? kCatObservations : kDogObservations),
    ];
    final l = context.l10n;
    return _Section(
      title: l.kindObservation,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(observationLabel(l, o)),
                selected: _observations.contains(o),
                showCheckmark: false,
                selectedColor: kBrandBlueSoft,
                backgroundColor: kCanvas,
                side: BorderSide(
                  color: _observations.contains(o) ? kBrandBlue : kHairline,
                ),
                labelStyle: TextStyle(
                  color: _observations.contains(o) ? kBrandBlueDeep : kCharcoal,
                  fontSize: 13,
                ),
                shape: const StadiumBorder(),
                onSelected: (on) => setState(
                  () => on ? _observations.add(o) : _observations.remove(o),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notes,
          maxLines: 3,
          decoration: _inputDecoration(l.entryNotes),
        ),
      ],
    );
  }
}

// ─── 작은 위젯 ─────────────────────────────────────────────────────────────────

InputDecoration _inputDecoration(
  String label, {
  String? suffix,
  String? hint,
}) => InputDecoration(
  labelText: label,
  suffixText: suffix,
  helperText: hint,
  helperMaxLines: 1,
  filled: true,
  fillColor: kCanvas,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusLg),
    borderSide: const BorderSide(color: kHairline),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusLg),
    borderSide: const BorderSide(color: kHairline),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(kRadiusLg),
    borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);

class _Tile extends StatelessWidget {
  final Widget child;
  const _Tile({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: kCanvas,
      borderRadius: BorderRadius.circular(kRadiusLg),
      border: Border.all(color: kHairline),
    ),
    child: child,
  );
}

class _Section extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;
  const _Section({required this.title, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kCharcoal,
              ),
            ),
            const Spacer(),
            ?trailing,
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String unit;
  final int decimals;
  final int maxLength;
  final String? hint;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.unit,
    required this.decimals,
    required this.maxLength,
    this.hint,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(decimals > 0 ? '^\\d+\\.?\\d{0,$decimals}' : r'^\d+'),
      ),
      LengthLimitingTextInputFormatter(maxLength),
    ],
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      fontFeatures: kTabularFigures,
    ),
    decoration: _inputDecoration(label, suffix: unit, hint: hint),
  );
}

class _ChoiceRow extends StatelessWidget {
  final Map<String, String> options;
  final String value;
  final ValueChanged<String> onChanged;
  const _ChoiceRow({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final e in options.entries)
        ChoiceChip(
          label: Text(e.value),
          selected: value == e.key,
          showCheckmark: false,
          selectedColor: kBrandBlueSoft,
          backgroundColor: kCanvas,
          side: BorderSide(color: value == e.key ? kBrandBlue : kHairline),
          labelStyle: TextStyle(
            color: value == e.key ? kBrandBlueDeep : kCharcoal,
            fontWeight: value == e.key ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
          shape: const StadiumBorder(),
          onSelected: (_) => onChanged(e.key),
        ),
    ],
  );
}

class _WarnBox extends StatelessWidget {
  final String title;
  final String body;
  final Color color;
  final Color background;
  final Widget? footer;

  const _WarnBox({
    required this.title,
    required this.body,
    this.color = kStatusWarn,
    this.background = kStatusWarnSoft,
    this.footer,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(kRadiusLg),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.triangleAlert, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(color: kCharcoal, fontSize: 13, height: 1.5),
        ),
        ?footer,
      ],
    ),
  );
}

class _DuplicateWarning extends ConsumerWidget {
  final Record? local;
  final DuplicateDoseException? server;
  final bool acknowledged;
  final ValueChanged<bool> onAcknowledge;

  const _DuplicateWarning({
    required this.local,
    required this.server,
    required this.acknowledged,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final writer = local != null
        ? ref.watch(writerNameProvider(local!.writerId))
        : WriterName(isMe: false, name: server!.writerName);
    final at = local?.recordedAt ?? server!.recordedAt;
    final dose = local?.insulinDose ?? server?.insulinDose;

    return _WarnBox(
      title: l.dupTitle,
      body: l.dupBody(
        writer.subject(l),
        DateFormat('HH:mm').format(at),
        (dose ?? 0).toStringAsFixed(1),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: InkWell(
          onTap: () => onAcknowledge(!acknowledged),
          child: Row(
            children: [
              Checkbox(
                value: acknowledged,
                onChanged: (v) => onAcknowledge(v ?? false),
                activeColor: kStatusWarn,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              Expanded(
                child: Text(
                  l.dupAcknowledge,
                  style: TextStyle(
                    color: kCharcoal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
