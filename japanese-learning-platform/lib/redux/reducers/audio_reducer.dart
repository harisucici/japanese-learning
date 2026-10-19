/// 音频 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/audio_actions.dart';
import '../../core/audio/audio_service.dart';

/// 音频播放器 Reducer
Reducer<AudioPlayerState> audioPlayerReducer = combineReducers<AudioPlayerState>([
  TypedReducer<AudioPlayerState, AudioPlaybackStateChanged>(_playbackStateChanged),
  TypedReducer<AudioPlayerState, AudioPositionChanged>(_positionChanged),
  TypedReducer<AudioPlayerState, AudioDurationChanged>(_durationChanged),
  TypedReducer<AudioPlayerState, AudioCurrentIndexChanged>(_currentIndexChanged),
  TypedReducer<AudioPlayerState, AudioErrorOccurred>(_errorOccurred),
  TypedReducer<AudioPlayerState, AudioPlaylistChanged>(_playlistChanged),
  TypedReducer<AudioPlayerState, AudioSpeedChanged>(_speedChanged),
  TypedReducer<AudioPlayerState, AudioLoopModeChanged>(_loopModeChanged),
  TypedReducer<AudioPlayerState, AudioStopped>(_stopped),
]);

AudioPlayerState _playbackStateChanged(AudioPlayerState state, AudioPlaybackStateChanged action) {
  return state.copyWith(
    playbackState: action.state,
    clearError: action.state != AudioPlaybackState.error,
  );
}

AudioPlayerState _positionChanged(AudioPlayerState state, AudioPositionChanged action) {
  return state.copyWith(position: action.position);
}

AudioPlayerState _durationChanged(AudioPlayerState state, AudioDurationChanged action) {
  return state.copyWith(duration: action.duration);
}

AudioPlayerState _currentIndexChanged(AudioPlayerState state, AudioCurrentIndexChanged action) {
  return state.copyWith(currentIndex: action.index, currentItem: action.item);
}

AudioPlayerState _errorOccurred(AudioPlayerState state, AudioErrorOccurred action) {
  return state.copyWith(error: action.error);
}

AudioPlayerState _playlistChanged(AudioPlayerState state, AudioPlaylistChanged action) {
  return state.copyWith(playlist: action.playlist);
}

AudioPlayerState _speedChanged(AudioPlayerState state, AudioSpeedChanged action) {
  return state.copyWith(speed: action.speed);
}

AudioPlayerState _loopModeChanged(AudioPlayerState state, AudioLoopModeChanged action) {
  return state.copyWith(loopMode: action.mode);
}

AudioPlayerState _stopped(AudioPlayerState state, AudioStopped action) {
  return const AudioPlayerState();
}
