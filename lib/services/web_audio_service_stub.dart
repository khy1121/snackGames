class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  bool _isInitialized = false;
  double _volume = 0.3;
  bool _isPlaying = false;
  bool _loopMode = false;
  String _currentTrackPath = 'audio/main_logo.mp3';
  
  void setOnTrackEnded(void Function() callback) {}
  void setOnTimeUpdate(void Function(Duration currentTime, Duration duration) callback) {}
  void setLoopMode(bool loop) { _loopMode = loop; }

  Future<void> initialize() async { _isInitialized = true; }
  Future<void> changeTrack(String fileName) async { _currentTrackPath = 'audio/$fileName'; }
  Future<bool> play() async => false;
  Future<void> pause() async { _isPlaying = false; }
  Future<void> resume() async {}
  Future<void> stop() async { _isPlaying = false; }
  Future<void> setVolume(double volume) async { _volume = volume; }

  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  String get currentTrackPath => _currentTrackPath;
  Duration get currentTime => Duration.zero;
  Duration get duration => const Duration(minutes: 3, seconds: 30);
  
  void seek(Duration position) {}
  void dispose() { _isInitialized = false; }
}
