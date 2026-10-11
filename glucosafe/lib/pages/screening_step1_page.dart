import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/screening_form.dart';
import '../models/screening_options.dart';
import '../models/screening_state.dart';
import '../widgets/app_colors.dart';
import '../widgets/screening_step_scaffold.dart';
import 'screening_step2_page.dart';

/// Skrining langkah 1 dari 4: Data Diri.
/// Simpan di: lib/pages/screening_step1_page.dart
class ScreeningStep1Page extends StatefulWidget {
  const ScreeningStep1Page({
    super.key,
    this.onNext,
    this.onBack,
    this.onProfileTap,
  });

  /// Dipanggil saat tombol Lanjut ditekan (nanti: buka langkah 2).
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  @override
  State<ScreeningStep1Page> createState() => _ScreeningStep1PageState();
}

class _ScreeningStep1PageState extends State<ScreeningStep1Page> {
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  final _heightFocus = FocusNode();
  final _weightFocus = FocusNode();
  bool _heightTouched = false;
  bool _weightTouched = false;

  @override
  void initState() {
    super.initState();
    // Isi awal dari state bersama, supaya data tidak hilang saat kembali ke langkah ini.
    final form = screeningFormNotifier.value;
    _heightCtrl = TextEditingController(text: formatNumber(form.heightCm));
    _weightCtrl = TextEditingController(text: formatNumber(form.weightKg));
    _heightFocus.addListener(() {
      if (!_heightFocus.hasFocus && !_heightTouched) {
        setState(() => _heightTouched = true);
      }
    });
    _weightFocus.addListener(() {
      if (!_weightFocus.hasFocus && !_weightTouched) {
        setState(() => _weightTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _heightFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  String? _heightError(ScreeningForm form) {
    if (!_heightTouched) return null;
    if (_heightCtrl.text.trim().isEmpty) return 'Wajib diisi';
    if (!form.isHeightValid) {
      return 'Isi antara ${ScreeningForm.minHeightCm.toInt()}–${ScreeningForm.maxHeightCm.toInt()} cm';
    }
    return null;
  }

  String? _weightError(ScreeningForm form) {
    if (!_weightTouched) return null;
    if (_weightCtrl.text.trim().isEmpty) return 'Wajib diisi';
    if (!form.isWeightValid) {
      return 'Isi antara ${ScreeningForm.minWeightKg.toInt()}–${ScreeningForm.maxWeightKg.toInt()} kg';
    }
    return null;
  }

  void _next() {
    final onNext = widget.onNext;
    if (onNext != null) {
      onNext();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScreeningStep2Page()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreeningStepScaffold(
      step: 1,
      title: 'Data Diri',
      subtitle: 'Lengkapi informasi fisik dan profil dasar Anda untuk mempermudah perhitungan faktor risiko diabetes.',
      onBack: widget.onBack,
      onProfileTap: widget.onProfileTap,
      child: ValueListenableBuilder<ScreeningForm>(
        valueListenable: screeningFormNotifier,
        builder: (context, form, _) {
          final bmi = form.bmiRounded;
          final canContinue = form.isStep1Valid;

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Jenis Kelamin'),
                _OptionDropdown(
                  value: form.sex,
                  hint: 'Pilih jenis kelamin',
                  options: sexOptions,
                  onChanged: (v) =>
                      updateScreeningForm((f) => f.copyWith(sex: v)),
                ),
                const SizedBox(height: 20),
                const _FieldLabel('Rentang Usia'),
                _OptionDropdown(
                  value: form.age,
                  hint: 'Pilih rentang usia',
                  options: ageOptions,
                  onChanged: (v) =>
                      updateScreeningForm((f) => f.copyWith(age: v)),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _NumberField(
                        label: 'Tinggi Badan',
                        suffix: 'cm',
                        controller: _heightCtrl,
                        focusNode: _heightFocus,
                        errorText: _heightError(form),
                        onChanged: (text) => updateScreeningForm(
                          (f) =>
                              f.copyWith(heightCm: parseLocalizedDouble(text)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        label: 'Berat Badan',
                        suffix: 'kg',
                        controller: _weightCtrl,
                        focusNode: _weightFocus,
                        errorText: _weightError(form),
                        onChanged: (text) => updateScreeningForm(
                          (f) =>
                              f.copyWith(weightKg: parseLocalizedDouble(text)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (bmi != null) ...[
                  const SizedBox(height: 20),
                  _BmiCard(bmi: bmi),
                ],
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: canContinue ? _next : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.disabled,
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Lanjut'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
                if (!canContinue)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Center(
                      child: Text(
                        'Lengkapi semua isian untuk melanjutkan.',
                        style: TextStyle(fontSize: 14, color: AppColors.slate),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(color: c, width: w),
);

InputDecoration _decoration({String? suffix, String? error}) {
  return InputDecoration(
    suffixText: suffix,
    errorText: error,
    errorStyle: const TextStyle(fontSize: 13),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: _border(AppColors.border),
    enabledBorder: _border(AppColors.border),
    focusedBorder: _border(AppColors.brand2, 1.5),
    errorBorder: _border(AppColors.error),
    focusedErrorBorder: _border(AppColors.error, 1.5),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _OptionDropdown extends StatelessWidget {
  const _OptionDropdown({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  final int? value;
  final String hint;
  final List<Option<int>> options;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 320,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      style: const TextStyle(fontSize: 16, color: AppColors.ink),
      hint: Text(
        hint,
        style: const TextStyle(fontSize: 16, color: AppColors.hint),
      ),
      decoration: _decoration(),
      items: [
        for (final option in options)
          DropdownMenuItem<int>(value: option.value, child: Text(option.label)),
      ],
      onChanged: onChanged,
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.focusNode,
    required this.errorText,
    required this.onChanged,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: const TextStyle(fontSize: 16, color: AppColors.ink),
          decoration: _decoration(suffix: suffix, error: errorText),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.bmi});
  final double bmi;

  @override
  Widget build(BuildContext context) {
    final category = bmiCategoryOf(bmi);
    final isNormal = category == BmiCategory.normal;
    final accent = isNormal ? AppColors.brand : AppColors.warn;
    final background = isNormal ? AppColors.okBg : AppColors.warnBg;
    final border = isNormal ? AppColors.okBorder : AppColors.warnBorder;
    final summary = 'BMI: ${bmi.toStringAsFixed(1)} kg/m² • ${category.label}';

    return Semantics(
      label: 'Hasil BMI. $summary',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Icon(Icons.monitor_heart_outlined, color: accent),
            const SizedBox(width: 8),
            const Text(
              'Hasil BMI',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                summary,
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.w700, color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
