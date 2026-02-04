// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:shared_preferences/shared_preferences.dart';

/// 웹 전용 배경음악 서비스 (HTML5 Audio API 사용)
class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  static const String _musicEnabledKey = 'music_enabled';
  static const String _musicVolumeKey = 'music_volume';

  html.AudioElement? _audioElement;
  bool _isInitialized = false;
  bool _isMusicEnabled = true;
  double _volume = 0.3;
  bool _isPlaying = false;
  bool _userInteracted = false;

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _volume = prefs.getDouble(_musicVolumeKey) ?? 0.3;

      // HTML5 Audio 요소 생성
      _audioElement = html.AudioElement()
        ..src = 'assets/assets/audio/mainLogo.mp3'
        ..loop = true
        ..volume = _volume;

      _isInitialized = true;
      print('Web audio service initialized');
    } catch (e) {
      print('Failed to initialize web audio service: $e');
      _isInitialized = true;
    }
  }

  /// 사용자 상호작용 후 음악 재생 시도
  Future<void> onUserInteraction() async {
    if (_userInteracted) return;
    _userInteracted = true;
    
    if (_isMusicEnabled && !_isPlaying) {
      await play();
    }
  }

  /// 배경음악 재생
  Future<void> play() async {
    if (!_isMusicEnabled || _isPlaying || _audioElement == null) return;

    try {
      await _audioElement!.play();
      _isPlaying = true;
      print('Web background music started');
    } catch (e) {
      print('Failed to play web background music: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 일시정지
  Future<void> pause() async {
    _audioElement?.pause();
    _isPlaying = false;
  }

  /// 배경음악 재개
  Future<void> resume() async {
    if (!_isMusicEnabled || _audioElement == null) return;
    try {
      await _audioElement!.play();
      _isPlaying = true;
    } catch (e) {
      print('Failed to resume: $e');
    }
  }

  /// 배경음악 정지
  Future<void> stop() async {
    _audioElement?.pause();
    if (_audioElement != null) {
      _audioElement!.currentTime = 0;
    }
    _isPlaying = false;
  }

  /// 음악 토글 (켜기/끄기)
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, _isMusicEnabled);

    if (_isMusicEnabled) {
      await play();
    } else {
      await stop();
    }
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioElement != null) {
      _audioElement!.volume = _volume;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _volume);
  }

  /// 현재 음악 활성화 상태
  bool get isMusicEnabled => _isMusicEnabled;

  /// 현재 볼륨
  double get volume => _volume;

  /// 현재 재생 중인지 여부
  bool get isPlaying => _isPlaying;

  /// 리소스 정리
  void dispose() {
    _audioElement?.pause();
    _audioElement = null;
    _isInitialized = false;
  }
}
