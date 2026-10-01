import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/constants/veterinary_guidelines.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/record.dart';
import '../../view_models/dashboard_view_model.dart';
import '../../widgets/pet_app_bar.dart';
import '../profile/widgets/profile_family_management.dart';
import 'care_plan_sheet.dart';

/// 건강수첩: 펫 프로필, 질환 모듈별 관리 계획, 가족, 반려동물 관리.
/// 건강 기능을 넓힐 때는 새 탭 대신 이 화면에 카드를 추가한다.
class BookView extends ConsumerWidget {
  const BookView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(currentPetProvider);
    final records = ref.watch(recordsStreamProvider).value ?? const <Record>[];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PetAppBar(subtitle: pet == null ? null : '건강수첩', title: pet == null ? '건강수첩' : null),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          if (pet != null) ...[
            _ProfileCard(pet: pet, records: records),
            const SizedBox(height: 12),
            if (pet.hasDiabetes) _DiabetesPlanCard(pet: pet) else _StartConditionCard(pet: pet),
            const SizedBox(height: 12),
          ],
          _LinkCard(
            icon: LucideIcons.pawPrint,
            title: pet == null ? '반려동물 등록하기' : '반려동물 관리',
            subtitle: pet == null ? '강아지, 고양이 모두 등록할 수 있어요' : '등록 · 정보 수정 · 삭제 · 초대 코드',
            onTap: () => context.push('/home/book/pets'),
          ),
          const SizedBox(height: 24),
          const ProfileFamilyManagement(),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCanvas,
          borderRadius: BorderRadius.circular(kRadiusXl),
          border: Border.all(color: kHairline),
        ),
        child: child,
      );
}

class _ProfileCard extends StatelessWidget {
  final Pet pet;
  final List<Record> records;
  const _ProfileCard({required this.pet, required this.records});

  @override
  Widget build(BuildContext context) {
    final latestWeight = records.where((r) => r.weightKg != null).firstOrNull?.weightKg ?? pet.weightKg;
    final age = pet.dateOfBirth == null ? null : DateTime.now().difference(pet.dateOfBirth!).inDays ~/ 365;
    final sex = switch (pet.sex) {
      'male' => pet.isNeutered ? '수컷(중성화)' : '수컷',
      'female' => pet.isNeutered ? '암컷(중성화)' : '암컷',
      _ => null,
    };
    final facts = [
      pet.breed ?? (pet.isCat ? '고양이' : '강아지'),
      ?sex,
      if (age != null) '$age살',
      if (latestWeight != null) '${latestWeight.toStringAsFixed(2)} kg',
    ];

    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: kBrandBlueSoft,
            backgroundImage: pet.avatarUrl?.isNotEmpty == true ? NetworkImage(pet.avatarUrl!) : null,
            child: pet.avatarUrl?.isNotEmpty == true
                ? null
                : Icon(pet.isCat ? LucideIcons.cat : LucideIcons.dog, color: kBrandBlueDeep),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pet.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kInk)),
                const SizedBox(height: 2),
                Text(facts.join(' · '), style: const TextStyle(color: kSlate, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DiabetesPlanCard extends StatelessWidget {
  final Pet pet;
  const _DiabetesPlanCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final concentration = pet.insulinConcentration ?? VeterinaryGuidelines.concentrationOf(pet.insulinType);
    final syringe = switch (pet.syringeType) {
      'pen' => '펜',
      null => null,
      final s => '$s 주사기',
    };
    final diagnosed = pet.diagnosedAt == null
        ? null
        : '${pet.diagnosedAt!.year}.${pet.diagnosedAt!.month}.${pet.diagnosedAt!.day} 진단';

    final rows = <(String, String, bool)>[
      (
        '인슐린',
        [pet.insulinType?.split('(').first ?? '미설정', ?concentration].join(' · '),
        pet.insulinType == null,
      ),
      (
        '용량 · 시각',
        [
          if (pet.insulinUnitIu != null) '${pet.insulinUnitIu} IU',
          pet.dosingTimes.isEmpty ? '투여 시각 미설정' : pet.dosingTimes.join(' / '),
        ].join(' · '),
        pet.dosingTimes.isEmpty,
      ),
      ('주사기', syringe ?? '미설정', syringe == null),
      ('목표 혈당', '${pet.targetGlucoseMin ?? 100} – ${pet.targetGlucoseMax ?? (pet.isCat ? 300 : 250)} · 저혈당 ${pet.hypoThreshold} 미만', false),
      if (pet.glucoseMeter != null) ('측정기', pet.glucoseMeter!, false),
      if (pet.defaultFoodWet != null || pet.defaultFoodDry != null)
        ('사료', [?pet.defaultFoodWet, ?pet.defaultFoodDry].join(' · '), false),
      if (pet.vetClinic?.isNotEmpty ?? false) ('병원', pet.vetClinic!, false),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('당뇨 관리 계획', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(width: 8),
            if (diagnosed != null) Text(diagnosed, style: const TextStyle(color: kSlate, fontSize: 12)),
            const Spacer(),
            TextButton(onPressed: () => showCarePlanSheet(context, pet), child: const Text('수정')),
          ]),
          for (final (label, value, missing) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 84, child: Text(label, style: const TextStyle(color: kSlate, fontSize: 13))),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: missing ? kStatusWarn : kInk,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: kTabularFigures,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StartConditionCard extends StatelessWidget {
  final Pet pet;
  const _StartConditionCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('질환 관리', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 6),
          Text(
            '${pet.name}이(가) 당뇨 진단을 받았다면 관리 계획을 만들어 투여 시간, 혈당 목표, 가족 간 중복 투여 방지를 시작할 수 있어요.',
            style: const TextStyle(color: kCharcoal, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showCarePlanSheet(context, pet),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('당뇨 관리 시작'),
            style: OutlinedButton.styleFrom(shape: const StadiumBorder(), foregroundColor: kBrandBlueDeep),
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _LinkCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCanvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusXl),
        side: const BorderSide(color: kHairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusXl),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: kCharcoal, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: kInk, fontSize: 15)),
                    Text(subtitle, style: const TextStyle(color: kSlate, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: kStone, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
