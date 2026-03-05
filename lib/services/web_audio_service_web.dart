// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// 웹 전용 배경음악 서비스 (HTML5 Audio API 사용)
class WebAudioService {
  static final WebAudioService _instance = WebAudioService._internal();
  factory WebAudioService() => _instance;
  WebAudioService._internal();

  html.AudioElement? _audioElement;
  bool _isInitialized = false;
  double _volume = 0.3;
  bool _isPlaying = false;
  bool _loopMode = false;
  String _currentTrackPath = 'audio/main_logo.mp3';
  
  void Function()? _onTrackEnded;
  void Function(Duration currentTime, Duration duration)? _onTimeUpdate;

  void setOnTrackEnded(void Function() callback) {
    _onTrackEnded = callback;
  }
  
  void setOnTimeUpdate(void Function(Duration currentTime, Duration duration) callback) {
    _onTimeUpdate = callback;
  }

  void setLoopMode(bool loop) {
    _loopMode = loop;
    if (_audioElement != null) {
      _audioElement!.loop = loop;
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _audioElement = html.AudioElement()
        ..src = _currentTrackPath
        ..loop = _loopMode
        ..volume = _volume;
      
      _audioElement!.preload = 'auto';
      
      _audioElement!.onEnded.listen((_) {
        _isPlaying = false;
        if (!_loopMode && _onTrackEnded != null) {
          _onTrackEnded!();
        }
      });

      _audioElement!.onError.listen((event) {
        _isPlaying = false;
      });

      _audioElement!.onCanPlay.listen((_) {});
      
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

  Future<void> changeTrack(String fileName) async {
    final newPath = 'audio/$fileName';
    if (_currentTrackPath == newPath && _audioElement != null) return;
    
    _currentTrackPath = newPath;
    
    if (_audioElement != null) {
      final wasPlaying = _isPlaying;
      _audioElement!.pause();
      _isPlaying = false;
      
      _audioElement!.src = newPath;
      _audioElement!.loop = _loopMode;
      _audioElement!.load();
      
      if (wasPlaying) {
        await Future.delayed(const Duration(milliseconds: 300));
        await play();
      }
    }
  }

  Future<bool> play() async {
    if (_audioElement == null) return false;
    if (_isPlaying) return true;

    try {
      if (_audioElement!.readyState < 2) {
        _audioElement!.load();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      await _audioElement!.play();
      _isPlaying = true;
      return true;
    } catch (e) {
      _isPlaying = false;
      return false;
    }
  }

  Future<void> pause() async {
    _audioElement?.pause();
    _isPlaying = false;
  }

  Future<void> resume() async {
    if (_audioElement == null) return;
    try {
      await _audioElement!.play();
      _isPlaying = true;
    } catch (e) {}
  }

  Future<void> stop() async {
    _audioElement?.pause();
    if (_audioElement != null) {
      _audioElement!.currentTime = 0;
    }
    _isPlaying = false;
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    if (_audioElement != null) {
      _audioElement!.volume = _volume;
    }
  }

  double get volume => _volume;
  bool get isPlaying => _isPlaying;
  String get currentTrackPath => _currentTrackPath;
  
  Duration get currentTime {
    if (_audioElement == null) return Duration.zero;
    return Duration(seconds: _audioElement!.currentTime.toInt());
  }
  
  Duration get duration {
    if (_audioElement == null || !_audioElement!.duration.isFinite) {
      return const Duration(minutes: 3, seconds: 30);
    }
    return Duration(seconds: _audioElement!.duration.toInt());
  }
  
  void seek(Duration position) {
    if (_audioElement != null) {
      _audioElement!.currentTime = position.inSeconds.toDouble();
    }
  }

  void dispose() {
    _audioElement?.pause();
    _audioElement = null;
    _isInitialized = false;
    _onTrackEnded = null;
  }
}
