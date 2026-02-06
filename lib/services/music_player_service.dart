import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_audio_service.dart' if (dart.library.io) 'web_audio_stub.dart';

/// 음악 트랙 정보
class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String fileName;
  final Duration? duration;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileName,
    this.duration,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'fileName': fileName,
  };

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      fileName: json['fileName'] as String,
    );
  }
}

/// 반복 모드
enum RepeatMode {
  none,      // 반복 없음
  all,       // 전체 반복
  one,       // 한 곡 반복
}

/// 통합 음악 플레이어 서비스 (플레이리스트 + 실제 재생 관리)
class MusicPlayerService extends ChangeNotifier {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  MusicPlayerService._internal();

  // 사용 가능한 모든 트랙
  static const List<MusicTrack> availableTracks = [
    MusicTrack(
      id: 'mainLogo',
      title: 'Main Theme',
      artist: 'Snack Games',
      fileName: 'mainLogo.mp3',
    ),
    MusicTrack(
      id: 'breaktime_hush',
      title: 'Breaktime Hush Duo',
      artist: 'Snack Games',
      fileName: 'Breaktime Hush Duo.mp3',
    ),
    MusicTrack(
      id: 'pocket_groove',
      title: 'Pocket Groove Snack',
      artist: 'Snack Games',
      fileName: 'Pocket Groove Snack.mp3',
    ),
    MusicTrack(
      id: 'soft_breaktime',
      title: 'Soft Breaktime Glow',
      artist: 'Snack Games',
      fileName: 'Soft Breaktime Glow.mp3',
    ),
    MusicTrack(
      id: 'subway_home',
      title: 'Subway Home, One Breath',
      artist: 'Snack Games',
      fileName: 'Subway Home, One Breath.mp3',
    ),
    MusicTrack(
      id: 'one_more_round',
      title: 'One More Round',
      artist: 'Snack Games',
      fileName: 'One More Round.mp3',
    ),
  ];

  // 현재 플레이리스트
  List<MusicTrack> _playlist = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isMusicEnabled = true;
  RepeatMode _repeatMode = RepeatMode.all;
  bool _shuffle = false;
  double _volume = 0.3;
  bool _isInitialized = false;
  bool _userInteracted = false;

  // Getters
  List<MusicTrack> get playlist => _playlist;
  List<MusicTrack> get allTracks => availableTracks;
  MusicTrack? get currentTrack => _playlist.isNotEmpty && _currentIndex < _playlist.length 
      ? _playlist[_currentIndex] 
      : null;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isMusicEnabled => _isMusicEnabled;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  double get volume => _volume;
  bool get isInitialized => _isInitialized;
  
  /// 웹 오디오 서비스 접근 (UI에서 시간 정보 가져오기 위해)
  WebAudioService? get webAudioService {
    if (kIsWeb) {
      return WebAudioService();
    }
    return null;
  }

  /// 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _isMusicEnabled = prefs.getBool('music_enabled') ?? true;
    _volume = prefs.getDouble('music_volume') ?? 0.3;
    
    // 저장된 플레이리스트 로드 또는 기본값 설정
    final savedPlaylist = prefs.getStringList('playlist_ids');
    if (savedPlaylist != null && savedPlaylist.isNotEmpty) {
      _playlist = savedPlaylist
          .map((id) => availableTracks.firstWhere(
                (t) => t.id == id,
                orElse: () => availableTracks.first,
              ))
          .toList();
    } else {
      // 기본 플레이리스트: 모든 트랙
      _playlist = List.from(availableTracks);
    }

    // 저장된 현재 트랙 인덱스 로드
    _currentIndex = prefs.getInt('current_track_index') ?? 0;
    if (_currentIndex >= _playlist.length) {
      _currentIndex = 0;
    }

    final savedRepeatMode = prefs.getInt('repeat_mode') ?? 1;
    _repeatMode = RepeatMode.values[savedRepeatMode];
    
    _shuffle = prefs.getBool('shuffle') ?? false;

    // 웹에서 WebAudioService 초기화 및 트랙 동기화
    if (kIsWeb) {
      final webAudio = WebAudioService();
      await webAudio.initialize();
      webAudio.setVolume(_volume);
      
      // 현재 트랙으로 설정
      if (currentTrack != null) {
        await webAudio.changeTrack(currentTrack!.fileName);
      }
      
      // 트랙 종료 콜백 설정
      webAudio.setOnTrackEnded(_onTrackEnded);
      
      // 시간 업데이트 콜백 설정 (UI 업데이트용)
      webAudio.setOnTimeUpdate((currentTime, duration) {
        // 필요시 notifyListeners() 호출
      });
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// 사용자 상호작용 시 호출 (자동재생 정책 대응)
  Future<void> onUserInteraction() async {
    if (_userInteracted) return;
    _userInteracted = true;

    if (_isMusicEnabled && !_isPlaying) {
      await play();
    }
  }

  /// 트랙 종료 시 호출
  void _onTrackEnded() {
    if (_repeatMode == RepeatMode.one) {
      // 한 곡 반복: 같은 트랙 재생
      _playCurrentTrack();
    } else {
      // 다음 곡으로 이동
      next();
    }
  }

  /// 플레이리스트에 트랙 추가
  Future<void> addToPlaylist(MusicTrack track) async {
    if (!_playlist.any((t) => t.id == track.id)) {
      _playlist.add(track);
      await _savePlaylist();
      notifyListeners();
    }
  }

  /// 플레이리스트에서 트랙 제거
  Future<void> removeFromPlaylist(MusicTrack track) async {
    final index = _playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _playlist.removeAt(index);
      if (_currentIndex >= _playlist.length && _playlist.isNotEmpty) {
        _currentIndex = _playlist.length - 1;
      }
      await _savePlaylist();
      notifyListeners();
    }
  }

  /// 트랙이 플레이리스트에 있는지 확인
  bool isInPlaylist(MusicTrack track) {
    return _playlist.any((t) => t.id == track.id);
  }

  /// 특정 트랙 재생
  Future<void> playTrack(MusicTrack track) async {
    final index = _playlist.indexWhere((t) => t.id == track.id);
    if (index != -1) {
      _currentIndex = index;
      await _saveCurrentIndex();
      await _playCurrentTrack();
    }
  }

  /// 현재 트랙 실제 재생
  Future<void> _playCurrentTrack() async {
    if (!_isMusicEnabled || _playlist.isEmpty) {
      print('Cannot play: musicEnabled=$_isMusicEnabled, playlist=${_playlist.length}');
      return;
    }
    
    final track = currentTrack;
    if (track == null) {
      print('Cannot play: currentTrack is null');
      return;
    }

    print('Playing track: ${track.title} (${track.fileName})');

    if (kIsWeb) {
      final webAudio = WebAudioService();
      await webAudio.changeTrack(track.fileName);
      await webAudio.play();
    } else {
      // 모바일: BackgroundMusicService 사용 (추후 구현)
    }
    
    _isPlaying = true;
    notifyListeners();
  }

  /// 재생/일시정지 토글
  Future<void> togglePlay() async {
    print('togglePlay called: isPlaying=$_isPlaying');
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// 재생
  Future<void> play() async {
    print('play() called: playlist=${_playlist.length}, musicEnabled=$_isMusicEnabled');
    
    if (_playlist.isEmpty) {
      print('Playlist is empty, cannot play');
      return;
    }
    
    if (!_isMusicEnabled) {
      print('Music is disabled');
      return;
    }
    
    if (kIsWeb) {
      final webAudio = WebAudioService();
      if (currentTrack != null) {
        print('Changing track to: ${currentTrack!.fileName}');
        await webAudio.changeTrack(currentTrack!.fileName);
      }
      await webAudio.play();
    }
    
    _isPlaying = true;
    notifyListeners();
  }

  /// 일시정지
  Future<void> pause() async {
    if (kIsWeb) {
      await WebAudioService().pause();
    }
    
    _isPlaying = false;
    notifyListeners();
  }

  /// 정지
  Future<void> stop() async {
    if (kIsWeb) {
      await WebAudioService().stop();
    }
    
    _isPlaying = false;
    _currentIndex = 0;
    notifyListeners();
  }

  /// 다음 곡
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    
    if (_shuffle) {
      // 셔플: 랜덤 트랙 선택 (현재 트랙 제외)
      if (_playlist.length > 1) {
        int newIndex;
        do {
          newIndex = DateTime.now().millisecond % _playlist.length;
        } while (newIndex == _currentIndex);
        _currentIndex = newIndex;
      }
    } else {
      _currentIndex++;
      if (_currentIndex >= _playlist.length) {
        if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        } else if (_repeatMode == RepeatMode.none) {
          _currentIndex = _playlist.length - 1;
          _isPlaying = false;
          notifyListeners();
          return;
        }
      }
    }
    
    await _saveCurrentIndex();
    await _playCurrentTrack();
  }

  /// 이전 곡
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    
    _currentIndex--;
    if (_currentIndex < 0) {
      if (_repeatMode == RepeatMode.all || _repeatMode == RepeatMode.one) {
        _currentIndex = _playlist.length - 1;
      } else {
        _currentIndex = 0;
      }
    }
    
    await _saveCurrentIndex();
    await _playCurrentTrack();
  }

  /// 반복 모드 변경
  Future<void> toggleRepeatMode() async {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
        break;
    }
    
    // WebAudioService 루프 모드 업데이트
    if (kIsWeb) {
      WebAudioService().setLoopMode(_repeatMode == RepeatMode.one);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('repeat_mode', _repeatMode.index);
    notifyListeners();
  }

  /// 셔플 토글
  Future<void> toggleShuffle() async {
    _shuffle = !_shuffle;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shuffle', _shuffle);
    notifyListeners();
  }

  /// 음악 활성화 토글
  Future<void> toggleMusic() async {
    _isMusicEnabled = !_isMusicEnabled;
    
    if (_isMusicEnabled) {
      await play();
    } else {
      await stop();
      _isPlaying = false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _isMusicEnabled);
    notifyListeners();
  }

  /// 볼륨 설정
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    
    if (kIsWeb) {
      await WebAudioService().setVolume(_volume);
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _volume);
    notifyListeners();
  }

  /// 플레이리스트 저장
  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist_ids', _playlist.map((t) => t.id).toList());
  }

  /// 현재 인덱스 저장
  Future<void> _saveCurrentIndex() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_track_index', _currentIndex);
  }

  /// 현재 트랙의 파일 경로 (웹용)
  String get currentTrackPath {
    if (currentTrack == null) return '';
    if (kIsWeb) {
      return 'audio/${currentTrack!.fileName}';
    }
    return 'audio/${currentTrack!.fileName}';
  }
}
