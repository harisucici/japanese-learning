/**
 * 题库导入服务
 * 处理 JSON 格式的题目批量导入，支持事务和错误记录
 */
import prisma from '../config/database';
import { randomUUID } from 'node:crypto';

// 导入输入类型
interface ImportQuestionInput {
  question: {
    id?: string;
    level: string;
    type: string;
    content: string;
    contentReading?: string;
    options: Array<{ id: string; content: string; hint?: string; reading?: string }>;
    answer: string;
    source?: string;
    provenance?: any;
    explanationId: string;
    tags?: string[];
    difficulty?: number;
    order?: number;
    vocabularyId?: string;
    grammarId?: string;
  };
  explanation: {
    id?: string;
    questionId?: string;
    translation: string;
    wordAnalysis?: any;
    sentenceStructure?: string;
    grammar?: any;
    optionAnalysis?: any;
    extensions?: any;
    note?: string;
  };
  vocabulary?: {
    word: string;
    reading: string;
    meaning: string;
    level: string;
    exampleSentences?: any;
    note?: string;
  };
  grammar?: {
    name: string;
    structure: string;
    meaning: string;
    level: string;
    usage?: any;
    exampleSentences?: any;
    note?: string;
  };
}

interface ImportError {
  index: number;
  reason: string;
  data?: any;
}

interface ImportResult {
  total: number;
  success: number;
  failed: number;
  skipped: number;
  errors: ImportError[];
}

export class ImportService {
  /**
   * 批量导入题目
   * @param items 题目数据数组
   * @returns 导入结果统计
   */
  async importQuestions(items: ImportQuestionInput[]): Promise<ImportResult> {
    const result: ImportResult = {
      total: items.length,
      success: 0,
      failed: 0,
      skipped: 0,
      errors: [],
    };

    // 逐条处理，记录错误但不中断整个流程
    for (let i = 0; i < items.length; i++) {
      try {
        await this.processSingleQuestion(items[i]);
        result.success++;
      } catch (error: any) {
        // 如果是唯一约束冲突（题目已存在），标记为跳过
        if (error.code === 'P2002' || error.message?.includes('Unique constraint')) {
          result.skipped++;
          result.errors.push({
            index: i,
            reason: '题目已存在（ID 冲突）',
            data: items[i].question,
          });
        } else {
          result.failed++;
          result.errors.push({
            index: i,
            reason: error.message || '未知错误',
            data: items[i].question,
          });
        }
      }
    }

    return result;
  }

  /**
   * 处理单条题目导入（事务）
   */
  private async processSingleQuestion(input: ImportQuestionInput) {
    return prisma.$transaction(async (tx) => {
      // 1. 校验数据完整性
      this.validateQuestion(input.question);
      this.validateExplanation(input.explanation);

      // 2. 确定题目 ID（使用提供的或生成新的）
      const questionId = input.question.id || randomUUID();
      const explanationId = input.explanation.id || input.question.explanationId || randomUUID();

      // 3. 如果提供了词汇，创建词汇（有 ID 则 upsert，无 ID 则创建）
      let vocabularyId = input.question.vocabularyId;
      if (input.vocabulary) {
        const vocabData = {
          word: input.vocabulary.word,
          reading: input.vocabulary.reading,
          meaning: input.vocabulary.meaning,
          level: input.vocabulary.level.toLowerCase(),
          exampleSentences: input.vocabulary.exampleSentences || [],
          note: input.vocabulary.note,
        };
        if (vocabularyId) {
          const vocab = await tx.vocabulary.upsert({
            where: { id: vocabularyId },
            update: vocabData,
            create: { id: vocabularyId, ...vocabData },
          });
          vocabularyId = vocab.id;
        } else {
          const vocab = await tx.vocabulary.create({ data: vocabData });
          vocabularyId = vocab.id;
        }
      }

      // 4. 如果提供了语法，创建语法（有 ID 则 upsert，无 ID 则创建）
      let grammarId = input.question.grammarId;
      if (input.grammar) {
        const gramData = {
          name: input.grammar.name,
          structure: input.grammar.structure,
          meaning: input.grammar.meaning,
          level: input.grammar.level.toLowerCase(),
          usage: input.grammar.usage || {},
          exampleSentences: input.grammar.exampleSentences || [],
          note: input.grammar.note,
        };
        if (grammarId) {
          const gram = await tx.grammar.upsert({
            where: { id: grammarId },
            update: gramData,
            create: { id: grammarId, ...gramData },
          });
          grammarId = gram.id;
        } else {
          const gram = await tx.grammar.create({ data: gramData });
          grammarId = gram.id;
        }
      }

      // 5. 创建题目
      await tx.question.create({
        data: {
          id: questionId,
          level: input.question.level.toLowerCase(),
          type: input.question.type,
          content: input.question.content,
          contentReading: input.question.contentReading,
          options: input.question.options,
          answer: input.question.answer,
          source: input.question.source || 'official',
          provenance: input.question.provenance,
          explanationId: explanationId,
          tags: input.question.tags || [],
          difficulty: input.question.difficulty ?? 0.5,
          order: input.question.order ?? 0,
          vocabularyId,
          grammarId,
          status: 'draft',
          importedAt: new Date(),
        },
      });

      // 6. 创建解析
      await tx.explanation.create({
        data: {
          id: explanationId,
          questionId: questionId,
          translation: input.explanation.translation,
          wordAnalysis: input.explanation.wordAnalysis || [],
          sentenceStructure: input.explanation.sentenceStructure || '',
          grammar: input.explanation.grammar || [],
          optionAnalysis: input.explanation.optionAnalysis || [],
          extensions: input.explanation.extensions || [],
          note: input.explanation.note,
        },
      });
    });
  }

  /**
   * 校验题目数据完整性
   */
  private validateQuestion(question: ImportQuestionInput['question']) {
    const errors: string[] = [];

    // 必填字段检查
    if (!question.content) errors.push('缺少题目内容 (content)');
    if (!question.type) errors.push('缺少题目类型 (type)');
    if (!question.options || !Array.isArray(question.options)) {
      errors.push('缺少选项 (options)');
    }
    if (!question.answer) errors.push('缺少正确答案 (answer)');
    if (!question.level) errors.push('缺少级别 (level)');
    if (!question.explanationId) errors.push('缺少解析 ID (explanationId)');

    // 选项数量检查
    if (question.options) {
      if (question.options.length < 2 || question.options.length > 6) {
        errors.push(`选项数量必须为 2-6 个，当前为 ${question.options.length} 个`);
      }

      // 检查答案有效性
      const optionIds = question.options.map(opt => opt.id);
      if (!optionIds.includes(question.answer)) {
        errors.push(`答案 (${question.answer}) 不在选项中`);
      }

      // 检查每个选项的必填字段
      for (let i = 0; i < question.options.length; i++) {
        const opt = question.options[i];
        if (!opt.id) errors.push(`选项 ${i} 缺少 id`);
        if (!opt.content) errors.push(`选项 ${i} 缺少 content`);
      }
    }

    if (errors.length > 0) {
      throw new Error(`题目数据校验失败: ${errors.join('; ')}`);
    }
  }

  /**
   * 校验解析数据完整性
   */
  private validateExplanation(explanation: ImportQuestionInput['explanation']) {
    const errors: string[] = [];

    if (!explanation.translation) errors.push('缺少翻译 (translation)');

    if (errors.length > 0) {
      throw new Error(`解析数据校验失败: ${errors.join('; ')}`);
    }
  }
}
