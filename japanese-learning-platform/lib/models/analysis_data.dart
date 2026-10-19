/// 题目深度解析数据模型
///
/// 对应解析规范：
/// 6.1 考点说明  6.2 原文注音翻译  6.3 逐词拆解
/// 6.4 句子结构  6.5 语法句型      6.6 选项逐项讲解  6.7 引申与迁移
library;

/// 题目类型
enum QuestionType {
  grammar, // 语法
  vocabulary, // 词汇
  kanji, // 汉字
  reading, // 阅读
  listening, // 听力
  conversation, // 会话
}

/// JLPT 等级
enum JLPTLevel { n5, n4, n3, n2, n1 }

/// 一道题目及其全部解析信息
class QuestionAnalysis {
  final String id;
  final String questionText; // 题目原文（含空）
  final String questionTextFilled; // 填入正确答案后的完整句
  final int correctIndex; // 正确选项下标
  final List<QuestionOption> options; // 4 个选项
  final String source; // 来源
  final JLPTLevel level;
  final QuestionType type;

  // 6.1 总览
  final AnalysisOverview overview;

  // 6.2 原文注音翻译
  final List<AnnotatedSegment> annotatedQuestion;
  final List<AnnotatedSegment> annotatedAnswer;
  final String literalTranslation; // 直译
  final String naturalTranslation; // 意译

  // 6.3 逐词拆解
  final List<WordBreakdown> words;

  // 6.4 句子结构
  final SentenceStructure structure;

  // 6.5 语法句型（可多个）
  final List<GrammarPoint> grammarPoints;

  // 6.7 引申与迁移
  final ExtendedPractice extended;

  const QuestionAnalysis({
    required this.id,
    required this.questionText,
    required this.questionTextFilled,
    required this.correctIndex,
    required this.options,
    required this.source,
    required this.level,
    required this.type,
    required this.overview,
    required this.annotatedQuestion,
    required this.annotatedAnswer,
    required this.literalTranslation,
    required this.naturalTranslation,
    required this.words,
    required this.structure,
    required this.grammarPoints,
    required this.extended,
  });
}

/// 选项
class QuestionOption {
  final String label; // A / B / C / D
  final String text; // 选项原文
  final String reading; // 读音（平假名 / 罗马音）
  final String meaning; // 含义
  final OptionVerdict verdict; // 本题判断
  final String reasoning; // 判断依据
  final String usageNote; // 用法说明

  const QuestionOption({
    required this.label,
    required this.text,
    required this.reading,
    required this.meaning,
    required this.verdict,
    required this.reasoning,
    required this.usageNote,
  });
}

/// 选项在本小题中的判断结论
enum OptionVerdict { correct, plausible, wrong }

/// 6.1 总览
class AnalysisOverview {
  final String corePoint; // 核心考点（一句话）
  final String keyJudgment; // 关键判断依据
  final List<String> keywords; // 关键词
  final int difficulty; // 1-5 星难度

  const AnalysisOverview({
    required this.corePoint,
    required this.keyJudgment,
    required this.keywords,
    required this.difficulty,
  });
}

/// 6.2 注音段落片段
/// [rubyText] 为假名注音；非汉字词可空
class AnnotatedSegment {
  final String surface; // 表面文字
  final String? rubyText; // 注音（假名）
  final String? pos; // 词性（用于句子结构高亮）
  final bool isBlank; // 是否题目空位
  final bool isAnswer; // 是否答案位置（填答案后句）

  const AnnotatedSegment({
    required this.surface,
    this.rubyText,
    this.pos,
    this.isBlank = false,
    this.isAnswer = false,
  });
}

/// 6.3 逐词拆解
class WordBreakdown {
  final String surface; // 原文形式
  final String reading; // 读音（假名）
  final String dictionaryForm; // 原形
  final String partOfSpeech; // 词性
  final String meaning; // 含义
  final ConjugationStep? conjugation; // 活用过程（可空：无活用词）
  final String note; // 备注

  const WordBreakdown({
    required this.surface,
    required this.reading,
    required this.dictionaryForm,
    required this.partOfSpeech,
    required this.meaning,
    this.conjugation,
    this.note = '',
  });
}

/// 活用完整过程
class ConjugationStep {
  final String typeName; // 活用类别（如 五段・マ行 / 一段 / サ变 / カ变 / 形容詞）
  final String fromForm; // 起点形（如 辞書形）
  final String toForm; // 终点形（如 て形）
  final List<String> steps; // 每一步变化（如 ['書<-か','く→け','+て']）
  final String rule; // 规则文字描述

  const ConjugationStep({
    required this.typeName,
    required this.fromForm,
    required this.toForm,
    required this.steps,
    required this.rule,
  });
}

/// 6.4 句子结构
class SentenceStructure {
  final List<StructureBlock> blocks;
  final List<Relation> relations; // 修饰/依存关系
  final List<String> omitted; // 省略成分说明

  const SentenceStructure({
    required this.blocks,
    required this.relations,
    required this.omitted,
  });
}

/// 结构块（对应一个主谓宾/补语/修饰语等块）
class StructureBlock {
  final String text; // 原文片段
  final StructureRole role; // 主 / 谓 / 宾 / 补 / 修
  final String roleLabel; // 角色中文名
  final String colorKey; // 颜色键（与 theme 对应）

  const StructureBlock({
    required this.text,
    required this.role,
    required this.roleLabel,
    required this.colorKey,
  });
}

enum StructureRole { subject, predicate, object, complement, modifier, particle }

/// 结构关系（修饰 / 依存）
class Relation {
  final int from; // 修饰方块索引
  final int to; // 被修饰方块索引
  final String kind; // 关系种类（修饰 / 并列 / 因果...）
  final String note;

  const Relation({
    required this.from,
    required this.to,
    required this.kind,
    required this.note,
  });
}

/// 6.5 语法详情
class GrammarPoint {
  final String name; // 名称（如 ～ている）
  final String meaning; // 含义
  final String connection; // 接续
  final String formula; // 公式
  final String scenario; // 使用场景
  final List<String> examples; // 例句
  final JLPTLevel level;
  final List<String> tags; // 标签
  final List<String> similar; // 相似语法（易混）

  const GrammarPoint({
    required this.name,
    required this.meaning,
    required this.connection,
    required this.formula,
    required this.scenario,
    required this.examples,
    required this.level,
    required this.tags,
    required this.similar,
  });
}

/// 6.7 引申练习
class ExtendedPractice {
  /// 本题必懂
  final List<MustKnowItem> mustKnow;

  /// 容易混淆（对比）
  final List<ConfusingPair> confusingPairs;

  /// 进阶拓展
  final List<AdvancedItem> advanced;

  /// 迁移练习（小题）
  final List<TransferExercise> exercises;

  const ExtendedPractice({
    required this.mustKnow,
    required this.confusingPairs,
    required this.advanced,
    required this.exercises,
  });
}

class MustKnowItem {
  final String title;
  final String explanation;
  const MustKnowItem({required this.title, required this.explanation});
}

class ConfusingPair {
  final String a; // A 语法
  final String b; // B 语法
  final String aDesc;
  final String bDesc;
  final String difference; // 关键差异
  final String exampleA;
  final String exampleB;

  const ConfusingPair({
    required this.a,
    required this.b,
    required this.aDesc,
    required this.bDesc,
    required this.difference,
    required this.exampleA,
    required this.exampleB,
  });
}

class AdvancedItem {
  final String title;
  final String content;
  final JLPTLevel level;
  const AdvancedItem({
    required this.title,
    required this.content,
    required this.level,
  });
}

class TransferExercise {
  final String question;
  final List<String> choices;
  final int answerIndex;
  final String explanation;

  const TransferExercise({
    required this.question,
    required this.choices,
    required this.answerIndex,
    required this.explanation,
  });
}
