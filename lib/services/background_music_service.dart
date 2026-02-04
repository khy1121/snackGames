import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_audio_service.dart' if (dart.library.io) 'web_audio_stub.dart';

/// 배경음악 관리 서비스
class BackgroundMusicService {
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  static const String _musicEnabledKey = 'music_enabled';
  static const String _musicVolumeKey = 'music_volume';
  
  // 웹이 아닐 때만 AudioPlayer 생성 (lazy initialization)
  AudioPlayer? _audioPlayer;
  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }
  
  bool _isInitialized = false;
  bool _isMusicEnabled = true;
  double _volume = 0.3; // 기본 볼륨 30%
  bool _isPlaying = false;

  /// 서비스 초기화 및 설정 로드
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 웹에서는 WebAudioService 사용
    if (kIsWeb) {
      await WebAudioService().initialize();
      _isInitialized = true;
      _isMusicEnabled = WebAudioService().isMusicEnabled;
      print('Using WebAudioService for web platform');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _volume = prefs.getDouble(_musicVolumeKey) ?? 0.3;

      // 무한 반복 설정
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.setVolume(_volume);

      // 모바일에서만 자동 재생
      if (_isMusicEnabled) {
        await play();
      }

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize background music service: $e');
      _isInitialized = true; // 에러가 나도 다시 초기화 시도 방지
    }
  }

  /// 배경음악 재생
  Future<void> play() async {
    if (kIsWeb) {
      await WebAudioService().play();
      return;
    }
    
    if (!_isMusicEnabled || _isPlaying) return;
    
    try {
      await audioPlayer.play(AssetSource('audio/mainLogo.mp3'));
      _isPlaying = true;
      print('Background music started');
    } catch (e) {
      print('Failed to play background music: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 일시정지
  Future<void> pause() async {
    if (kIsWeb) {
      await WebAudioService().pause();
      return;
    }
    await audioPlayer.pause();
    _isPlaying = false;
  }

  /// 배경음악 재개
  Future<void> resume() async {
    if (kIsWeb) {
      await WebAudioService().resume();
      return;
    }
    if (!_isMusicEnabled) return;
    await audioPlayer.resume();
    _isPlaying = true;
  }

  /// 배경음악 정지
  Future<void> stop() async {
    if (kIsWeb) {
      await WebAudioService().stop();
      return;
    }
    await audioPlayer.stop();
    _isPlaying = false;
  }

  /// 음악 토글 (켜기/끄기)
  Future<void> toggleMusic() async {
    if (kIsWeb) {
      await WebAudioService().toggleMusic();
      _isMusicEnabled = WebAudioService().isMusicEnabled;
      return;
    }
    
    _isMusicEnabled = !_isMusicEnabled;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_musicEnabledKey, _isMusicEnabled);

    if (_isMusicEnabled) {
      await play();
    } else {
      await stop();
    }
  }

  /// 웹에서 사용자 상호작용 시 호출
  Future<void> onUserInteraction() async {
    if (kIsWeb) {
      await WebAudioService().onUserInteraction();
    }
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    if (kIsWeb) {
      await WebAudioService().setVolume(volume);
      return;
    }
    _volume = volume.clamp(0.0, 1.0);
    await audioPlayer.setVolume(_volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _volume);
  }

  /// 현재 음악 활성화 상태
  bool get isMusicEnabled {
    if (kIsWeb) return WebAudioService().isMusicEnabled;
    return _isMusicEnabled;
  }

  /// 현재 볼륨
  double get volume {
    if (kIsWeb) return WebAudioService().volume;
    return _volume;
  }
  
  /// 현재 재생 중인지 여부
  bool get isPlayingSync {
    if (kIsWeb) return WebAudioService().isPlaying;
    return _isPlaying;
  }

  /// 현재 재생 상태 (async)
  Future<PlayerState> get state async => audioPlayer.state;

  /// 리소스 정리
  Future<void> dispose() async {
    if (kIsWeb) {
      WebAudioService().dispose();
      return;
    }
    await audioPlayer.dispose();
    _isInitialized = false;
  }
}
