import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/constants/app_colors.dart';
import '../view_models/dashboard_view_model.dart';
import '../views/dashboard/widgets/pet_selector_bottom_sheet.dart';

/// 탭 공통 상단바: 선택된 펫 이름(눌러서 전환)과 설정 톱니.
class PetAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;

  const PetAppBar({super.key, this.title, this.subtitle});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(currentPetProvider);
    return AppBar(
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Semantics(
        button: pet != null,
        label: pet == null ? null : '반려동물 바꾸기',
        child: GestureDetector(
          onTap: pet == null
              ? null
              : () => showModalBottomSheet(
                  context: context,
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const PetSelectorBottomSheet(),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title ?? pet?.name ?? '메티',
                    style: const TextStyle(
                      color: kInk,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (title == null && pet != null) ...[
                    const SizedBox(width: 2),
                    const Icon(LucideIcons.chevronDown, color: kInk, size: 18),
                  ],
                ],
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: kSlate,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: '설정',
          onPressed: () => context.push('/settings'),
          icon: const Icon(LucideIcons.settings, color: kCharcoal, size: 22),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
