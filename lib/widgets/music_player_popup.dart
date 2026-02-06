import 'package:flutter/material.dart';
import '../services/music_player_service.dart';

/// 심플한 음악 플레이어 팝업 (토글 스위치 방식)
class MusicPlayerPopup extends StatefulWidget {
  const MusicPlayerPopup({super.key});

  @override
  State<MusicPlayerPopup> createState() => _MusicPlayerPopupState();
}

class _MusicPlayerPopupState extends State<MusicPlayerPopup> {
  final MusicPlayerService _playerService = MusicPlayerService();
  
  // 재생 진행률 (0.0 ~ 1.0)
  double _progress = 0.0;
  Duration _currentPosition = Duration.zero;
  Duration _trackDuration = const Duration(minutes: 3, seconds: 30); // 기본값

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerChanged);
    _updateAudioTime();
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) {
      _updateAudioTime();
      setState(() {});
    }
  }

  // 실제 오디오 시간 업데이트
  void _updateAudioTime() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return false;
      
      if (_playerService.isPlaying) {
        final webAudio = _playerService.webAudioService;
        if (webAudio != null) {
          setState(() {
            _currentPosition = webAudio.currentTime;
            _trackDuration = webAudio.duration;
            if (_trackDuration.inSeconds > 0) {
              _progress = _currentPosition.inSeconds / _trackDuration.inSeconds;
            }
          });
        }
      }
      return true;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 핸들 바
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더 (컴팩트)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎵 뮤직 플레이어',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // 현재 재생 중인 트랙 (컴팩트)
          _buildNowPlaying(),
          
          // 프로그레스 바
          _buildProgressBar(),
          
          // 플레이어 컨트롤 (컴팩트)
          _buildPlayerControls(),
          
          // 구분선
          Divider(color: Colors.grey[700], height: 1),
          
          // 플레이리스트 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '플레이리스트',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_playerService.playlist.length}곡',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 트랙 리스트 (확장됨)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: MusicPlayerService.availableTracks.length,
              itemBuilder: (context, index) {
                final track = MusicPlayerService.availableTracks[index];
                final isInPlaylist = _playerService.isInPlaylist(track);
                final isCurrentTrack = _playerService.currentTrack?.id == track.id;
                
                return _buildTrackTile(
                  track: track,
                  isInPlaylist: isInPlaylist,
                  isCurrentTrack: isCurrentTrack,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    final track = _playerService.currentTrack;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B894).withValues(alpha: 0.3),
            const Color(0xFF00CEC9).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 앨범 아트 (작은 사이즈)
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          
          // 트랙 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title ?? '선택된 곡 없음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track?.artist ?? 'Snack Games',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 재생 상태 표시
          if (_playerService.isPlaying)
            const _PlayingAnimation(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // 프로그레스 슬라이더
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00B894),
              inactiveTrackColor: Colors.grey[700],
              thumbColor: const Color(0xFF00B894),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  seconds: (value * _trackDuration.inSeconds).round(),
                );
                _playerService.webAudioService?.seek(newPosition);
                setState(() {
                  _progress = value;
                  _currentPosition = newPosition;
                });
              },
            ),
          ),
          // 시간 표시
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_currentPosition),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
                Text(
                  _formatDuration(_trackDuration),
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          // 볼륨 슬라이더
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.grey, size: 18),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00B894),
                    inactiveTrackColor: Colors.grey[700],
                    thumbColor: const Color(0xFF00B894),
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  ),
                  child: Slider(
                    value: _playerService.volume,
                    onChanged: (value) => _playerService.setVolume(value),
                  ),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.grey, size: 18),
            ],
          ),
          
          // 메인 컨트롤 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 셔플
              IconButton(
                onPressed: () => _playerService.toggleShuffle(),
                icon: Icon(
                  Icons.shuffle,
                  size: 22,
                  color: _playerService.shuffle 
                      ? const Color(0xFF00B894) 
                      : Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              // 이전 곡
              IconButton(
                onPressed: () {
                  _playerService.previous();
                  _resetProgress();
                },
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              // 재생/일시정지
              GestureDetector(
                onTap: () => _playerService.togglePlay(),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B894),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              
              // 다음 곡
              IconButton(
                onPressed: () {
                  _playerService.next();
                  _resetProgress();
                },
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 28,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              
              // 반복 모드
              IconButton(
                onPressed: () => _playerService.toggleRepeatMode(),
                icon: Icon(
                  _getRepeatIcon(),
                  size: 22,
                  color: _playerService.repeatMode != RepeatMode.none 
                      ? const Color(0xFF00B894) 
                      : Colors.grey,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _resetProgress() {
    setState(() {
      _progress = 0.0;
      _currentPosition = Duration.zero;
    });
  }

  IconData _getRepeatIcon() {
    switch (_playerService.repeatMode) {
      case RepeatMode.none:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  Widget _buildTrackTile({
    required MusicTrack track,
    required bool isInPlaylist,
    required bool isCurrentTrack,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrentTrack 
            ? const Color(0xFF00B894).withValues(alpha: 0.2)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
        border: isCurrentTrack 
            ? Border.all(color: const Color(0xFF00B894), width: 1)
            : null,
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: () {
          if (isInPlaylist) {
            _playerService.playTrack(track);
          } else {
            _playerService.addToPlaylist(track);
            _playerService.playTrack(track);
          }
          _resetProgress();
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrentTrack 
                ? const Color(0xFF00B894) 
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCurrentTrack && _playerService.isPlaying 
                ? Icons.equalizer 
                : Icons.music_note,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isCurrentTrack ? const Color(0xFF00B894) : Colors.white,
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: TextStyle(color: Colors.grey[500], fontSize: 11),
        ),
        // 온/오프 토글 스위치
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch(
            value: isInPlaylist,
            onChanged: (value) {
              if (value) {
                _playerService.addToPlaylist(track);
              } else {
                _playerService.removeFromPlaylist(track);
              }
            },
            activeColor: const Color(0xFF00B894),
            activeTrackColor: const Color(0xFF00B894).withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey[600],
            inactiveTrackColor: Colors.grey[800],
          ),
        ),
      ),
    );
  }
}

/// 재생 중 애니메이션
class _PlayingAnimation extends StatefulWidget {
  const _PlayingAnimation();

  @override
  State<_PlayingAnimation> createState() => _PlayingAnimationState();
}

class _PlayingAnimationState extends State<_PlayingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = ((_controller.value + delay) % 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 3,
              height: 8 + (value * 10),
              decoration: BoxDecoration(
                color: const Color(0xFF00B894),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        );
      },
    );
  }
}

/// 플레이어 팝업 표시 함수
void showMusicPlayerPopup(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (context) => const MusicPlayerPopup(),
  );
}
