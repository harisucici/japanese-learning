/// 音频播放服务（单例）
///
/// 封装 just_audio，提供：
/// - 本地文件 / 网络 URL 播放
/// - 播放速率切换（常速 / 慢速）
/// - 循环（单项 / 列表循环 / 单次）
/// - 播放 / 暂停 / 停止 / 进度监听
/// - 按来源类型打标（仅用于业务统计，不影响播放行为）
///
/// 设计：单一实例，全局共享，避免多个 AudioPlayer 同时播放。
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as ja;

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

/// 播放项（单次播放或列表中的一个元素）
class AudioItem {
  /// 唯一标识（URL / 路径 / ID）
  final String id;

  /// 音源：http(s) 或本地文件路径 / Asset
  final String source;

  /// 是否为本地文件（true 时按 FileSource 播放）
  final bool isLocalFile;

  /// 来源类型
  final AudioSourceType sourceType;

  /// 显示名（用于调试或 UI 日志）
  final String? label;

  /// 慢速倍速（仅用于业务层展示或外部 seek；just_audio 使用 [speed] 全局）
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

/// 音频播放服务（单例）- 移动端实现
///
/// 使用 just_audio 实现实际音频播放
class AudioService {
  AudioService._internal() {
    _player = ja.AudioPlayer();
    _attachListeners();
  }

  static final AudioService instance = AudioService._internal();

  late final ja.AudioPlayer _player;

  // ------------------------------------------------------------------
  // 对外状态（通过 Stream 暴露，UI 通过 provider 消费）
  // ------------------------------------------------------------------

  final _stateController = StreamController<AudioPlaybackState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _currentIndexController = StreamController<int>.broadcast();
  final _errorController = StreamController<String?>.broadcast();

  /// 当前播放项列表（业务侧注入）
  List<AudioItem> _playlist = [];
  int _currentIndex = -1;

  /// 当前使用的速率
  double _speed = 1.0;
  double get speed => _speed;

  /// 循环模式
  AudioLoopMode _loopMode = AudioLoopMode.none;
  AudioLoopMode get loopMode => _loopMode;

  /// 当前播放状态
  AudioPlaybackState _state = AudioPlaybackState.idle;
  AudioPlaybackState get state => _state;

  /// 当前播放项
  AudioItem? get currentItem =>
      (_currentIndex >= 0 && _currentIndex < _playlist.length)
          ? _playlist[_currentIndex]
          : null;
  int get currentIndex => _currentIndex;
  List<AudioItem> get playlist => List.unmodifiable(_playlist);

  // ------------------------------------------------------------------
  // 流
  // ------------------------------------------------------------------
  Stream<AudioPlaybackState> get stateStream => _stateController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<int> get currentIndexStream => _currentIndexController.stream;
  Stream<String?> get errorStream => _errorController.stream;
  Stream<AudioItem?> get currentItemStream => _currentIndexController.stream.map((_) => currentItem);

  // ------------------------------------------------------------------
  // 播放控制
  // ------------------------------------------------------------------

  /// 设置播放列表并自动播放第一项
  Future<void> playList(List<AudioItem> items, {int startIndex = 0}) async {
    if (items.isEmpty) {
      await stop();
      return;
    }
    _playlist = List.of(items);
    _currentIndex = startIndex.clamp(0, items.length - 1);
    await _loadAndPlayCurrent();
  }

  /// 直接播放单个项（清空列表）
  Future<void> playSingle(AudioItem item) async {
    _playlist = [item];
    _currentIndex = 0;
    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    final item = currentItem;
    if (item == null) {
      _updateState(AudioPlaybackState.idle);
      return;
    }
    _updateState(AudioPlaybackState.loading);
    _errorController.add(null);
    try {
      if (item.isLocalFile) {
        await _player.setFilePath(item.source);
      } else {
        await _player.setUrl(item.source);
      }
      await _player.setSpeed(_speed);
      _applyLoop();
      await _player.play();
      _updateState(AudioPlaybackState.playing);
    } catch (e, st) {
      debugPrint('[AudioService] load error: $e\n$st');
      _errorController.add(e.toString());
      _updateState(AudioPlaybackState.error);
    }
  }

  Future<void> resume() async {
    if (_state != AudioPlaybackState.paused) return;
    try {
      await _player.play();
      _updateState(AudioPlaybackState.playing);
    } catch (e) {
      _errorController.add(e.toString());
      _updateState(AudioPlaybackState.error);
    }
  }

  Future<void> pause() async {
    if (_state != AudioPlaybackState.playing) return;
    try {
      await _player.pause();
      _updateState(AudioPlaybackState.paused);
    } catch (e) {
      _errorController.add(e.toString());
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
    } catch (e) {
      _errorController.add(e.toString());
    }
    _updateState(AudioPlaybackState.idle);
    _currentIndex = -1;
    _playlist = [];
    _positionController.add(Duration.zero);
  }

  /// 切到下一项；列表循环时回到开头，none 模式停止
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    if (_currentIndex + 1 < _playlist.length) {
      _currentIndex++;
      _currentIndexController.add(_currentIndex);
      await _loadAndPlayCurrent();
    } else if (_loopMode == AudioLoopMode.list) {
      _currentIndex = 0;
      _currentIndexController.add(_currentIndex);
      await _loadAndPlayCurrent();
    } else {
      _updateState(AudioPlaybackState.completed);
    }
  }

  /// 切到上一项
  Future<void> previous() async {
    if (_playlist.isEmpty) return;
    // 若当前播放超过 3 秒，重新播放当前项
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      _currentIndexController.add(_currentIndex);
      await _loadAndPlayCurrent();
    } else if (_loopMode == AudioLoopMode.list) {
      _currentIndex = _playlist.length - 1;
      _currentIndexController.add(_currentIndex);
      await _loadAndPlayCurrent();
    } else {
      await seek(Duration.zero);
    }
  }

  /// 跳转到指定时间
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      _errorController.add(e.toString());
    }
  }

  /// 切换速率（1.0 常速，<1.0 慢速，>1.0 快速）
  Future<void> setSpeed(double value) async {
    final clamped = value.clamp(0.5, 2.0);
    _speed = clamped;
    try {
      await _player.setSpeed(clamped);
    } catch (e) {
      _errorController.add(e.toString());
    }
  }

  /// 切换慢速 / 常速（便捷）
  Future<void> toggleSlowSpeed() async {
    final item = currentItem;
    if (item == null) return;
    final target =
        (_speed - 1.0).abs() < 0.01 ? item.slowSpeed : item.normalSpeed;
    await setSpeed(target);
  }

  bool get isSlowSpeed => (_speed - 1.0).abs() > 0.01 && _speed < 1.0;

  /// 设置循环模式
  void setLoopMode(AudioLoopMode mode) {
    _loopMode = mode;
    _applyLoop();
  }

  void _applyLoop() {
    switch (_loopMode) {
      case AudioLoopMode.none:
        _player.setLoopMode(ja.LoopMode.off);
        break;
      case AudioLoopMode.one:
        _player.setLoopMode(ja.LoopMode.one);
        break;
      case AudioLoopMode.list:
        // 列表循环依赖 next() 手动切换，关闭引擎级 loop
        _player.setLoopMode(ja.LoopMode.off);
        break;
    }
  }

  // ------------------------------------------------------------------
  // 内部监听
  // ------------------------------------------------------------------
  void _attachListeners() {
    _player.playerStateStream.listen((event) {
      if (event.processingState == ja.ProcessingState.completed) {
        _handleCompleted();
        return;
      }
      if (event.playing) {
        _updateState(AudioPlaybackState.playing);
      } else if (_state == AudioPlaybackState.playing) {
        _updateState(AudioPlaybackState.paused);
      }
    });

    _player.positionStream.listen(_positionController.add);
    _player.durationStream.listen((d) {
      if (d != null) _durationController.add(d);
    });
  }

  void _handleCompleted() {
    if (_loopMode == AudioLoopMode.one) {
      // 引擎已自动重新播放
      return;
    }
    if (_currentIndex + 1 < _playlist.length) {
      // 静默切到下一项
      unawaited(next());
    } else if (_loopMode == AudioLoopMode.list) {
      _currentIndex = 0;
      _currentIndexController.add(_currentIndex);
      unawaited(_loadAndPlayCurrent());
    } else {
      _updateState(AudioPlaybackState.completed);
    }
  }

  void _updateState(AudioPlaybackState newState) {
    if (_state == newState) return;
    _state = newState;
    _stateController.add(newState);
  }

  /// 释放资源（应用退出时）
  Future<void> dispose() async {
    await _stateController.close();
    await _positionController.close();
    await _durationController.close();
    await _currentIndexController.close();
    await _errorController.close();
    await _player.dispose();
  }
}
