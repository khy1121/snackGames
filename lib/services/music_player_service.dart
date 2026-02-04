import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}

/// 반복 모드
enum RepeatMode {
  none,      // 반복 없음
  all,       // 전체 반복
  one,       // 한 곡 반복
}

/// 음악 플레이어 서비스 (플레이리스트 지원)
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
      // 기본 플레이리스트: mainLogo만
      _playlist = [availableTracks.first];
    }

    final savedRepeatMode = prefs.getInt('repeat_mode') ?? 1;
    _repeatMode = RepeatMode.values[savedRepeatMode];
    
    _shuffle = prefs.getBool('shuffle') ?? false;
    
    _isInitialized = true;
    notifyListeners();
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
      _isPlaying = true;
      notifyListeners();
      // 실제 오디오 재생은 WebAudioService에서 처리
    }
  }

  /// 재생/일시정지 토글
  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  /// 재생
  void play() {
    if (_playlist.isEmpty) return;
    _isPlaying = true;
    notifyListeners();
  }

  /// 일시정지
  void pause() {
    _isPlaying = false;
    notifyListeners();
  }

  /// 정지
  void stop() {
    _isPlaying = false;
    _currentIndex = 0;
    notifyListeners();
  }

  /// 다음 곡
  void next() {
    if (_playlist.isEmpty) return;
    
    if (_shuffle) {
      _currentIndex = (_currentIndex + 1 + DateTime.now().millisecond) % _playlist.length;
    } else {
      _currentIndex++;
      if (_currentIndex >= _playlist.length) {
        if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        } else {
          _currentIndex = _playlist.length - 1;
          _isPlaying = false;
        }
      }
    }
    notifyListeners();
  }

  /// 이전 곡
  void previous() {
    if (_playlist.isEmpty) return;
    
    _currentIndex--;
    if (_currentIndex < 0) {
      if (_repeatMode == RepeatMode.all) {
        _currentIndex = _playlist.length - 1;
      } else {
        _currentIndex = 0;
      }
    }
    notifyListeners();
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
    if (!_isMusicEnabled) {
      _isPlaying = false;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_enabled', _isMusicEnabled);
    notifyListeners();
  }

  /// 볼륨 설정
  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('music_volume', _volume);
    notifyListeners();
  }

  /// 플레이리스트 저장
  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('playlist_ids', _playlist.map((t) => t.id).toList());
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
