/// 词性分析
class WordInfo {
  /// 原词
  final String word;

  /// 读音
  final String reading;

  /// 词性
  final String partOfSpeech;

  /// 中文含义
  final String meaning;

  /// JLPT 等级
  final String? level;

  /// 例句（可选）
  final String? exampleSentence;

  /// 例句翻译（可选）
  final String? exampleTranslation;

  const WordInfo({
    required this.word,
    required this.reading,
    required this.partOfSpeech,
    required this.meaning,
    this.level,
    this.exampleSentence,
    this.exampleTranslation,
  });

  factory WordInfo.fromJson(Map<String, dynamic> json) {
    return WordInfo(
      word: json['word'] as String,
      reading: json['reading'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      level: json['level'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'reading': reading,
      'partOfSpeech': partOfSpeech,
      'meaning': meaning,
      'level': level,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
    };
  }
}

/// 语法点
class GrammarPoint {
  /// 语法名称（如：〜ている）
  final String name;

  /// 接续方式
  final String connection;

  /// 中文解释
  final String meaning;

  /// 使用场景
  final String usage;

  /// 相似语法对比
  final List<String> similarGrammars;

  /// 例句
  final String? exampleSentence;

  /// 例句翻译
  final String? exampleTranslation;

  const GrammarPoint({
    required this.name,
    required this.connection,
    required this.meaning,
    required this.usage,
    this.similarGrammars = const [],
    this.exampleSentence,
    this.exampleTranslation,
  });

  factory GrammarPoint.fromJson(Map<String, dynamic> json) {
    return GrammarPoint(
      name: json['name'] as String,
      connection: json['connection'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      usage: json['usage'] as String? ?? '',
      similarGrammars:
          (json['similarGrammars'] as List?)?.cast<String>() ?? const [],
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'connection': connection,
      'meaning': meaning,
      'usage': usage,
      'similarGrammars': similarGrammars,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
    };
  }
}

/// 选项分析
class OptionAnalysis {
  /// 选项 ID
  final String optionId;

  /// 是否正确
  final bool isCorrect;

  /// 为什么选/不选
  final String reason;

  /// 详细解析
  final String? detail;

  /// 易错点
  final String? pitfall;

  const OptionAnalysis({
    required this.optionId,
    required this.isCorrect,
    required this.reason,
    this.detail,
    this.pitfall,
  });

  factory OptionAnalysis.fromJson(Map<String, dynamic> json) {
    return OptionAnalysis(
      optionId: json['optionId'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
      reason: json['reason'] as String? ?? '',
      detail: json['detail'] as String?,
      pitfall: json['pitfall'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionId': optionId,
      'isCorrect': isCorrect,
      'reason': reason,
      'detail': detail,
      'pitfall': pitfall,
    };
  }
}

/// 引申练习
class ExtensionExercise {
  /// 练习 ID
  final String id;

  /// 练习类型（multiple_choice / fill_blank / translation）
  final String type;

  /// 题干
  final String content;

  /// 选项（选择题）
  final List<Map<String, dynamic>> options;

  /// 答案
  final String answer;

  /// 解析
  final String? explanation;

  /// 关联的知识点
  final List<String> relatedTags;

  const ExtensionExercise({
    required this.id,
    required this.type,
    required this.content,
    this.options = const [],
    required this.answer,
    this.explanation,
    this.relatedTags = const [],
  });

  factory ExtensionExercise.fromJson(Map<String, dynamic> json) {
    return ExtensionExercise(
      id: json['id'] as String,
      type: json['type'] as String,
      content: json['content'] as String,
      options: (json['options'] as List?)
              ?.map((o) => Map<String, dynamic>.from(o as Map))
              .toList() ??
          const [],
      answer: json['answer'] as String,
      explanation: json['explanation'] as String?,
      relatedTags:
          (json['relatedTags'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'options': options,
      'answer': answer,
      'explanation': explanation,
      'relatedTags': relatedTags,
    };
  }
}

/// 题目解析模型 - 深度解析
///
/// 字段: id, questionId, translation, wordAnalysis, sentenceStructure,
///       grammar, optionAnalysis, extensions
class Explanation {
  /// 解析 ID
  final String id;

  /// 关联的题目 ID
  final String questionId;

  /// 题目整体翻译
  final String translation;

  /// 逐词拆解
  final List<WordInfo> wordAnalysis;

  /// 句子结构分析
  final String sentenceStructure;

  /// 语法点（可能多个）
  final List<GrammarPoint> grammar;

  /// 选项分析（每选项一条）
  final List<OptionAnalysis> optionAnalysis;

  /// 引申练习
  final List<ExtensionExercise> extensions;

  /// 学习重点 / 备注
  final String? note;

  /// 创建时间
  final DateTime createdAt;

  const Explanation({
    required this.id,
    required this.questionId,
    required this.translation,
    this.wordAnalysis = const [],
    required this.sentenceStructure,
    this.grammar = const [],
    this.optionAnalysis = const [],
    this.extensions = const [],
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _EpochDateTime();

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      translation: json['translation'] as String? ?? '',
      wordAnalysis: ((json['wordAnalysis'] as List?) ?? const [])
          .map((w) => WordInfo.fromJson(w as Map<String, dynamic>))
          .toList(),
      sentenceStructure: json['sentenceStructure'] as String? ?? '',
      grammar: ((json['grammar'] as List?) ?? const [])
          .map((g) => GrammarPoint.fromJson(g as Map<String, dynamic>))
          .toList(),
      optionAnalysis: ((json['optionAnalysis'] as List?) ?? const [])
          .map((o) => OptionAnalysis.fromJson(o as Map<String, dynamic>))
          .toList(),
      extensions: ((json['extensions'] as List?) ?? const [])
          .map((e) => ExtensionExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      note: json['note'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'translation': translation,
      'wordAnalysis': wordAnalysis.map((w) => w.toJson()).toList(),
      'sentenceStructure': sentenceStructure,
      'grammar': grammar.map((g) => g.toJson()).toList(),
      'optionAnalysis': optionAnalysis.map((o) => o.toJson()).toList(),
      'extensions': extensions.map((e) => e.toJson()).toList(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Explanation copyWith({
    String? id,
    String? questionId,
    String? translation,
    List<WordInfo>? wordAnalysis,
    String? sentenceStructure,
    List<GrammarPoint>? grammar,
    List<OptionAnalysis>? optionAnalysis,
    List<ExtensionExercise>? extensions,
    String? note,
    DateTime? createdAt,
  }) {
    return Explanation(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      translation: translation ?? this.translation,
      wordAnalysis: wordAnalysis ?? this.wordAnalysis,
      sentenceStructure: sentenceStructure ?? this.sentenceStructure,
      grammar: grammar ?? this.grammar,
      optionAnalysis: optionAnalysis ?? this.optionAnalysis,
      extensions: extensions ?? this.extensions,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Explanation && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class _EpochDateTime implements DateTime {
  const _EpochDateTime();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
