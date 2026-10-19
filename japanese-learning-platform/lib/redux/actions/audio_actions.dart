/// 音频播放 Actions
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../../core/audio/audio.dart';

// ========== Action Types ==========

class AudioPlaybackStateChanged {
  final AudioPlaybackState state;
  AudioPlaybackStateChanged(this.state);
}

class AudioPositionChanged {
  final Duration position;
  AudioPositionChanged(this.position);
}

class AudioDurationChanged {
  final Duration duration;
  AudioDurationChanged(this.duration);
}

class AudioCurrentIndexChanged {
  final int index;
  final AudioItem? item;
  AudioCurrentIndexChanged(this.index, this.item);
}

class AudioErrorOccurred {
  final String? error;
  AudioErrorOccurred(this.error);
}

class AudioPlaylistChanged {
  final List<AudioItem> playlist;
  AudioPlaylistChanged(this.playlist);
}

class AudioSpeedChanged {
  final double speed;
  AudioSpeedChanged(this.speed);
}

class AudioLoopModeChanged {
  final AudioLoopMode mode;
  AudioLoopModeChanged(this.mode);
}

class AudioStopped {
  AudioStopped();
}

// ========== Service Actions ==========
/// 注意：音频服务是单例，不通过 Redux 管理
/// 这些 action 仅用于同步状态到 Redux Store
