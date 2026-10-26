import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/constants/veterinary_guidelines.dart';
import '../../../data/models/pet.dart';
import '../../../data/models/record.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
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
    final l = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PetAppBar(
        subtitle: pet == null ? null : l.navBook,
        title: pet == null ? l.navBook : null,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
        children: [
          if (pet != null) ...[
            _ProfileCard(pet: pet, records: records),
            const SizedBox(height: 12),
            if (pet.hasDiabetes)
              _DiabetesPlanCard(pet: pet)
            else
              _StartConditionCard(pet: pet),
            const SizedBox(height: 12),
          ],
          _LinkCard(
            icon: LucideIcons.pawPrint,
            title: pet == null ? l.bookAddPet : l.bookManagePets,
            subtitle: pet == null ? l.bookAddPetHint : l.bookManagePetsHint,
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
    final latestWeight =
        records.where((r) => r.weightKg != null).firstOrNull?.weightKg ??
        pet.weightKg;
    final l = context.l10n;
    final age = pet.dateOfBirth == null
        ? null
        : DateTime.now().difference(pet.dateOfBirth!).inDays ~/ 365;
    final sex = switch (pet.sex) {
      'male' => pet.isNeutered ? l.sexMaleNeutered : l.sexMale,
      'female' => pet.isNeutered ? l.sexFemaleSpayed : l.sexFemale,
      _ => null,
    };
    final facts = [
      pet.breed ?? (pet.isCat ? l.speciesCat : l.speciesDog),
      ?sex,
      if (age != null) l.ageYears(age),
      if (latestWeight != null) '${latestWeight.toStringAsFixed(2)} kg',
    ];

    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: kBrandBlueSoft,
            backgroundImage: pet.avatarUrl?.isNotEmpty == true
                ? NetworkImage(pet.avatarUrl!)
                : null,
            child: pet.avatarUrl?.isNotEmpty == true
                ? null
                : Icon(
                    pet.isCat ? LucideIcons.cat : LucideIcons.dog,
                    color: kBrandBlueDeep,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  facts.join(' · '),
                  style: const TextStyle(color: kSlate, fontSize: 13),
                ),
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
    final l = context.l10n;
    final concentration =
        pet.insulinConcentration ??
        VeterinaryGuidelines.concentrationOf(pet.insulinType);
    final syringe = switch (pet.syringeType) {
      'pen' => l.entryPen,
      null => null,
      final s => l.entrySyringe(s),
    };
    final diagnosed = pet.diagnosedAt == null
        ? null
        : l.diagnosedOn(DateFormat.yMd(l.localeName).format(pet.diagnosedAt!));

    final rows = <(String, String, bool)>[
      (
        l.planInsulin,
        [
          pet.insulinType == null
              ? l.commonUnset
              : insulinDisplayName(l, pet.insulinType!),
          ?concentration,
        ].join(' · '),
        pet.insulinType == null,
      ),
      (
        l.planDoseTimes,
        [
          if (pet.insulinUnitIu != null) '${pet.insulinUnitIu} IU',
          pet.dosingTimes.isEmpty
              ? l.planTimesUnset
              : pet.dosingTimes.join(' / '),
        ].join(' · '),
        pet.dosingTimes.isEmpty,
      ),
      (l.planSyringe, syringe ?? l.commonUnset, syringe == null),
      (
        l.planTarget,
        l.planTargetValue(
          pet.targetGlucoseMin ?? 100,
          pet.targetGlucoseMax ?? (pet.isCat ? 300 : 250),
          pet.hypoThreshold,
        ),
        false,
      ),
      if (pet.glucoseMeter != null) (l.planMeter, pet.glucoseMeter!, false),
      if (pet.defaultFoodWet != null || pet.defaultFoodDry != null)
        (
          l.planFood,
          [?pet.defaultFoodWet, ?pet.defaultFoodDry].join(' · '),
          false,
        ),
      if (pet.vetClinic?.isNotEmpty ?? false)
        (l.planVet, pet.vetClinic!, false),
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l.planTitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kInk,
                ),
              ),
              const SizedBox(width: 8),
              if (diagnosed != null)
                Text(
                  diagnosed,
                  style: const TextStyle(color: kSlate, fontSize: 12),
                ),
              const Spacer(),
              TextButton(
                onPressed: () => showCarePlanSheet(context, pet),
                child: Text(l.commonEdit),
              ),
            ],
          ),
          for (final (label, value, missing) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(
                      label,
                      style: const TextStyle(color: kSlate, fontSize: 13),
                    ),
                  ),
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
          Text(
            context.l10n.conditionTitle,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kInk,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.conditionBody(pet.name),
            style: const TextStyle(color: kCharcoal, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => showCarePlanSheet(context, pet),
            icon: const Icon(LucideIcons.plus, size: 16),
            label: Text(context.l10n.conditionStartDiabetes),
            style: OutlinedButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: kBrandBlueDeep,
            ),
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
  const _LinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

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
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kInk,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: kSlate, fontSize: 12),
                    ),
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
