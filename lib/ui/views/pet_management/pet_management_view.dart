import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../view_models/pet_management_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/pet.dart';
import 'widgets/pet_list_item.dart';

class PetManagementView extends ConsumerStatefulWidget {
  const PetManagementView({super.key});

  @override
  ConsumerState<PetManagementView> createState() => _PetManagementViewState();
}

class _PetManagementViewState extends ConsumerState<PetManagementView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _weightController = TextEditingController();
  final _insulinTypeController = TextEditingController();
  final _insulinDoseController = TextEditingController();
  final _vetClinicController = TextEditingController();

  String _species = 'dog';
  String _sex = 'male';
  bool _isNeutered = false;
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _insulinTypeController.dispose();
    _insulinDoseController.dispose();
    _vetClinicController.dispose();
    super.dispose();
  }

  void _savePet() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(petManagementViewModelProvider.notifier)
        .savePet(
          name: _nameController.text.trim(),
          species: _species,
          breed: _breedController.text.trim(),
          sex: _sex,
          isNeutered: _isNeutered,
          weightKg: double.tryParse(_weightController.text),
          insulinType: _insulinTypeController.text.trim(),
          insulinUnitIu: double.tryParse(_insulinDoseController.text),
          vetClinic: _vetClinicController.text.trim(),
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isCreatingNew = false;
      });
      // Optionally clear form
      _nameController.clear();
      _breedController.clear();
      _weightController.clear();
      _insulinTypeController.clear();
      _insulinDoseController.clear();
      _vetClinicController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(petManagementViewModelProvider).error ?? '저장에 실패했습니다.',
          ),
          backgroundColor: kBrandError,
        ),
      );
    }
  }

  void _confirmDeleteOrLeave(Pet pet) {
    final isOwner = pet.role == 'owner';
    final title = isOwner ? '반려동물 삭제' : '가족 나가기';
    final content = isOwner 
        ? '${pet.name}의 모든 데이터를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'
        : '${pet.name}의 가족 공간에서 나가시겠습니까?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: kSlate)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(petManagementViewModelProvider.notifier).deletePetOrLeave(pet);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isOwner ? '삭제되었습니다.' : '가족에서 나왔습니다.')),
                );
              }
            },
            child: Text(isOwner ? '삭제' : '나가기', style: const TextStyle(color: kBrandError, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPetList(List<Pet> pets) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('반려동물 관리', style: TextStyle(color: kInk, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: kInk),
            onPressed: () {
              setState(() {
                _isCreatingNew = true;
              });
            },
            tooltip: '새 반려동물 등록',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: pets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final pet = pets[index];
          return PetListItem(
            pet: pet,
            onDeleteOrLeave: () => _confirmDeleteOrLeave(pet),
          );
        },
      ),
    );
  }

  Widget _buildCreationForm(BuildContext context, WidgetRef ref, bool showBackButton) {
    final state = ref.watch(petManagementViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: showBackButton ? 100 : 200,
            pinned: true,
            leading: showBackButton 
              ? IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: kOnDark),
                  onPressed: () => setState(() => _isCreatingNew = false),
                )
              : null,
            backgroundColor: kHeroDarkFrom, // pinned 되었을 때의 색상
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kHeroDarkFrom, kHeroDarkTo],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: showBackButton ? null : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 20),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: kSurfaceSoft,
                      child: Icon(
                        LucideIcons.pawPrint,
                        size: 40,
                        color: kSlate,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '새로운 반려동물 등록',
                      style: TextStyle(
                        color: kOnDark,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: kBrandError.withValues(alpha: 0.1),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: kBrandError),
                        ),
                      ),

                    // 1. 기본 정보
                    _buildSectionTitle('기본 정보'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: '이름',
                      icon: LucideIcons.dog,
                      validator: (val) =>
                          val == null || val.isEmpty ? '이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _species,
                            decoration: _inputDecoration(
                              '종류',
                              LucideIcons.pawPrint,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'dog',
                                child: Text('강아지'),
                              ),
                              DropdownMenuItem(
                                value: 'cat',
                                child: Text('고양이'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _species = val);
                                ref
                                    .read(
                                      petManagementViewModelProvider.notifier,
                                    )
                                    .onSpeciesChanged(val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _sex,
                            decoration: _inputDecoration(
                              '성별',
                              LucideIcons.user,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('수컷'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('암컷'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _sex = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _breedController,
                      label: '품종 (선택)',
                      icon: LucideIcons.bookOpen,
                    ),
                    const SizedBox(height: 16),
                    Material( // Fix ink splash issue
                      color: Colors.transparent,
                      child: SwitchListTile(
                        title: const Text('중성화 완료'),
                        value: _isNeutered,
                        activeThumbColor: kBrandBlue,
                        onChanged: (val) => setState(() => _isNeutered = val),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 2. 신체 및 건강 정보
                    _buildSectionTitle('건강 및 관리 정보'),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _weightController,
                      label: '체중 (kg)',
                      icon: LucideIcons.activity,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _insulinTypeController,
                            label: '인슐린 종류 (선택)',
                            icon: LucideIcons.syringe,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _insulinDoseController,
                            label: '단위 (IU)',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // 3. 목표 혈당 (자동 설정됨)
                    _buildSectionTitle('목표 혈당 설정 (수정 가능)'),
                    const SizedBox(height: 8),
                    Text(
                      '${state.targetGlucoseMin} ~ ${state.targetGlucoseMax} mg/dL',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: kBrandBlue,
                      ),
                    ),
                    RangeSlider(
                      values: RangeValues(
                        state.targetGlucoseMin.toDouble(),
                        state.targetGlucoseMax.toDouble(),
                      ),
                      min: 50,
                      max: 600,
                      divisions: 550,
                      activeColor: kBrandBlue,
                      labels: RangeLabels(
                        '${state.targetGlucoseMin}',
                        '${state.targetGlucoseMax}',
                      ),
                      onChanged: (RangeValues values) {
                        ref
                            .read(petManagementViewModelProvider.notifier)
                            .updateTargetGlucose(
                              values.start.round(),
                              values.end.round(),
                            );
                      },
                    ),

                    const SizedBox(height: 48),

                    // 저장 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kBrandBlue,
                          foregroundColor: kOnDark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              kRadiusFull,
                            ), // Pill 형태
                          ),
                        ),
                        onPressed: state.isLoading ? null : _savePet,
                        child: state.isLoading
                            ? const SizedBox(
                                width: 24, 
                                height: 24, 
                                child: CircularProgressIndicator(color: kOnDark, strokeWidth: 2)
                              )
                            : const Text(
                                '저장하고 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: kCharcoal,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, color: kSlate, size: 20) : null,
      filled: true,
      fillColor: kCanvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: const BorderSide(color: kHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: const BorderSide(color: kHairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusMd),
        borderSide: const BorderSide(color: kBrandBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petsProvider);

    return petsAsync.when(
      data: (pets) {
        if (pets.isEmpty || _isCreatingNew) {
          return _buildCreationForm(context, ref, pets.isNotEmpty);
        } else {
          return _buildPetList(pets);
        }
      },
      loading: () => const Scaffold(backgroundColor: Colors.transparent, body: Center(child: CircularProgressIndicator(color: kBrandBlue))),
      error: (err, stack) => Scaffold(backgroundColor: Colors.transparent, body: Center(child: Text('Error: $err', style: const TextStyle(color: kBrandError)))),
    );
  }
}
