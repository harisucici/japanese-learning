/// 音频播放服务 - 条件导入入口
///
/// Web 平台使用 stub 实现（无实际播放），移动端（dart:io 可用）使用 just_audio 实现
library audio_service;

export 'audio_service_web.dart' if (dart.library.io) 'audio_service_io.dart';
