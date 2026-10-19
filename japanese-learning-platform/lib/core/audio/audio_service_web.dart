/// 音频播放服务（Web 平台 stub 实现）
///
/// Web 平台不支持 just_audio，此 stub 提供相同的 API 接口但不执行实际播放。
/// 实际音频播放功能仅在移动端可用。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'audio_source_type.dart';

/// 播放状态枚举
enum AudioPlaybackState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

/// 循环模式
enum AudioLoopMode {
  none,
  one,
  list,
}

/// 播放项
class AudioItem {
  final String id;
  final String source;
  final bool isLocalFile;
  final AudioSourceType sourceType;
  final String? label;
  final double normalSpeed;
  final double slowSpeed;

  const AudioItem({
    required this.id,
    required this.source,
    this.isLocalFile = false,
    this.sourceType = AudioSourceType.original,
    this.label,
    this.normalSpeed = 1.0,
    this.slowSpeed = 0.75,
  });
}

/// 音频播放服务（Web stub）
class AudioService {
  AudioService._internal() {
    debugPrint('[AudioService] Web stub initialized - audio playback disabled on web');
  }

  static final AudioService instance = AudioService._internal();

  List<AudioItem> _playlist = [];
  int _currentIndex = -1;
  double _speed = 1.0;
  double get speed => _speed;
  AudioLoopMode _loopMode = AudioLoopMode.none;
  AudioLoopMode get loopMode => _loopMode;
  AudioPlaybackState _state = AudioPlaybackState.idle;
  AudioPlaybackState get state => _state;

  final _stateController = StreamController<AudioPlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _currentIndexController = StreamController<int>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  AudioItem? get currentItem =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;
  int get currentIndex => _currentIndex;
  List<AudioItem> get playlist => List.unmodifiable(_playlist);

  Stream<AudioPlaybackState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<AudioItem?> get currentItemStream => _currentIndexController.stream.map((_) => currentItem);

  Future<void> playList(List<AudioItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) {
      await stop();
      return;
    }
    _playlist = List.of(items);
    _currentIndex = startIndex.clamp(0, items.length - 1);
    _updateState(AudioPlaybackState.idle);
  }

  Future<void> playSingle(AudioItem item) async {
    _playlist = [item];
    _currentIndex = 0;
    _updateState(AudioPlaybackState.idle);
  }

  Future<void> resume() async {
    debugPrint('[AudioService] resume() called on web stub - no-op');
  }

  Future<void> pause() async {
    debugPrint('[AudioService] pause() called on web stub - no-op');
  }

  Future<void> stop() async {
    _updateState(AudioPlaybackState.idle);
    _currentIndex = -1;
    _playlist = [];
    _positionController.add(Duration.zero);
  }

  Future<void> next() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex + 1 < _playlist.length) {
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
    } else if (_loopMode == AudioLoopMode.list) {
      _currentIndex = 0;
      _currentIndexController.add(_currentIndex);
    }
    _updateState(AudioPlaybackState.idle);
  }

  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentIndexController.add(_currentIndex);
    } else if (_loopMode == AudioLoopMode.list) {
      _currentIndex = _playlist.length - 1;
      _currentIndexController.add(_currentIndex);
    }
    _updateState(AudioPlaybackState.idle);
  }

  Future<void> seek(Duration position) async {
    debugPrint('[AudioService] seek() called on web stub - no-op');
  }

  Future<void> setSpeed(double value) async {
    final clamped = value.clamp(0.5, 2.0);
    _speed = clamped;
  }

  Future<void> toggleSlowSpeed() async {
    final item = currentItem;
    if (item == null) return;
    final target =
        (_speed - 1.0).abs() < 0.01 ? item.slowSpeed : item.normalSpeed;
    await setSpeed(target);
  }

  bool get isSlowSpeed => (_speed - 1.0).abs() > 0.01 && _speed < 1.0;

  void setLoopMode(AudioLoopMode mode) {
    _loopMode = mode;
  }

  void _updateState(AudioPlaybackState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> dispose() async {
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentIndexController.close();
    await _errorController.close();
  }
}
