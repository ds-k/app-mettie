import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/record.dart';
import '../../../../data/repositories/record_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/constants/veterinary_guidelines.dart';
import '../../../view_models/dashboard_view_model.dart';

class RecordEntryBottomSheet extends ConsumerStatefulWidget {
  const RecordEntryBottomSheet({super.key});

  @override
  ConsumerState<RecordEntryBottomSheet> createState() =>
      _RecordEntryBottomSheetState();
}

class _RecordEntryBottomSheetState
    extends ConsumerState<RecordEntryBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  DateTime _recordedAt = DateTime.now();

  // Controllers
  final _glucoseController = TextEditingController();
  String? _glucoseType;

  final _insulinDoseController = TextEditingController();
  final _insulinTypeController = TextEditingController();
  String? _selectedInsulinType;
  String? _injectionStatus = 'given';

  final _foodBrandController = TextEditingController();
  final _foodAmountController = TextEditingController();
  String? _foodType;

  final _weightController = TextEditingController();

  String? _waterIntake;
  String? _urination;
  String? _appetite;
  final int? _activityLevel = null;

  final _vomitCountController = TextEditingController(text: '0');
  String? _stoolStatus;

  final _notesController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _glucoseController.dispose();
    _insulinDoseController.dispose();
    _insulinTypeController.dispose();
    _foodBrandController.dispose();
    _foodAmountController.dispose();
    _weightController.dispose();
    _vomitCountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    // 최소 하나 이상의 데이터가 입력되었는지 확인
    final hasData =
        _glucoseController.text.isNotEmpty ||
        _insulinDoseController.text.isNotEmpty ||
        _foodAmountController.text.isNotEmpty ||
        _weightController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _vomitCountController.text != '0';

    if (!hasData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장할 데이터가 없습니다. 최소 한 가지 항목을 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pet = ref.read(currentPetProvider);
      final user = ref.read(currentUserProvider);

      if (pet == null || user == null) {
        throw '데이터를 저장할 수 없습니다 (반려동물 또는 사용자 정보 없음).';
      }

      final record = Record(
        id: '',
        petId: pet.id,
        writerId: user.id,
        recordedAt: _recordedAt,
        glucoseValue: int.tryParse(_glucoseController.text),
        glucoseType: _glucoseType,
        insulinDose: double.tryParse(_insulinDoseController.text),
        insulinType: _selectedInsulinType == '기타'
            ? _insulinTypeController.text.trim()
            : (_selectedInsulinType ?? pet.insulinType),
        injectionStatus: _injectionStatus,
        foodBrand: _foodBrandController.text,
        foodAmountG: double.tryParse(_foodAmountController.text),
        foodType: _foodType,
        weightKg: double.tryParse(_weightController.text),
        waterIntake: _waterIntake,
        urination: _urination,
        appetite: _appetite,
        activityLevel: _activityLevel,
        vomitCount: int.tryParse(_vomitCountController.text) ?? 0,
        stoolStatus: _stoolStatus,
        notes: _notesController.text,
        createdAt: DateTime.now(),
      );

      await ref.read(recordRepositoryProvider).createRecord(record);

      if (mounted) {
        Navigator.of(context).pop(); // 닫기
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    if (!mounted) return;

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            decoration: const BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(kRadiusXl),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: kHairline)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '기록 추가',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kInk,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: kSlate),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. 날짜/시간
                            _buildSectionTitle('날짜 및 시간'),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _selectDateTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: kCanvas,
                                  border: Border.all(color: kHairline),
                                  borderRadius: BorderRadius.circular(
                                    kRadiusMd,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.calendar,
                                      size: 20,
                                      color: kBrandBlue,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      DateFormat(
                                        'yyyy년 MM월 dd일 HH:mm',
                                      ).format(_recordedAt),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. 혈당
                            _buildSectionTitle('혈당 측정 (선택)'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildTextField(
                                    controller: _glucoseController,
                                    label: '혈당 수치 (mg/dL)',
                                    icon: LucideIcons.activity,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3), // 최대 999
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _glucoseType,
                                    decoration: _dropdownDecoration('상태', null),
                                    borderRadius: BorderRadius.circular(kRadiusLg),
                                    elevation: 2,
                                    menuMaxHeight: 200,
                                    style: const TextStyle(fontSize: 13, color: kInk),
                                    iconSize: 18,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'fasting',
                                        child: Text('공복'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'pre_meal',
                                        child: Text('식전'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'post_meal',
                                        child: Text('식후'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'nadir',
                                        child: Text('최저점'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'spot',
                                        child: Text('임의'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _glucoseType = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 3. 인슐린
                            _buildSectionTitle('인슐린 투여 (선택)'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _insulinDoseController,
                                    label: '투여량 (IU)',
                                    icon: LucideIcons.syringe,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      LengthLimitingTextInputFormatter(5), // 예: 99.99
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _injectionStatus,
                                    decoration: _dropdownDecoration('투여 상태', null),
                                    borderRadius: BorderRadius.circular(kRadiusLg),
                                    elevation: 2,
                                    menuMaxHeight: 200,
                                    style: const TextStyle(fontSize: 13, color: kInk),
                                    iconSize: 18,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'given',
                                        child: Text('투여 완료'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'skipped',
                                        child: Text('생략함'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'partial',
                                        child: Text('일부 투여'),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _injectionStatus = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedInsulinType,
                              decoration: _dropdownDecoration(
                                '인슐린 종류 (변경시에만 선택)',
                                LucideIcons.pill,
                              ),
                              borderRadius: BorderRadius.circular(kRadiusLg),
                              elevation: 2,
                              menuMaxHeight: 200,
                              style: const TextStyle(fontSize: 13, color: kInk),
                              iconSize: 18,
                              items: VeterinaryGuidelines.insulinTypes
                                  .map((type) => DropdownMenuItem(
                                        value: type,
                                        child: Text(type, overflow: TextOverflow.ellipsis),
                                      ))
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
                                label: '기타 인슐린 직접 입력',
                                icon: LucideIcons.penLine,
                              ),
                            ],
                            const SizedBox(height: 24),

                            // 4. 사료 및 체중
                            _buildSectionTitle('식이 및 체중 (선택)'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _foodAmountController,
                                    label: '급여량 (g)',
                                    icon: LucideIcons.bone,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                      LengthLimitingTextInputFormatter(5), // 예: 999.9
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _weightController,
                                    label: '체중 (kg)',
                                    icon: LucideIcons.scale,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                      LengthLimitingTextInputFormatter(5), // 예: 99.99
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // 5. 메모 UI
                            _buildSectionTitle('메모 (선택)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _notesController,
                              label: '자유롭게 기록을 남겨주세요',
                              icon: LucideIcons.fileText,
                              maxLines: 3,
                            ),

                            const SizedBox(height: 40),

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
                                onPressed: _isLoading ? null : _saveRecord,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: kOnDark,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        '기록 저장하기',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
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
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label, icon),
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
    );
  }
}
