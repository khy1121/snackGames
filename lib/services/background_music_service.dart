import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 배경음악 관리 서비스
class BackgroundMusicService {
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  static const String _musicEnabledKey = 'music_enabled';
  static const String _musicVolumeKey = 'music_volume';
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isMusicEnabled = true;
  double _volume = 0.3; // 기본 볼륨 30%
  bool _isPlaying = false;

  /// 서비스 초기화 및 설정 로드
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
    _volume = prefs.getDouble(_musicVolumeKey) ?? 0.3;

    // 무한 반복 설정
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(_volume);

    // 웹이 아닌 경우에만 자동 재생 (웹은 사용자 상호작용 필요)
    if (!kIsWeb && _isMusicEnabled) {
      await play();
    }

    _isInitialized = true;
  }

  /// 배경음악 재생
  Future<void> play() async {
    if (!_isMusicEnabled || _isPlaying) return;
    
    try {
      await _audioPlayer.play(AssetSource('audio/mainLogo.mp3'));
      _isPlaying = true;
      print('Background music started');
    } catch (e) {
      print('Failed to play background music: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 일시정지
  Future<void> pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  /// 배경음악 재개
  Future<void> resume() async {
    if (!_isMusicEnabled) return;
    await _audioPlayer.resume();
    _isPlaying = true;
  }

  /// 배경음악 정지
  Future<void> stop() async {
    await _audioPlayer.stop();
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
    await _audioPlayer.setVolume(_volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _volume);
  }

  /// 현재 음악 활성화 상태
  bool get isMusicEnabled => _isMusicEnabled;

  /// 현재 볼륨
  double get volume => _volume;
  
  /// 현재 재생 중인지 여부
  Future<bool> get isPlaying async {
    final state = await _audioPlayer.state;
    return state == PlayerState.playing;
  }

  /// 현재 재생 상태
  Future<PlayerState> get state async => _audioPlayer.state;

  /// 리소스 정리
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isInitialized = false;
  }
}
