/// 네이티브 플랫폼용 스텁 (웹에서만 사용되는 WebAudioService의 placeholder)
class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  Future<void> initialize() async {}
  Future<void> changeTrack(String fileName) async {}
  Future<bool> play() async => false;
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<void> stop() async {}
  Future<void> setVolume(double volume) async {}
  void setOnTrackEnded(void Function() callback) {}
  void setLoopMode(bool loop) {}
  double get volume => 0.3;
  bool get isPlaying => false;
  String get currentTrackPath => '';
  void dispose() {}
}
