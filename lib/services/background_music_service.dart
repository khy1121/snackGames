import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'music_player_service.dart';

/// 배경음악 관리 서비스 (모바일 전용 - 웹은 MusicPlayerService에서 직접 WebAudioService 사용)
/// 
/// 이 서비스는 레거시 호환성을 위해 유지되며,
/// 실제 음악 재생 로직은 MusicPlayerService로 통합되었습니다.
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
  double _volume = 0.3;
  bool _isPlaying = false;
  String _currentTrack = 'audio/mainLogo.mp3';

  /// 서비스 초기화 및 설정 로드
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // 웹에서는 MusicPlayerService가 직접 WebAudioService 사용
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _isMusicEnabled = prefs.getBool(_musicEnabledKey) ?? true;
      _volume = prefs.getDouble(_musicVolumeKey) ?? 0.3;

      // 무한 반복 설정 해제 (MusicPlayerService에서 관리)
      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      await audioPlayer.setVolume(_volume);

      // 트랙 종료 시 다음 곡으로 이동
      audioPlayer.onPlayerComplete.listen((_) {
        _isPlaying = false;
        // MusicPlayerService에 알림
        MusicPlayerService().next();
      });

      _isInitialized = true;
    } catch (e) {
      print('Failed to initialize background music service: $e');
      _isInitialized = true;
    }
  }

  /// 특정 트랙 재생
  Future<void> playTrack(String fileName) async {
    if (kIsWeb) return;
    
    final trackPath = 'audio/$fileName';
    if (_currentTrack == trackPath && _isPlaying) return;
    
    _currentTrack = trackPath;
    
    try {
      await audioPlayer.stop();
      await audioPlayer.play(AssetSource(trackPath));
      _isPlaying = true;
      print('Playing track: $fileName');
    } catch (e) {
      print('Failed to play track: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 재생
  Future<void> play() async {
    if (kIsWeb) return;
    if (!_isMusicEnabled || _isPlaying) return;
    
    try {
      await audioPlayer.play(AssetSource(_currentTrack));
      _isPlaying = true;
      print('Background music started');
    } catch (e) {
      print('Failed to play background music: $e');
      _isPlaying = false;
    }
  }

  /// 배경음악 일시정지
  Future<void> pause() async {
    if (kIsWeb) return;
    await audioPlayer.pause();
    _isPlaying = false;
  }

  /// 배경음악 재개
  Future<void> resume() async {
    if (kIsWeb) return;
    if (!_isMusicEnabled) return;
    await audioPlayer.resume();
    _isPlaying = true;
  }

  /// 배경음악 정지
  Future<void> stop() async {
    if (kIsWeb) return;
    await audioPlayer.stop();
    _isPlaying = false;
  }

  /// 음악 토글 (켜기/끄기)
  Future<void> toggleMusic() async {
    if (kIsWeb) {
      // 웹에서는 MusicPlayerService 사용
      await MusicPlayerService().toggleMusic();
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
      await MusicPlayerService().onUserInteraction();
    }
  }

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    if (kIsWeb) {
      await MusicPlayerService().setVolume(volume);
      return;
    }
    _volume = volume.clamp(0.0, 1.0);
    await audioPlayer.setVolume(_volume);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_musicVolumeKey, _volume);
  }

  /// 현재 음악 활성화 상태
  bool get isMusicEnabled {
    if (kIsWeb) return MusicPlayerService().isMusicEnabled;
    return _isMusicEnabled;
  }

  /// 현재 볼륨
  double get volume {
    if (kIsWeb) return MusicPlayerService().volume;
    return _volume;
  }
  
  /// 현재 재생 중인지 여부
  bool get isPlayingSync {
    if (kIsWeb) return MusicPlayerService().isPlaying;
    return _isPlaying;
  }

  /// 현재 재생 상태 (async)
  Future<PlayerState> get state async => audioPlayer.state;

  /// 리소스 정리
  Future<void> dispose() async {
    if (kIsWeb) return;
    await audioPlayer.dispose();
    _isInitialized = false;
  }
}
