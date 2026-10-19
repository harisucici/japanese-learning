import 'enums.dart';

/// 题目选项模型
///
/// 每个选项有唯一 optionId，answer 用 optionId 引用
class QuestionOption {
  /// 选项唯一 ID（与问题关联）
  final String id;

  /// 选项内容（支持富文本：日文 + 翻译）
  final String content;

  /// 选项附加说明（可选）
  final String? hint;

  /// 读音（假名，可选）
  final String? reading;

  /// 选项顺序索引（用于显示）
  final int index;

  const QuestionOption({
    required this.id,
    required this.content,
    this.hint,
    this.reading,
    required this.index,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      content: json['content'] as String,
      hint: json['hint'] as String?,
      reading: json['reading'] as String?,
      index: (json['index'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'hint': hint,
      'reading': reading,
      'index': index,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is QuestionOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 题目模型 - 七种题型，五种等级
///
/// 核心字段: id, level, type, content, options, answer (optionId), source, explanationId
class Question {
  /// 题目唯一 ID
  final String id;

  /// JLPT 等级
  final JLPTLevel level;

  /// 题目类型（七种）
  final QuestionType type;

  /// 题干内容
  final String content;

  /// 题干读音（可选，用于听力类）
  final String? contentReading;

  /// 题干图片 URL（可选）
  final String? contentImageUrl;

  /// 音频 URL（可选，听力题必需）
  final String? audioUrl;

  /// 选项列表
  final List<QuestionOption> options;

  /// 正确答案的 optionId（引用选项，而非 A/B/C/D）
  final String answer;

  /// 题目来源
  final QuestionSource source;

  /// 关联的解析 ID
  final String explanationId;

  /// 题目标签（如：〜て形、受身形、N2 文法）
  final List<String> tags;

  /// 难度系数（0.0 - 1.0）
  final double difficulty;

  /// 创建时间
  final DateTime createdAt;

  /// 题目顺序
  final int order;

  const Question({
    required this.id,
    required this.level,
    required this.type,
    required this.content,
    this.contentReading,
    this.contentImageUrl,
    this.audioUrl,
    required this.options,
    required this.answer,
    this.source = QuestionSource.official,
    required this.explanationId,
    this.tags = const [],
    this.difficulty = 0.5,
    DateTime? createdAt,
    this.order = 0,
  }) : createdAt = createdAt ?? const _EpochDateTime();

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      level: JLPTLevel.fromString(json['level'] as String?),
      type: QuestionType.fromString(json['type'] as String?),
      content: json['content'] as String,
      contentReading: json['contentReading'] as String?,
      contentImageUrl: json['contentImageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      options: ((json['options'] as List?) ?? const [])
          .map((o) => QuestionOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      answer: json['answer'] as String,
      source: QuestionSource.fromString(json['source'] as String?),
      explanationId: json['explanationId'] as String? ?? '',
      tags: (json['tags'] as List?)?.cast<String>() ?? const [],
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      order: (json['order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'type': type.name,
      'content': content,
      'contentReading': contentReading,
      'contentImageUrl': contentImageUrl,
      'audioUrl': audioUrl,
      'options': options.map((o) => o.toJson()).toList(),
      'answer': answer,
      'source': source.name,
      'explanationId': explanationId,
      'tags': tags,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
    };
  }

  /// 根据 optionId 取选项
  QuestionOption? getOptionById(String optionId) {
    try {
      return options.firstWhere((o) => o.id == optionId);
    } catch (_) {
      return null;
    }
  }

  /// 取正确答案对象
  QuestionOption? get correctOption => getOptionById(answer);

  /// 是否正确
  bool isCorrect(String selectedOptionId) => selectedOptionId == answer;

  Question copyWith({
    String? id,
    JLPTLevel? level,
    QuestionType? type,
    String? content,
    String? contentReading,
    String? contentImageUrl,
    String? audioUrl,
    List<QuestionOption>? options,
    String? answer,
    QuestionSource? source,
    String? explanationId,
    List<String>? tags,
    double? difficulty,
    DateTime? createdAt,
    int? order,
  }) {
    return Question(
      id: id ?? this.id,
      level: level ?? this.level,
      type: type ?? this.type,
      content: content ?? this.content,
      contentReading: contentReading ?? this.contentReading,
      contentImageUrl: contentImageUrl ?? this.contentImageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      options: options ?? this.options,
      answer: answer ?? this.answer,
      source: source ?? this.source,
      explanationId: explanationId ?? this.explanationId,
      tags: tags ?? this.tags,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      order: order ?? this.order,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Question && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Question(id: $id, level: ${level.name}, type: ${type.name})';
}

class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
