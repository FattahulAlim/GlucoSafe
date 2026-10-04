import 'package:flutter/material.dart';
import 'screening_step_4_page.dart';

class _C {
  static const bg = Color(0xFFFAF8FF);
  static const ink = Color(0xFF131B2E);
  static const mute = Color(0xFF3D4947);
  static const brand = Color(0xFF00685F);
  static const inactiveBg = Color(0xFFEEF0FA);
  static const progressBg = Color(0xFFE0DDF8);
}

class ScreeningStep3Page extends StatefulWidget {
  const ScreeningStep3Page({super.key});

  @override
  State<ScreeningStep3Page> createState() => _ScreeningStep3PageState();
}

class _ScreeningStep3PageState extends State<ScreeningStep3Page> {
  bool? _isSmoking;
  bool? _isExercising;
  bool? _eatFruits;
  bool? _eatVegetables;

  Widget _buildToggleQuestion({
    required String question,
    required bool? value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _C.ink),
          ),
          const SizedBox(height: 16),
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: _C.inactiveBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: value == false ? _C.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Tidak',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: value == false ? Colors.white : _C.mute,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(true),
                    child: Container(
                      decoration: BoxDecoration(
                        color: value == true ? _C.brand : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Ya',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: value == true ? Colors.white : _C.mute,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
      appBar: AppBar(
        backgroundColor: _C.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _C.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _C.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Skrining',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _C.ink),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: _C.brand,
              radius: 16,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('LANGKAH 3 DARI 4', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.brand)),
                    Text('75% Selesai', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _C.brand)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _C.progressBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.75,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _C.brand,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pola Gaya Hidup',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _C.ink),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kebiasaan aktivitas fisik dan nutrisi Anda sehari-hari.',
                    style: TextStyle(fontSize: 14, color: _C.mute),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildToggleQuestion(
                    question: 'Merokok minimal 100 batang seumur hidup?',
                    value: _isSmoking,
                    onChanged: (val) => setState(() => _isSmoking = val),
                  ),
                  _buildToggleQuestion(
                    question: 'Aktif berolahraga dalam 30 hari terakhir?',
                    value: _isExercising,
                    onChanged: (val) => setState(() => _isExercising = val),
                  ),
                  _buildToggleQuestion(
                    question: 'Konsumsi buah minimal 1x sehari?',
                    value: _eatFruits,
                    onChanged: (val) => setState(() => _eatFruits = val),
                  ),
                  _buildToggleQuestion(
                    question: 'Konsumsi sayur minimal 1x sehari?',
                    value: _eatVegetables,
                    onChanged: (val) => setState(() => _eatVegetables = val),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _C.bg,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.inactiveBg,
                      foregroundColor: _C.ink,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScreeningStep4Page(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _C.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Lanjut', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
