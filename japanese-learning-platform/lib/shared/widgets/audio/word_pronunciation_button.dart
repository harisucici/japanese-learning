/// 单词发音按钮
///
/// 点击播放单词发音（来自 URL / 本地文件）。支持加载中、错误、当前正在播放的视觉反馈。
library;

import 'package:flutter/material.dart';

import '../../../core/audio/audio.dart';
import '../../../core/theme/app_colors.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

class WordPronunciationButton extends StatefulWidget {
  final String word;
  final String audioUrl;
  final bool isLocalFile;
  final double size;
  final Color? color;

  const WordPronunciationButton({
    super.key,
    required this.word,
    required this.audioUrl,
    this.isLocalFile = false,
    this.size = 32,
    this.color,
  });

  @override
  State<WordPronunciationButton> createState() =>
      _WordPronunciationButtonState();
}

class _WordPronunciationButtonState
    extends State<WordPronunciationButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isCurrentPlaying(AudioPlaybackState state, AudioItem? currentItem) =>
      currentItem?.id == widget.audioUrl &&
      (state == AudioPlaybackState.playing || state == AudioPlaybackState.loading);

  void _handleTap() async {
    final service = AudioService.instance;
    final currentState = service.state;
    final currentItem = service.currentItem;

    if (_isCurrentPlaying(currentState, currentItem)) {
      if (currentState == AudioPlaybackState.playing) {
        await service.pause();
      } else {
        await service.resume();
      }
      return;
    }

    setState(() => _pressed = true);
    _controller.repeat();
    final item = AudioItem(
      id: widget.audioUrl,
      source: widget.audioUrl,
      isLocalFile: widget.isLocalFile,
      sourceType: AudioSourceType.humanRecorded,
      label: widget.word,
    );
    await service.playSingle(item);
    if (mounted) setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AudioPlaybackState>(
      stream: AudioService.instance.stateStream,
      builder: (context, stateSnapshot) {
        return StreamBuilder<AudioItem?>(
          stream: AudioService.instance.currentItemStream,
          builder: (context, itemSnapshot) {
            final state = stateSnapshot.data ?? AudioPlaybackState.idle;
            final currentItem = itemSnapshot.data;
            final playing = _isCurrentPlaying(state, currentItem);
            final loading = playing && state == AudioPlaybackState.loading;
            final iconColor = widget.color ?? AppColors.primary;

            return GestureDetector(
              onTap: _handleTap,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final scale = (playing && !_pressed)
                      ? 1.0 + 0.08 * (_controller.value - 0.5).abs()
                      : 1.0;
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: playing
                        ? iconColor.withAlphaCompat(0.15)
                        : iconColor.withAlphaCompat(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: loading
                        ? SizedBox(
                            width: widget.size * 0.5,
                            height: widget.size * 0.5,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: iconColor,
                            ),
                          )
                        : Icon(
                            playing ? Icons.pause : Icons.volume_up_rounded,
                            size: widget.size * 0.55,
                            color: iconColor,
                          ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
