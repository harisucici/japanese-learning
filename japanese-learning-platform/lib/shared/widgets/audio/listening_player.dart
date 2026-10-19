import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../core/audio/audio_service.dart';
import '../../../redux/app_state.dart';

/// 听力播放器
/// 
/// 支持：进度条、时间显示、常速/慢速切换、循环模式、上/下一项、播放状态指示。
/// 典型场景：听力题的音频播放面板。
class ListeningPlayer extends StatefulWidget {
  /// 播放项列表
  final List<AudioItem> items;

  /// 起始播放索引
  final int startIndex;

  /// 是否展示标题/序号
  final bool showHeader;

  /// 外部关闭/收起回调
  final VoidCallback? onClose;

  const ListeningPlayer({
    super.key,
    required this.items,
    this.startIndex = 0,
    this.showHeader = true,
    this.onClose,
  });

  @override
  State<ListeningPlayer> createState() => _ListeningPlayerState();
}

class _ListeningPlayerState extends State<ListeningPlayer> {
  final _audioService = AudioService.instance;

  @override
  void initState() {
    super.initState();
    // 初始化播放列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService.playList(widget.items, startIndex: widget.startIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AudioPlayerState>(
      converter: (store) => store.state.audioPlayer,
      builder: (context, audioState) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              if (widget.showHeader) _buildHeader(audioState),
              
              // 进度条
              _buildProgress(audioState),
              
              // 时间显示
              _buildTimeRow(audioState),
              
              // 控制按钮
              _buildControls(audioState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(AudioPlayerState state) {
    final currentItem = state.currentItem;
    
    return Row(
      children: [
        // 当前项标题
        Expanded(
          child: Text(
            currentItem?.label ?? '无播放项',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // 序号显示
        if (widget.items.length > 1)
          Text(
            '${state.currentIndex + 1}/${widget.items.length}',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        
        // 关闭按钮
        if (widget.onClose != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ],
    );
  }

  Widget _buildProgress(AudioPlayerState state) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return GestureDetector(
      onTapDown: (details) {
        _seekToPosition(details, state);
      },
      onHorizontalDragUpdate: (details) {
        _seekToPosition(details, state);
      },
      child: Container(
        height: 20,
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // 背景轨道
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 已播放进度
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // 进度指示点
                Positioned(
                  left: (constraints.maxWidth * progress).clamp(0.0, constraints.maxWidth - 12),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _seekToPosition(dynamic details, AudioPlayerState state) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final localPosition = details.localPosition;
    
    // 计算点击位置相对于进度条的比例
    final progress = (localPosition.dx / size.width).clamp(0.0, 1.0);
    final targetPosition = Duration(
      milliseconds: (state.duration.inMilliseconds * progress).round(),
    );

    _audioService.seek(targetPosition);
  }

  Widget _buildTimeRow(AudioPlayerState state) {
    final current = _formatDuration(state.position);
    final total = _formatDuration(state.duration);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          current,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          total,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildControls(AudioPlayerState state) {
    final hasPlaylist = widget.items.length > 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 循环模式
        _buildControlButton(
          icon: _loopModeIcon(_audioService.loopMode),
          onTap: () => _toggleLoopMode(_audioService.loopMode),
          tooltip: '循环模式',
        ),

        // 上一项（仅播放列表时显示）
        if (hasPlaylist)
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: () {
              _audioService.previous();
            },
            tooltip: '上一项',
          ),

        // 播放/暂停按钮
        _buildPlayPauseButton(state),

        // 下一项（仅播放列表时显示）
        if (hasPlaylist)
          _buildControlButton(
            icon: Icons.skip_next,
            onTap: () {
              _audioService.next();
            },
            tooltip: '下一项',
          ),

        // 播放速度
        _buildControlButton(
          icon: Icons.speed,
          label: _formatSpeed(_audioService.speed),
          onTap: () => _toggleSpeed(_audioService.speed),
          tooltip: '播放速度',
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    String? label,
    VoidCallback? onTap,
    String? tooltip,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              if (label != null) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(AudioPlayerState state) {
    final isPlaying = state.isPlaying;
    final isLoading = state.isLoading;

    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 32,
            ),
      onPressed: isLoading
          ? null
          : () {
              if (isPlaying) {
                _audioService.pause();
              } else {
                _audioService.resume();
              }
            },
      iconSize: 32,
    );
  }

  IconData _loopModeIcon(AudioLoopMode mode) {
    switch (mode) {
      case AudioLoopMode.none:
        return Icons.repeat;
      case AudioLoopMode.one:
        return Icons.repeat_one;
      case AudioLoopMode.list:
        return Icons.repeat;
    }
  }

  String _formatSpeed(double speed) {
    if (speed == 1.0) return '1x';
    if (speed == 1.5) return '1.5x';
    if (speed == 2.0) return '2x';
    if (speed == 0.5) return '0.5x';
    return '${speed}x';
  }

  void _toggleLoopMode(AudioLoopMode currentMode) {
    AudioLoopMode nextMode;
    switch (currentMode) {
      case AudioLoopMode.none:
        nextMode = AudioLoopMode.one;
        break;
      case AudioLoopMode.one:
        nextMode = AudioLoopMode.list;
        break;
      case AudioLoopMode.list:
        nextMode = AudioLoopMode.none;
        break;
    }
    
    _audioService.setLoopMode(nextMode);
  }

  void _toggleSpeed(double currentSpeed) {
    // 循环切换速度：1x -> 1.5x -> 2x -> 0.5x -> 1x
    double nextSpeed;
    if (currentSpeed == 1.0) {
      nextSpeed = 1.5;
    } else if (currentSpeed == 1.5) {
      nextSpeed = 2.0;
    } else if (currentSpeed == 2.0) {
      nextSpeed = 0.5;
    } else {
      nextSpeed = 1.0;
    }
    
    _audioService.setSpeed(nextSpeed);
  }
}
