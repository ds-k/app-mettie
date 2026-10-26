import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/constants/veterinary_guidelines.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
import '../../view_models/pet_management_view_model.dart';

/// 당뇨 관리 계획 편집 시트. 투여 시각과 인슐린·주사기 정보는 홈, 중복 투여 판정, 알림이 모두 쓴다.
Future<void> showCarePlanSheet(BuildContext context, Pet pet) {
  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CarePlanSheet(pet: pet),
  );
}

class CarePlanSheet extends ConsumerStatefulWidget {
  final Pet pet;
  const CarePlanSheet({super.key, required this.pet});

  @override
  ConsumerState<CarePlanSheet> createState() => _CarePlanSheetState();
}

class _CarePlanSheetState extends ConsumerState<CarePlanSheet> {
  late String? _insulinType;
  late final TextEditingController _customInsulin;
  late final TextEditingController _dose;
  late String? _concentration;
  late String? _syringe;
  late List<String> _times;
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _hypo;
  late final TextEditingController _meter;
  late final TextEditingController _wet;
  late final TextEditingController _dry;
  late final TextEditingController _vet;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.pet;
    final known = VeterinaryGuidelines.insulinTypes.contains(p.insulinType);
    _insulinType = p.insulinType == null
        ? null
        : (known ? p.insulinType : '기타');
    _customInsulin = TextEditingController(
      text: known ? '' : (p.insulinType ?? ''),
    );
    _dose = TextEditingController(text: p.insulinUnitIu?.toString() ?? '');
    _concentration =
        p.insulinConcentration ??
        VeterinaryGuidelines.concentrationOf(p.insulinType);
    _syringe = p.syringeType;
    _times = [...p.dosingTimes];
    _min = TextEditingController(text: (p.targetGlucoseMin ?? 100).toString());
    _max = TextEditingController(
      text: (p.targetGlucoseMax ?? (p.isCat ? 300 : 250)).toString(),
    );
    _hypo = TextEditingController(text: p.hypoThreshold.toString());
    _meter = TextEditingController(text: p.glucoseMeter ?? '');
    _wet = TextEditingController(text: p.defaultFoodWet ?? '');
    _dry = TextEditingController(text: p.defaultFoodDry ?? '');
    _vet = TextEditingController(text: p.vetClinic ?? '');
  }

  @override
  void dispose() {
    for (final c in [
      _customInsulin,
      _dose,
      _min,
      _max,
      _hypo,
      _meter,
      _wet,
      _dry,
      _vet,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
    );
    if (picked == null) return;
    final t =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _times = ({..._times, t}.toList()..sort()));
  }

  Future<void> _save() async {
    final min = int.tryParse(_min.text),
        max = int.tryParse(_max.text),
        hypo = int.tryParse(_hypo.text);
    if (min == null || max == null || min >= max) {
      _snack(context.l10n.planErrRange);
      return;
    }
    if (hypo == null || hypo < 40 || hypo > 150) {
      _snack(context.l10n.planErrHypo);
      return;
    }
    setState(() => _saving = true);
    final insulin = _insulinType == '기타' ? _text(_customInsulin) : _insulinType;
    final updated = widget.pet.copyWith(
      conditions: {...widget.pet.conditions, 'diabetes'}.toList(),
      insulinType: insulin,
      insulinUnitIu: double.tryParse(_dose.text),
      insulinConcentration: _concentration,
      syringeType: _syringe,
      dosingTimes: _times,
      targetGlucoseMin: min,
      targetGlucoseMax: max,
      hypoThreshold: hypo,
      glucoseMeter: _text(_meter),
      defaultFoodWet: _text(_wet),
      defaultFoodDry: _text(_dry),
      vetClinic: _text(_vet),
    );
    try {
      await ref.read(petRepositoryProvider).updatePet(updated);
      ref.invalidate(petsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _snack(context.l10n.planErrSave);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final mismatch =
        _concentration != null &&
        _syringe != null &&
        _syringe != 'pen' &&
        _syringe != _concentration;
    final l = context.l10n;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Text(
                    l.planSheetTitle(widget.pet.name),
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
                  8,
                  20,
                  24 + MediaQuery.of(context).viewInsets.bottom,
                ),
                children: [
                  _title(l.planDosingTimes),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in _times)
                        InputChip(
                          label: Text(
                            t,
                            style: const TextStyle(
                              fontFeatures: kTabularFigures,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onDeleted: () => setState(() => _times.remove(t)),
                          backgroundColor: kCanvas,
                          side: const BorderSide(color: kHairline),
                        ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.plus, size: 16),
                        label: Text(l.planAddTime),
                        onPressed: _addTime,
                        backgroundColor: kCanvas,
                        side: const BorderSide(color: kHairline),
                      ),
                      if (_times.isEmpty)
                        ActionChip(
                          label: Text(l.planTwiceDaily),
                          onPressed: () =>
                              setState(() => _times = ['07:00', '19:00']),
                          backgroundColor: kBrandBlueSoft,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  _title(l.planInsulin),
                  DropdownButtonFormField<String>(
                    initialValue: _insulinType,
                    decoration: _decoration(l.planInsulinType),
                    items: [
                      for (final t in VeterinaryGuidelines.insulinTypes)
                        DropdownMenuItem(
                          value: t,
                          child: Text(insulinDisplayName(l, t)),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _insulinType = v;
                      _concentration =
                          VeterinaryGuidelines.concentrationOf(v) ??
                          _concentration;
                    }),
                  ),
                  if (_insulinType == '기타') ...[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customInsulin,
                      decoration: _decoration(l.planInsulinName),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dose,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    decoration: _decoration(l.planDosePerShot, suffix: 'IU'),
                  ),
                  const SizedBox(height: 12),
                  _chips(
                    l.planConcentration,
                    const {'U-40': 'U-40', 'U-100': 'U-100', 'U-300': 'U-300'},
                    _concentration,
                    (v) => setState(() => _concentration = v),
                  ),
                  const SizedBox(height: 8),
                  _chips(
                    l.planSyringe,
                    {
                      'U-40': l.entrySyringe('U-40'),
                      'U-100': l.entrySyringe('U-100'),
                      'pen': l.entryPen,
                    },
                    _syringe,
                    (v) => setState(() => _syringe = v),
                  ),
                  if (mismatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l.planMismatch(_concentration!, _syringe!),
                        style: const TextStyle(
                          color: kStatusError,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _title(l.planTarget),
                  Row(
                    children: [
                      Expanded(child: _numberField(_min, l.planLower, 'mg/dL')),
                      const SizedBox(width: 10),
                      Expanded(child: _numberField(_max, l.planUpper, 'mg/dL')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _numberField(
                          _hypo,
                          l.planHypoThreshold,
                          'mg/dL',
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      l.planTargetHint,
                      style: const TextStyle(color: kSlate, fontSize: 12),
                    ),
                  ),
                  _title(l.planMeterFoodVet),
                  TextField(
                    controller: _meter,
                    decoration: _decoration(l.planMeterHint),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _wet,
                    decoration: _decoration(l.planDefaultWet),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dry,
                    decoration: _decoration(l.planDefaultDry),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _vet,
                    decoration: _decoration(l.planVetClinic),
                  ),
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
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: kBrandBlue,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      l.commonSave,
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

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: kCharcoal,
      ),
    ),
  );

  Widget _chips(
    String label,
    Map<String, String> options,
    String? value,
    ValueChanged<String?> onChanged,
  ) => Row(
    children: [
      SizedBox(
        width: 76,
        child: Text(label, style: const TextStyle(color: kSlate, fontSize: 13)),
      ),
      Expanded(
        child: Wrap(
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
                side: BorderSide(
                  color: value == e.key ? kBrandBlue : kHairline,
                ),
                labelStyle: TextStyle(
                  color: value == e.key ? kBrandBlueDeep : kCharcoal,
                  fontSize: 13,
                ),
                shape: const StadiumBorder(),
                onSelected: (on) => onChanged(on ? e.key : null),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _numberField(TextEditingController c, String label, String suffix) =>
      TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        style: const TextStyle(
          fontFeatures: kTabularFigures,
          fontWeight: FontWeight.w600,
        ),
        decoration: _decoration(label, suffix: suffix),
      );

  InputDecoration _decoration(String label, {String? suffix}) =>
      InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: kCanvas,
        isDense: true,
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
      );
}
