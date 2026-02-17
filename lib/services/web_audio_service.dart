// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 웹 전용 배경음악 서비스 (HTML5 Audio API 사용)
/// MusicPlayerService에서 호출하는 저수준 오디오 API
class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  html.AudioElement? _audioElement;
  bool _isInitialized = false;
  double _volume = 0.3;
  bool _isPlaying = false;
  bool _loopMode = false;
  String _currentTrackPath = 'assets/assets/audio/main_logo.mp3';
  
  // 트랙 종료 콜백
  void Function()? _onTrackEnded;
  
  // 시간 업데이트 콜백
  void Function(Duration currentTime, Duration duration)? _onTimeUpdate;

  /// 트랙 종료 콜백 설정
  void setOnTrackEnded(void Function() callback) {
    _onTrackEnded = callback;
  }
  
  /// 시간 업데이트 콜백 설정
  void setOnTimeUpdate(void Function(Duration currentTime, Duration duration) callback) {
    _onTimeUpdate = callback;
  }

  /// 루프 모드 설정 (한 곡 반복)
  void setLoopMode(bool loop) {
    _loopMode = loop;
    if (_audioElement != null) {
      _audioElement!.loop = loop;
    }
  }

  /// 서비스 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // HTML5 Audio 요소 생성
      _audioElement = html.AudioElement()
        ..src = _currentTrackPath
        ..loop = _loopMode
        ..volume = _volume;
      
      // preload 설정
      _audioElement!.preload = 'auto';
      
      // 트랙 종료 시 이벤트
      _audioElement!.onEnded.listen((_) {
        _isPlaying = false;
        // 루프 모드가 아닐 때만 콜백 호출
        if (!_loopMode && _onTrackEnded != null) {
          _onTrackEnded!();
        }
      });

      // 에러 이벤트 핸들러
      _audioElement!.onError.listen((event) {
        _isPlaying = false;
      });

      // canplay 이벤트 핸들러
      _audioElement!.onCanPlay.listen((_) {
        // 준비 완료
      });
      
      // 시간 업데이트 이벤트 핸들러
      _audioElement!.onTimeUpdate.listen((_) {
        if (_onTimeUpdate != null && _audioElement != null) {
          final currentTime = Duration(seconds: _audioElement!.currentTime.toInt());
          final duration = Duration(seconds: _audioElement!.duration.isFinite ? _audioElement!.duration.toInt() : 0);
          _onTimeUpdate!(currentTime, duration);
        }
      });

      _isInitialized = true;
    } catch (e) {
      _isInitialized = true;
    }
  }

  /// 트랙 변경
  Future<void> changeTrack(String fileName) async {
    final newPath = 'assets/assets/audio/$fileName';
    
    // 같은 트랙이면 무시
    if (_currentTrackPath == newPath && _audioElement != null) {
      return;
    }
    
    _currentTrackPath = newPath;
    
    if (_audioElement != null) {
      final wasPlaying = _isPlaying;
      
      // 현재 재생 중지
      _audioElement!.pause();
      _isPlaying = false;
      
      // 새 트랙 설정
      _audioElement!.src = newPath;
      _audioElement!.loop = _loopMode;
      _audioElement!.load();
      
      // 이전에 재생 중이었다면 다시 재생
      if (wasPlaying) {
        await Future.delayed(const Duration(milliseconds: 300));
        await play();
      }
    }
  }

  /// 배경음악 재생 (성공 여부 반환)
  Future<bool> play() async {
    if (_audioElement == null) {
      print('[WebAudio] play failed: audioElement is null');
      return false;
    }
    if (_isPlaying) return true;

    try {
      // 오디오 로드 확인
      if (_audioElement!.readyState < 2) {
        _audioElement!.load();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      await _audioElement!.play();
      _isPlaying = true;
      print('[WebAudio] play success: $_currentTrackPath');
      return true;
    } catch (e) {
      print('[WebAudio] play failed: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// 배경음악 일시정지
  Future<void> pause() async {
    _audioElement?.pause();
    _isPlaying = false;
  }

  /// 배경음악 재개
  Future<void> resume() async {
    if (_audioElement == null) return;
    try {
      await _audioElement!.play();
      _isPlaying = true;
    } catch (e) {
      // 무시
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

  /// 볼륨 설정 (0.0 ~ 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioElement != null) {
      _audioElement!.volume = _volume;
    }
  }

  /// 현재 볼륨
  double get volume => _volume;

  /// 현재 재생 중인지 여부
  bool get isPlaying => _isPlaying;

  /// 현재 트랙 경로
  String get currentTrackPath => _currentTrackPath;
  
  /// 현재 재생 위치
  Duration get currentTime {
    if (_audioElement == null) return Duration.zero;
    return Duration(seconds: _audioElement!.currentTime.toInt());
  }
  
  /// 트랙 총 길이
  Duration get duration {
    if (_audioElement == null || !_audioElement!.duration.isFinite) {
      return const Duration(minutes: 3, seconds: 30); // 기본값
    }
    return Duration(seconds: _audioElement!.duration.toInt());
  }
  
  /// 재생 위치 변경 (시크)
  void seek(Duration position) {
    if (_audioElement != null) {
      _audioElement!.currentTime = position.inSeconds.toDouble();
    }
  }

  /// 리소스 정리
  void dispose() {
    _audioElement?.pause();
    _audioElement = null;
    _isInitialized = false;
    _onTrackEnded = null;
  }
}
