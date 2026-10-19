/// 全局枚举定义 - 日语 N5-N1 刷题与深度解析平台

/// JLPT 等级枚举
enum JLPTLevel {
  n5,
  n4,
  n3,
  n2,
  n1;

  /// 显示名称
  String get displayName => name.toUpperCase();

  /// 从字符串解析
  static JLPTLevel fromString(String? value) {
    if (value == null) return JLPTLevel.n5;
    return JLPTLevel.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => JLPTLevel.n5,
    );
  }

  /// 等级对应的数值（用于排序和比较）
  int get numericValue {
    switch (this) {
      case JLPTLevel.n5:
        return 5;
      case JLPTLevel.n4:
        return 4;
      case JLPTLevel.n3:
        return 3;
      case JLPTLevel.n2:
        return 2;
      case JLPTLevel.n1:
        return 1;
    }
  }
}

/// 题目类型枚举（七种）
enum QuestionType {
  /// 文字・語彙（字符与词汇）
  vocabulary,

  /// 漢字（汉字）
  kanji,

  /// 文法（语法）
  grammar,

  /// 読解（阅读理解）
  reading,

  /// 聴解（听力理解）
  listening,

  /// 文脈規定（填空/上下文）
  fillInBlank,

  /// 総合（综合题）
  comprehensive;

  /// 显示名称（日文）
  String get displayName {
    switch (this) {
      case QuestionType.vocabulary:
        return '文字・語彙';
      case QuestionType.kanji:
        return '漢字';
      case QuestionType.grammar:
        return '文法';
      case QuestionType.reading:
        return '読解';
      case QuestionType.listening:
        return '聴解';
      case QuestionType.fillInBlank:
        return '文脈規定';
      case QuestionType.comprehensive:
        return '総合';
    }
  }

  /// 显示名称（中文）
  String get displayNameZh {
    switch (this) {
      case QuestionType.vocabulary:
        return '词汇';
      case QuestionType.kanji:
        return '汉字';
      case QuestionType.grammar:
        return '语法';
      case QuestionType.reading:
        return '阅读';
      case QuestionType.listening:
        return '听力';
      case QuestionType.fillInBlank:
        return '填空';
      case QuestionType.comprehensive:
        return '综合';
    }
  }

  /// 从字符串解析
  static QuestionType fromString(String? value) {
    if (value == null) return QuestionType.vocabulary;
    return QuestionType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionType.vocabulary,
    );
  }
}

/// 题目来源枚举
enum QuestionSource {
  /// 真题
  official,

  /// 模拟题
  mock,

  /// 教材题
  textbook,

  /// 用户生成
  userGenerated,

  /// AI 生成
  aiGenerated,

  /// 历年真题
  pastExam,

  /// 自定义
  custom;

  /// 显示名称
  String get displayName {
    switch (this) {
      case QuestionSource.official:
        return '真题';
      case QuestionSource.mock:
        return '模拟题';
      case QuestionSource.textbook:
        return '教材题';
      case QuestionSource.userGenerated:
        return '用户生成';
      case QuestionSource.aiGenerated:
        return 'AI 生成';
      case QuestionSource.pastExam:
        return '历年真题';
      case QuestionSource.custom:
        return '自定义';
    }
  }

  /// 从字符串解析
  static QuestionSource fromString(String? value) {
    if (value == null) return QuestionSource.official;
    return QuestionSource.values.firstWhere(
      (e) => e.name == value,
      orElse: () => QuestionSource.official,
    );
  }
}

/// 复习状态枚举
enum ReviewStatus {
  /// 新题
  new_,

  /// 学习中
  learning,

  /// 复习中
  reviewing,

  /// 已掌握
  mastered;

  String get displayName {
    switch (this) {
      case ReviewStatus.new_:
        return '新题';
      case ReviewStatus.learning:
        return '学习中';
      case ReviewStatus.reviewing:
        return '复习中';
      case ReviewStatus.mastered:
        return '已掌握';
    }
  }

  static ReviewStatus fromString(String? value) {
    if (value == null) return ReviewStatus.new_;
    return ReviewStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReviewStatus.new_,
    );
  }
}

/// 练习类型枚举
enum ExerciseType {
  /// 选择题
  multipleChoice,

  /// 填空题
  fillBlank,

  /// 翻译题
  translation,

  /// 造句题
  sentenceBuilding;

  String get displayName {
    switch (this) {
      case ExerciseType.multipleChoice:
        return '选择题';
      case ExerciseType.fillBlank:
        return '填空题';
      case ExerciseType.translation:
        return '翻译题';
      case ExerciseType.sentenceBuilding:
        return '造句题';
    }
  }

  static ExerciseType fromString(String? value) {
    if (value == null) return ExerciseType.multipleChoice;
    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.multipleChoice,
    );
  }
}
