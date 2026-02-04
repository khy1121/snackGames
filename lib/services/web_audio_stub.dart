/// 네이티브 플랫폼용 스텁 (웹에서만 사용되는 WebAudioService의 placeholder)
class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  Future<void> initialize() async {}
  Future<void> onUserInteraction() async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  Future<void> toggleMusic() async {}
  Future<void> setVolume(double volume) async {}
  bool get isMusicEnabled => false;
  double get volume => 0.3;
  bool get isPlaying => false;
  void dispose() {}
}
