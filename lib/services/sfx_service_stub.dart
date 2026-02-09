/// 효과음 재생 서비스 (Native - Stub)
class SfxService {
  static final SfxService _instance = SfxService._internal();
  factory SfxService() => _instance;
  SfxService._internal();

  double _volume = 0.5;
  bool _enabled = true;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
  }

  Future<void> play(String path) async {
    // Native 플랫폼은 audioplayers 패키지 필요
    // Stub: 아무 작업도 하지 않음
  }

  Future<void> playDropDice() async {
    await play('assets/sfx/dicemerge/dice_pop/dropdice.mp3');
  }

  Future<void> playPop(int diceValue) async {
    if (diceValue < 1 || diceValue > 6) return;
    await play('assets/sfx/dicemerge/dice_pop/pop$diceValue.mp3');
  }

  Future<void> playButtonClick() async {
    await play('assets/sfx/dicemerge/dice_pop/dropdice.mp3');
  }

  void dispose() {}
}
