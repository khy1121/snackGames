import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/game_data_service.dart';
import '../services/background_music_service.dart';
import '../services/vibration_service.dart';
import '../services/sfx_service_stub.dart'
    if (dart.library.html) '../services/sfx_service.dart';
import '../services/music_player_service.dart';
import '../home/home_page.dart';

/// 설정 페이지
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Theme background
      appBar: AppBar(
        title: Text('설정', style: TextStyle(color: Theme.of(context).primaryColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Accessibility (Senior Friendly)
            _buildSectionHeader('화면 설정 (어르신 맞춤)'),
            const SizedBox(height: 12),
            _buildAccessibilityCard(),
            const SizedBox(height: 30),
  
            // 2. Sound & Haptics
            _buildSectionHeader('사운드 및 효과'),
            const SizedBox(height: 12),
            _buildSoundCard(),
            const SizedBox(height: 30),
  
            // 3. App Info & Data
            _buildSectionHeader('앱 정보 및 관리'),
            const SizedBox(height: 12),
            _buildInfoCard(),
            const SizedBox(height: 40),
            
            // Footer
            const Center(
              child: Text(
                'Snack Games v2.7.1',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF667EEA),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAccessibilityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_size, color: Theme.of(context).primaryColor, size: 24),
              SizedBox(width: 12),
              Text(
                '글자 크기',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<double>(
            valueListenable: SettingsService.textScale,
            builder: (context, scale, child) {
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      thumbColor: Theme.of(context).primaryColor,
                      overlayColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                      trackHeight: 8.0,
                    ),
                    child: Slider(
                      value: scale,
                      min: 1.0,
                      max: 1.5,
                      divisions: 5,
                      label: '${((scale - 1.0) * 200).toInt()}%',
                      onChanged: (value) {
                        SettingsService.setTextScale(value);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '글자가 이 크기로 보입니다.\n편안하게 읽으실 수 있나요?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 16 * scale, // Apply scale locally for preview
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSoundCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // 효과음 볼륨 슬라이더
          ValueListenableBuilder<double>(
            valueListenable: SettingsService.sfxVolume,
            builder: (context, volume, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        volume > 0 ? Icons.volume_up : Icons.volume_off,
                        color: volume > 0 ? const Color(0xFF10B981) : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '효과음',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${(volume * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF10B981),
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                      thumbColor: const Color(0xFF10B981),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        SettingsService.setSfxVolume(value);
                        SfxService().setVolume(value);
                        SfxService().setEnabled(value > 0);
                        // 미리 듣기
                        if (value > 0) SfxService().playButtonClick();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 16),
          
          // 배경음악 볼륨 슬라이더
          ValueListenableBuilder<double>(
            valueListenable: SettingsService.musicVolume,
            builder: (context, volume, child) {
              return Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        volume > 0 ? Icons.music_note : Icons.music_off,
                        color: volume > 0 ? const Color(0xFF667EEA) : Colors.grey,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '배경음악',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        '${(volume * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF667EEA),
                      inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                      thumbColor: const Color(0xFF667EEA),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: (value) {
                        SettingsService.setMusicVolume(value);
                        MusicPlayerService().setVolume(value);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          
          Divider(color: Colors.grey.withValues(alpha: 0.2), height: 16),
          
          // 진동 토글
          ValueListenableBuilder<bool>(
            valueListenable: SettingsService.vibrationEnabled,
            builder: (context, enabled, child) {
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '진동',
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  enabled ? '켜짐' : '꺼짐',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                secondary: Icon(
                  enabled ? Icons.vibration : Icons.smartphone,
                  color: enabled ? const Color(0xFF10B981) : Colors.grey,
                ),
                value: enabled,
                activeTrackColor: const Color(0xFF10B981),
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.3),
                onChanged: (value) {
                  SettingsService.setVibrationEnabled(value);
                  VibrationService.setEnabled(value);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildInfoRow('현재 버전', '2.7.1'),
          const SizedBox(height: 20),
          InkWell(
            onTap: _showResetConfirmDialog,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_forever, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text(
                    '데이터 초기화',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ],
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2E),
        title: const Text('데이터 초기화', style: TextStyle(color: Colors.white)),
        content: const Text(
          '정말로 모든 게임 데이터를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // 다이얼로그 닫기 (동기 호출)
              
              await GameDataService.resetAllData();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('모든 데이터가 초기화되었습니다.')),
                );
                // 홈으로 이동하여 리셋된 상태 반영
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              }
            },
            child: const Text('초기화', style: TextStyle(color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }
}
