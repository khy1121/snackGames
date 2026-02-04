import 'package:flutter/material.dart';
import '../services/music_player_service.dart';

/// 멜론/플로 스타일 음악 플레이어 팝업
class MusicPlayerPopup extends StatefulWidget {
  const MusicPlayerPopup({super.key});

  @override
  State<MusicPlayerPopup> createState() => _MusicPlayerPopupState();
}

class _MusicPlayerPopupState extends State<MusicPlayerPopup> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MusicPlayerService _playerService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _playerService.addListener(_onPlayerChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _playerService.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
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
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🎵 뮤직 플레이어',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // 현재 재생 중인 트랙
          _buildNowPlaying(),
          
          // 플레이어 컨트롤
          _buildPlayerControls(),
          
          const SizedBox(height: 8),
          
          // 탭 바
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF00B894),
            labelColor: const Color(0xFF00B894),
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: '플레이리스트'),
              Tab(text: '전체 음악'),
            ],
          ),
          
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlaylistTab(),
                _buildAllTracksTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlaying() {
    final track = _playerService.currentTrack;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00B894).withValues(alpha: 0.3),
            const Color(0xFF00CEC9).withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 앨범 아트 (아이콘으로 대체)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF00B894),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          
          // 트랙 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track?.title ?? '선택된 곡 없음',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  track?.artist ?? 'Snack Games',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
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

  Widget _buildPlayerControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // 볼륨 슬라이더
          Row(
            children: [
              const Icon(Icons.volume_down, color: Colors.grey, size: 20),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF00B894),
                    inactiveTrackColor: Colors.grey[700],
                    thumbColor: const Color(0xFF00B894),
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  ),
                  child: Slider(
                    value: _playerService.volume,
                    onChanged: (value) => _playerService.setVolume(value),
                  ),
                ),
              ),
              const Icon(Icons.volume_up, color: Colors.grey, size: 20),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 메인 컨트롤 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 셔플
              IconButton(
                onPressed: _playerService.toggleShuffle,
                icon: Icon(
                  Icons.shuffle,
                  color: _playerService.shuffle 
                      ? const Color(0xFF00B894) 
                      : Colors.grey,
                ),
              ),
              
              // 이전 곡
              IconButton(
                onPressed: _playerService.previous,
                icon: const Icon(
                  Icons.skip_previous,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              // 재생/일시정지
              GestureDetector(
                onTap: _playerService.togglePlay,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF00B894),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              
              // 다음 곡
              IconButton(
                onPressed: _playerService.next,
                icon: const Icon(
                  Icons.skip_next,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              
              // 반복 모드
              IconButton(
                onPressed: _playerService.toggleRepeatMode,
                icon: Icon(
                  _getRepeatIcon(),
                  color: _playerService.repeatMode != RepeatMode.none 
                      ? const Color(0xFF00B894) 
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

  Widget _buildPlaylistTab() {
    final playlist = _playerService.playlist;
    
    if (playlist.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            Text(
              '플레이리스트가 비어있습니다',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '전체 음악 탭에서 곡을 추가해보세요',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      );
    }
    
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playlist.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final item = _playerService.playlist.removeAt(oldIndex);
          _playerService.playlist.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final track = playlist[index];
        final isCurrentTrack = _playerService.currentIndex == index;
        
        return _buildTrackTile(
          key: ValueKey(track.id),
          track: track,
          isCurrentTrack: isCurrentTrack,
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
            onPressed: () => _playerService.removeFromPlaylist(track),
          ),
          onTap: () => _playerService.playTrack(track),
        );
      },
    );
  }

  Widget _buildAllTracksTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: MusicPlayerService.availableTracks.length,
      itemBuilder: (context, index) {
        final track = MusicPlayerService.availableTracks[index];
        final isInPlaylist = _playerService.isInPlaylist(track);
        
        return _buildTrackTile(
          key: ValueKey('all_${track.id}'),
          track: track,
          isCurrentTrack: _playerService.currentTrack?.id == track.id,
          trailing: IconButton(
            icon: Icon(
              isInPlaylist ? Icons.check_circle : Icons.add_circle_outline,
              color: isInPlaylist ? const Color(0xFF00B894) : Colors.grey,
            ),
            onPressed: () {
              if (isInPlaylist) {
                _playerService.removeFromPlaylist(track);
              } else {
                _playerService.addToPlaylist(track);
              }
            },
          ),
          onTap: () {
            if (!isInPlaylist) {
              _playerService.addToPlaylist(track);
            }
            _playerService.playTrack(track);
          },
        );
      },
    );
  }

  Widget _buildTrackTile({
    required Key key,
    required MusicTrack track,
    required bool isCurrentTrack,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentTrack 
            ? const Color(0xFF00B894).withValues(alpha: 0.2)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTrack 
            ? Border.all(color: const Color(0xFF00B894), width: 1)
            : null,
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
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
          ),
        ),
        title: Text(
          track.title,
          style: TextStyle(
            color: isCurrentTrack ? const Color(0xFF00B894) : Colors.white,
            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        trailing: trailing,
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
              height: 8 + (value * 12),
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
