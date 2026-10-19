/// 句子朗读按钮
///
/// 与单词按钮相似，但图标与来源类型不同（humanRecorded / synthesized）。
/// 支持长按显示朗读来源菜单。
library;

import 'package:flutter/material.dart';

import '../../../core/audio/audio.dart';
import '../../../core/theme/app_colors.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

class SentenceReadButton extends StatelessWidget {
  final String sentenceId;
  final String audioUrl;
  final String label;
  final AudioSourceType sourceType;
  final bool isLocalFile;
  final Color? color;
  final VoidCallback? onLongPress;

  const SentenceReadButton({
    super.key,
    required this.sentenceId,
    required this.audioUrl,
    required this.label,
    this.sourceType = AudioSourceType.humanRecorded,
    this.isLocalFile = false,
    this.color,
    this.onLongPress,
  });

  bool _isCurrent(AudioPlaybackState state, AudioItem? currentItem) =>
      currentItem?.id == sentenceId &&
      (state == AudioPlaybackState.playing ||
       state == AudioPlaybackState.loading ||
       state == AudioPlaybackState.paused);

  void _handleTap() async {
    final service = AudioService.instance;
    final currentState = service.state;
    final currentItem = service.currentItem;

    if (_isCurrent(currentState, currentItem)) {
      if (currentState == AudioPlaybackState.playing) {
        await service.pause();
      } else if (currentState == AudioPlaybackState.paused) {
        await service.resume();
      }
      return;
    }

    await service.playSingle(AudioItem(
      id: sentenceId,
      source: audioUrl,
      isLocalFile: isLocalFile,
      sourceType: sourceType,
      label: label,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.primary;

    return StreamBuilder<AudioPlaybackState>(
      stream: AudioService.instance.stateStream,
      builder: (context, stateSnapshot) {
        return StreamBuilder<AudioItem?>(
          stream: AudioService.instance.currentItemStream,
          builder: (context, itemSnapshot) {
            final state = stateSnapshot.data ?? AudioPlaybackState.idle;
            final currentItem = itemSnapshot.data;
            final active = _isCurrent(state, currentItem);
            final loading = active && state == AudioPlaybackState.loading;

            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _handleTap,
              onLongPress: onLongPress,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? iconColor.withAlphaCompat(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: active ? iconColor.withAlphaCompat(0.3) : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          color: iconColor,
                        ),
                      )
                    else
                      Icon(
                        active && state == AudioPlaybackState.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 18,
                        color: iconColor,
                      ),
                    const SizedBox(width: 6),
                    Text(
                      active && state == AudioPlaybackState.playing ? '朗读中' : '朗读',
                      style: TextStyle(
                        color: iconColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
