import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/constants/veterinary_guidelines.dart';
import '../../../data/models/pet.dart';
import '../../../data/repositories/pet_repository.dart';
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
    _insulinType = p.insulinType == null ? null : (known ? p.insulinType : '기타');
    _customInsulin = TextEditingController(text: known ? '' : (p.insulinType ?? ''));
    _dose = TextEditingController(text: p.insulinUnitIu?.toString() ?? '');
    _concentration = p.insulinConcentration ?? VeterinaryGuidelines.concentrationOf(p.insulinType);
    _syringe = p.syringeType;
    _times = [...p.dosingTimes];
    _min = TextEditingController(text: (p.targetGlucoseMin ?? 100).toString());
    _max = TextEditingController(text: (p.targetGlucoseMax ?? (p.isCat ? 300 : 250)).toString());
    _hypo = TextEditingController(text: p.hypoThreshold.toString());
    _meter = TextEditingController(text: p.glucoseMeter ?? '');
    _wet = TextEditingController(text: p.defaultFoodWet ?? '');
    _dry = TextEditingController(text: p.defaultFoodDry ?? '');
    _vet = TextEditingController(text: p.vetClinic ?? '');
  }

  @override
  void dispose() {
    for (final c in [_customInsulin, _dose, _min, _max, _hypo, _meter, _wet, _dry, _vet]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _addTime() async {
    final picked = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (picked == null) return;
    final t = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => _times = ({..._times, t}.toList()..sort()));
  }

  Future<void> _save() async {
    final min = int.tryParse(_min.text), max = int.tryParse(_max.text), hypo = int.tryParse(_hypo.text);
    if (min == null || max == null || min >= max) {
      _snack('목표 범위를 확인해 주세요. 하한이 상한보다 작아야 해요.');
      return;
    }
    if (hypo == null || hypo < 40 || hypo > 150) {
      _snack('저혈당 기준은 40–150 사이로 입력해 주세요.');
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
      _snack('저장하지 못했어요. 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final mismatch = _concentration != null && _syringe != null && _syringe != 'pen' && _syringe != _concentration;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Container(
        decoration: const BoxDecoration(color: kSurface, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(children: [
                Text('${widget.pet.name} 당뇨 관리 계획',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
                const Spacer(),
                IconButton(tooltip: '닫기', onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x, color: kSlate)),
              ]),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
                children: [
                  _title('투여 시각'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in _times)
                        InputChip(
                          label: Text(t, style: const TextStyle(fontFeatures: kTabularFigures, fontWeight: FontWeight.w600)),
                          onDeleted: () => setState(() => _times.remove(t)),
                          backgroundColor: kCanvas,
                          side: const BorderSide(color: kHairline),
                        ),
                      ActionChip(
                        avatar: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('시각 추가'),
                        onPressed: _addTime,
                        backgroundColor: kCanvas,
                        side: const BorderSide(color: kHairline),
                      ),
                      if (_times.isEmpty)
                        ActionChip(
                          label: const Text('07:00 · 19:00 (하루 2회)'),
                          onPressed: () => setState(() => _times = ['07:00', '19:00']),
                          backgroundColor: kBrandBlueSoft,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                  _title('인슐린'),
                  DropdownButtonFormField<String>(
                    initialValue: _insulinType,
                    decoration: _decoration('종류'),
                    items: [
                      for (final t in VeterinaryGuidelines.insulinTypes) DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) => setState(() {
                      _insulinType = v;
                      _concentration = VeterinaryGuidelines.concentrationOf(v) ?? _concentration;
                    }),
                  ),
                  if (_insulinType == '기타') ...[
                    const SizedBox(height: 10),
                    TextField(controller: _customInsulin, decoration: _decoration('인슐린 이름')),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dose,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    decoration: _decoration('1회 용량', suffix: 'IU'),
                  ),
                  const SizedBox(height: 12),
                  _chips('인슐린 농도', const {'U-40': 'U-40', 'U-100': 'U-100', 'U-300': 'U-300'}, _concentration,
                      (v) => setState(() => _concentration = v)),
                  const SizedBox(height: 8),
                  _chips('주사기', const {'U-40': 'U-40 주사기', 'U-100': 'U-100 주사기', 'pen': '펜'}, _syringe,
                      (v) => setState(() => _syringe = v)),
                  if (mismatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '인슐린($_concentration)과 주사기($_syringe) 눈금이 달라요. 눈금대로 넣으면 실제 용량이 크게 달라집니다.',
                        style: const TextStyle(color: kStatusError, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  _title('목표 혈당'),
                  Row(children: [
                    Expanded(child: _numberField(_min, '하한', 'mg/dL')),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField(_max, '상한', 'mg/dL')),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField(_hypo, '저혈당 기준', 'mg/dL')),
                  ]),
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('수의사가 정해 준 범위를 넣어 주세요. 기본값은 강아지 100–250, 고양이 100–300입니다.',
                        style: TextStyle(color: kSlate, fontSize: 12)),
                  ),
                  _title('측정기 · 사료 · 병원'),
                  TextField(controller: _meter, decoration: _decoration('혈당 측정기 (예: 알파트랙 3)')),
                  const SizedBox(height: 10),
                  TextField(controller: _wet, decoration: _decoration('기본 습식 사료')),
                  const SizedBox(height: 10),
                  TextField(controller: _dry, decoration: _decoration('기본 건식 사료')),
                  const SizedBox(height: 10),
                  TextField(controller: _vet, decoration: _decoration('다니는 병원')),
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
                    style: FilledButton.styleFrom(backgroundColor: kBrandBlue, shape: const StadiumBorder()),
                    child: const Text('저장', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kCharcoal)),
      );

  Widget _chips(String label, Map<String, String> options, String? value, ValueChanged<String?> onChanged) => Row(
        children: [
          SizedBox(width: 76, child: Text(label, style: const TextStyle(color: kSlate, fontSize: 13))),
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (final e in options.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: value == e.key,
                  showCheckmark: false,
                  selectedColor: kBrandBlueSoft,
                  backgroundColor: kCanvas,
                  side: BorderSide(color: value == e.key ? kBrandBlue : kHairline),
                  labelStyle: TextStyle(color: value == e.key ? kBrandBlueDeep : kCharcoal, fontSize: 13),
                  shape: const StadiumBorder(),
                  onSelected: (on) => onChanged(on ? e.key : null),
                ),
            ]),
          ),
        ],
      );

  Widget _numberField(TextEditingController c, String label, String suffix) => TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
        style: const TextStyle(fontFeatures: kTabularFigures, fontWeight: FontWeight.w600),
        decoration: _decoration(label, suffix: suffix),
      );

  InputDecoration _decoration(String label, {String? suffix}) => InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: kCanvas,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusLg), borderSide: const BorderSide(color: kHairline)),
        enabledBorder:
            OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusLg), borderSide: const BorderSide(color: kHairline)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusLg), borderSide: const BorderSide(color: kBrandBlue, width: 1.5)),
      );
}
