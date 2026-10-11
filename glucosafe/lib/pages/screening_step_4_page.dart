import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import 'screening_result_page.dart';

class ScreeningStep4Page extends StatefulWidget {
  const ScreeningStep4Page({super.key});

  @override
  State<ScreeningStep4Page> createState() => _ScreeningStep4PageState();
}

class _ScreeningStep4PageState extends State<ScreeningStep4Page> {
  int? _generalHealthIndex; // 0=Sangat Baik, 1=Baik, 2=Cukup, 3=Kurang, 4=Buruk
  double _mentalHealthDays = 3;
  double _physicalHealthDays = 2;

  final List<Map<String, dynamic>> _healthOptions = [
    {'label': 'Sangat\nBaik', 'icon': Icons.sentiment_very_satisfied},
    {'label': 'Baik', 'icon': Icons.sentiment_satisfied},
    {'label': 'Cukup', 'icon': Icons.sentiment_neutral},
    {'label': 'Kurang', 'icon': Icons.sentiment_dissatisfied},
    {'label': 'Buruk', 'icon': Icons.sentiment_very_dissatisfied},
  ];

  Widget _buildHealthEmoticons() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kondisi kesehatan secara umum',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Bagaimana Anda menilai kondisi kesehatan Anda saat ini?',
            style: TextStyle(fontSize: 13, color: AppColors.mute),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_healthOptions.length, (index) {
              final isSelected = _generalHealthIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _generalHealthIndex = index),
                child: Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.brand
                        : const Color(0xFFF6F5FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _healthOptions[index]['icon'],
                        color: isSelected ? Colors.white : AppColors.mute,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _healthOptions[index]['label'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.mute,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '(dalam 30 hari terakhir)',
                      style: TextStyle(fontSize: 13, color: AppColors.mute),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lightPill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${value.toInt()} Hari',
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.progressBg,
              inactiveTrackColor: AppColors.progressBg,
              thumbColor: AppColors.brand,
              trackHeight: 8,
              overlayColor: AppColors.brand.withValues(alpha: 0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 30,
              divisions: 30,
              onChanged: onChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  '0 Hari',
                  style: TextStyle(fontSize: 12, color: AppColors.mute),
                ),
                Text(
                  '15 Hari',
                  style: TextStyle(fontSize: 12, color: AppColors.mute),
                ),
                Text(
                  '30 Hari',
                  style: TextStyle(fontSize: 12, color: AppColors.mute),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.formBg,
      appBar: AppBar(
        backgroundColor: AppColors.formBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Skrining',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: AppColors.brand,
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
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'LANGKAH 4 DARI 4',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
                    ),
                    Text(
                      '100% Selesai',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brand,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.progressBg,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.brand,
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
                    'Kondisi Umum',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Evaluasi menyeluruh untuk melengkapi profil risiko kesehatan Anda.',
                    style: TextStyle(fontSize: 14, color: AppColors.mute),
                  ),
                  const SizedBox(height: 24),

                  _buildHealthEmoticons(),
                  _buildSliderCard(
                    title: 'Hari kesehatan mental terganggu',
                    value: _mentalHealthDays,
                    onChanged: (val) => setState(() => _mentalHealthDays = val),
                  ),
                  _buildSliderCard(
                    title: 'Hari kesehatan fisik tidak fit',
                    value: _physicalHealthDays,
                    onChanged: (val) =>
                        setState(() => _physicalHealthDays = val),
                  ),

                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ScreeningResultPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Cek Risiko Saya',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Back to previous step
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 18,
                        color: AppColors.mute,
                      ),
                      label: const Text(
                        'Kembali ke Langkah Sebelumnya',
                        style: TextStyle(
                          color: AppColors.mute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
