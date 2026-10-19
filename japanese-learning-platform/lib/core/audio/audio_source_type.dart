/// 音频来源类型
///
/// 区分不同业务场景下音频的来源：
/// - [original]: 真题配套原声（官方听力音频）
/// - [synthesized]: 合成朗读（TTS / 本地合成）
/// - [humanRecorded]: 人工录音（单词发音、例句朗读等）
enum AudioSourceType {
  /// 原音频（真题配套）
  original,

  /// 合成朗读
  synthesized,

  /// 人工录音
  humanRecorded;

  String get displayName {
    switch (this) {
      case AudioSourceType.original:
        return '真题原声';
      case AudioSourceType.synthesized:
        return '合成朗读';
      case AudioSourceType.humanRecorded:
        return '人工录音';
    }
  }

  static AudioSourceType fromString(String? value) {
    if (value == null) return AudioSourceType.original;
    return AudioSourceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AudioSourceType.original,
    );
  }
}
