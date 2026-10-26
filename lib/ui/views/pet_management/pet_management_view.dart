import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../../view_models/pet_management_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
import '../../../data/models/pet.dart';
import '../../../data/constants/veterinary_guidelines.dart';
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
  String? _selectedInsulinType;

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
          insulinType: _selectedInsulinType == '기타'
              ? _insulinTypeController.text.trim()
              : (_selectedInsulinType ?? ''),
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
      _selectedInsulinType = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage(context.l10n, ref.read(petManagementViewModelProvider).error),
          ),
          backgroundColor: kBrandError,
        ),
      );
    }
  }

  void _confirmDeleteOrLeave(Pet pet) {
    final isOwner = pet.role == 'owner';
    final l = context.l10n;
    final title = isOwner ? l.petDeleteTitle : l.petLeaveTitle;
    final content = isOwner
        ? l.petDeleteBody(pet.name)
        : l.petLeaveBody(pet.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel, style: const TextStyle(color: kSlate)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(petManagementViewModelProvider.notifier)
                  .deletePetOrLeave(pet);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isOwner ? l.petDeleted : l.petLeft)),
                );
              }
            },
            child: Text(
              isOwner ? l.commonDelete : l.petLeave,
              style: const TextStyle(
                color: kBrandError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetList(List<Pet> pets) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          context.l10n.petManageTitle,
          style: TextStyle(color: kInk, fontWeight: FontWeight.bold),
        ),
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
            tooltip: context.l10n.petAddTooltip,
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

  Widget _buildCreationForm(
    BuildContext context,
    WidgetRef ref,
    bool showBackButton,
  ) {
    final state = ref.watch(petManagementViewModelProvider);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          backgroundColor: kSurface,
          elevation: 0,
          leading: showBackButton
              ? IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: kInk),
                  onPressed: () => setState(() => _isCreatingNew = false),
                )
              : null,
          title: Text(
            context.l10n.petNewTitle,
            style: TextStyle(color: kInk, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
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
                        errorMessage(context.l10n, state.error),
                        style: const TextStyle(color: kBrandError),
                      ),
                    ),

                  // 1. 기본 정보
                  _buildSectionTitle(context.l10n.petBasicInfo),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: context.l10n.petName,
                    icon: LucideIcons.dog,
                    validator: (val) =>
                        val == null || val.isEmpty ? context.l10n.petNameRequired : null,
                    inputFormatters: [LengthLimitingTextInputFormatter(20)],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _species,
                          decoration: _dropdownDecoration(
                            context.l10n.petSpecies,
                            LucideIcons.pawPrint,
                          ),
                          borderRadius: BorderRadius.circular(kRadiusLg),
                          elevation: 2,
                          menuMaxHeight: 250,
                          style: const TextStyle(fontSize: 13, color: kInk),
                          iconSize: 18,
                          items: [
                            DropdownMenuItem(value: 'dog', child: Text(context.l10n.speciesDog)),
                            DropdownMenuItem(value: 'cat', child: Text(context.l10n.speciesCat)),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _species = val);
                              ref
                                  .read(petManagementViewModelProvider.notifier)
                                  .onSpeciesChanged(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sex,
                          decoration: _dropdownDecoration(
                            context.l10n.petSex,
                            LucideIcons.user,
                          ),
                          borderRadius: BorderRadius.circular(kRadiusLg),
                          elevation: 2,
                          menuMaxHeight: 250,
                          style: const TextStyle(fontSize: 13, color: kInk),
                          iconSize: 18,
                          items: [
                            DropdownMenuItem(value: 'male', child: Text(context.l10n.sexMale)),
                            DropdownMenuItem(
                              value: 'female',
                              child: Text(context.l10n.sexFemale),
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
                    label: context.l10n.petBreedOptional,
                    icon: LucideIcons.bookOpen,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                  ),
                  const SizedBox(height: 16),
                  Material(
                    // Fix ink splash issue
                    color: Colors.transparent,
                    child: SwitchListTile(
                      title: Text(context.l10n.petNeutered),
                      value: _isNeutered,
                      activeThumbColor: kBrandBlue,
                      onChanged: (val) => setState(() => _isNeutered = val),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. 신체 및 건강 정보
                  _buildSectionTitle(context.l10n.petHealthInfo),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _weightController,
                    label: context.l10n.petWeightKg,
                    icon: LucideIcons.activity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                      LengthLimitingTextInputFormatter(5), // 예: 99.99
                    ],
                    validator: (val) {
                      if (val != null && val.isNotEmpty) {
                        final weight = double.tryParse(val);
                        if (weight == null || weight <= 0 || weight > 150) {
                          return context.l10n.petWeightInvalid;
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedInsulinType,
                              decoration: _dropdownDecoration(
                                context.l10n.petInsulinTypeOptional,
                                LucideIcons.syringe,
                              ),
                              borderRadius: BorderRadius.circular(kRadiusLg),
                              elevation: 2,
                              menuMaxHeight: 250,
                              style: const TextStyle(fontSize: 13, color: kInk),
                              iconSize: 18,
                              items: VeterinaryGuidelines.insulinTypes
                                  .map(
                                    (type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(
                                        insulinDisplayName(context.l10n, type),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedInsulinType = val;
                                  if (val != '기타') {
                                    _insulinTypeController.clear();
                                  }
                                });
                              },
                              isExpanded: true,
                            ),
                            if (_selectedInsulinType == '기타') ...[
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _insulinTypeController,
                                label: context.l10n.petInsulinOther,
                                icon: LucideIcons.penLine,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _insulinDoseController,
                          label: context.l10n.petInsulinUnits,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                            LengthLimitingTextInputFormatter(5), // 예: 99.99
                          ],
                          validator: (val) {
                            if (val != null && val.isNotEmpty) {
                              final dose = double.tryParse(val);
                              if (dose == null || dose <= 0 || dose > 150) {
                                return context.l10n.petInsulinUnitsInvalid;
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // 3. 목표 혈당 (자동 설정됨)
                  _buildSectionTitle(context.l10n.petTargetGlucose),
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
                              child: CircularProgressIndicator(
                                color: kOnDark,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              context.l10n.petSaveAndStart,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ),
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

  InputDecoration _dropdownDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, color: kSlate, size: 16) : null,
      filled: true,
      fillColor: kCanvas,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusFull),
        borderSide: const BorderSide(color: kHairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusFull),
        borderSide: const BorderSide(color: kHairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadiusFull),
        borderSide: const BorderSide(color: kBrandBlue, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
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
      loading: () => const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: kBrandBlue)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Text(
            errorMessage(context.l10n, err),
            style: const TextStyle(color: kBrandError),
          ),
        ),
      ),
    );
  }
}
