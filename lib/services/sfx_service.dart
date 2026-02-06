// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 효과음 재생 서비스 (Web)
class SfxService {
  static final SfxService _instance = SfxService._internal();
  factory SfxService() => _instance;
  SfxService._internal();

  // 효과음 볼륨 (0.0 ~ 1.0)
  double _volume = 0.5;
  bool _enabled = true;

  // 오디오 풀 (동시에 여러 효과음 재생 가능)
  final Map<String, html.AudioElement> _audioPool = {};

  /// SFX 활성화 여부 설정
  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  /// SFX 볼륨 설정
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// 효과음 재생
  Future<void> play(String path) async {
    if (!_enabled) return;

    try {
      // 기존 오디오가 있으면 재사용, 없으면 생성
      if (!_audioPool.containsKey(path)) {
        final audio = html.AudioElement();
        audio.src = path;
        audio.preload = 'auto';
        audio.volume = _volume;
        
        // 로드 에러 핸들러
        audio.onError.listen((event) {
          print('SFX load error: $path');
        });
        
        _audioPool[path] = audio;
      }

      final audio = _audioPool[path]!;
      audio.volume = _volume;
      audio.currentTime = 0;
      
      // play() 호출 후 Promise 처리
      try {
        await audio.play();
        print('SFX played: $path');
      } catch (e) {
        print('SFX play failed: $path - $e');
      }
    } catch (e) {
      print('SFX error: $path - $e');
    }
  }

  /// 주사위 놓을 때 효과음
  Future<void> playDropDice() async {
    await play('assets/sfx/dicemerge/dice_pop/dropdice.mp3');
  }

  /// 주사위 합칠 때 효과음 (눈금별)
  Future<void> playPop(int diceValue) async {
    if (diceValue < 1 || diceValue > 6) return;
    await play('assets/sfx/dicemerge/dice_pop/pop$diceValue.mp3');
  }

  /// 버튼 클릭 효과음 (dropdice 재사용)
  Future<void> playButtonClick() async {
    await play('assets/sfx/dicemerge/dice_pop/dropdice.mp3');
  }

  /// 모든 오디오 정리
  void dispose() {
    for (final audio in _audioPool.values) {
      audio.pause();
      audio.remove();
    }
    _audioPool.clear();
  }
}
