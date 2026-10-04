import 'package:flutter/material.dart';
import '../models/screening_form.dart';
import '../models/screening_state.dart';
import '../widgets/screening_step_scaffold.dart';
import 'screening_step_3_page.dart';

/// Skrining langkah 2 dari 4: Riwayat Diagnosis.
/// Simpan di: lib/pages/screening_step2_page.dart

const _toggleBg = Color(0xFFEEF0FB);

/// Satu pertanyaan: teks, cara membaca nilainya dari form, dan cara menyimpannya.
class _Question {
  const _Question({
    required this.label,
    required this.read,
    required this.write,
  });

  final String label;
  final int? Function(ScreeningForm form) read;
  final ScreeningForm Function(ScreeningForm form, int value) write;
}

// Urutan sama dengan desain. 1 = Ya, 0 = Tidak.
final List<_Question> _questions = [
  _Question(
    label: 'Dokter pernah menyatakan tekanan darah tinggi',
    read: (f) => f.highBp,
    write: (f, v) => f.copyWith(highBp: v),
  ),
  _Question(
    label: 'Dokter pernah menyatakan kolesterol tinggi',
    read: (f) => f.highChol,
    write: (f, v) => f.copyWith(highChol: v),
  ),
  _Question(
    label: 'Pernah terkena stroke',
    read: (f) => f.stroke,
    write: (f, v) => f.copyWith(stroke: v),
  ),
  _Question(
    label: 'Penyakit jantung atau pernah serangan jantung',
    read: (f) => f.heartDiseaseOrAttack,
    write: (f, v) => f.copyWith(heartDiseaseOrAttack: v),
  ),
  _Question(
    label: 'Sangat kesulitan berjalan atau naik tangga',
    read: (f) => f.diffWalk,
    write: (f, v) => f.copyWith(diffWalk: v),
  ),
];

class ScreeningStep2Page extends StatelessWidget {
  const ScreeningStep2Page({
    super.key,
    this.onNext,
    this.onBack,
    this.onProfileTap,
  });

  /// Dipanggil saat Lanjut ditekan (nanti: buka langkah 3).
  final VoidCallback? onNext;
  final VoidCallback? onBack;
  final VoidCallback? onProfileTap;

  void _next(BuildContext context) {
    final callback = onNext;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScreeningStep3Page()),
    );
  }

  void _back(BuildContext context) {
    final callback = onBack;
    if (callback != null) {
      callback();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return ScreeningStepScaffold(
      step: 2,
      title: 'Riwayat Diagnosis',
      subtitle: 'Jawab sesuai kondisi Anda.',
      onBack: () => _back(context),
      onProfileTap: onProfileTap,
      child: ValueListenableBuilder<ScreeningForm>(
        valueListenable: screeningFormNotifier,
        builder: (context, form, _) {
          final canContinue = form.isStep2Valid;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final q in _questions) ...[
                _QuestionCard(
                  label: q.label,
                  value: q.read(form),
                  onChanged: (v) => updateScreeningForm((f) => q.write(f, v)),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: () => _back(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _toggleBg,
                        foregroundColor: ScreeningColors.ink,
                        elevation: 0,
                        minimumSize: const Size(0, 54),
                        shape: buttonShape,
                        textStyle: buttonText,
                      ),
                      child: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: canContinue ? () => _next(context) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ScreeningColors.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: ScreeningColors.disabled,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(0, 54),
                        shape: buttonShape,
                        textStyle: buttonText,
                      ),
                      child: const Text('Lanjut'),
                    ),
                  ),
                ],
              ),
              if (!canContinue)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: Text(
                      'Jawab semua pertanyaan untuk melanjutkan.',
                      style: TextStyle(
                        fontSize: 14,
                        color: ScreeningColors.slate,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int? value; // 1 = ya, 0 = tidak, null = belum dijawab
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ScreeningColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: ScreeningColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _YesNoToggle(
            question: label,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Pilihan "Tidak | Ya". Keduanya netral sampai pengguna memilih.
class _YesNoToggle extends StatelessWidget {
  const _YesNoToggle({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final int? value;
  final ValueChanged<int> onChanged;

  Widget _segment(String label, int segmentValue) {
    final selected = value == segmentValue;
    return Semantics(
      button: true,
      selected: selected,
      label: '$question: $label',
      excludeSemantics: true,
      child: Material(
        color: selected ? ScreeningColors.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(segmentValue),
          child: Container(
            constraints: const BoxConstraints(minWidth: 60, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : ScreeningColors.slate,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _toggleBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('Tidak', 0),
          _segment('Ya', 1),
        ],
      ),
    );
  }
}