import prisma from '../config/database';
import userPrisma from '../config/user-database';

/**
 * 练习模式服务 —— 按题型、语法、错题、随机 四种入口
 */
export class PracticeService {
  /**
   * 按题型练习：获取该等级 + 题型的已核验题目
   * @param level JLPT 等级
   * @param type  题目类型 (vocabulary | grammar | reading | listening | ...)
   * @param limit 最多返回几题
   */
  async getByType(level: string, type: string, limit: number) {
    const questions = await prisma.question.findMany({
      where: {
        level: level.toLowerCase(),
        type,
        source: { in: ['pastExam', 'official', 'mock', 'textbook'] },
      },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      take: limit,
    });
    return questions.map(sanitizeQuestion);
  }

  /**
   * 按语法知识点练习：获取与 grammarId 关联的所有题目
   */
  async getByGrammar(grammarId: string, limit: number) {
    const questions = await prisma.question.findMany({
      where: { grammarId },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      take: limit,
    });
    return questions.map(sanitizeQuestion);
  }

  /**
   * 错题重练：从 ReviewItem 获取错题并返回对应题目
   * @param userId   学习者 ID
   * @param level    可选等级过滤
   * @param limit    最多返回几题
   */
  async getMistakes(userId: string, level?: string, limit: number = 20) {
    const where: any = {
      userId,
      isWrongAnswer: true,
    };
    if (level) where.level = level.toLowerCase();

    const items = await userPrisma.reviewItem.findMany({
      where,
      orderBy: [
        // 优先复习：错得多、最近复习时间早的
        { wrongCount: 'desc' },
        { nextReviewAt: 'asc' },
      ],
      take: limit,
    });

    const questions = await prisma.question.findMany({ where: { id: { in: items.map(item => item.questionId) } } });
    return items.flatMap(item => {
      const question = questions.find(q => q.id === item.questionId);
      return question ? [{
      reviewItem: item,
      question: sanitizeQuestion(question),
    }] : [];
    });
  }

  /**
   * 随机题目练习：从该等级随机抽取
   */
  async getRandom(level: string, limit: number, excludeIds: string[] = []) {
    // SQLite 不支持 RANDOM() in Prisma orderBy 直接使用；
    // 先获取总数，再用 skip+take 随机取
    const total = await prisma.question.count({
      where: {
        level: level.toLowerCase(),
        source: { in: ['pastExam', 'official', 'mock', 'textbook'] },
        ...(excludeIds.length ? { id: { notIn: excludeIds } } : {}),
      },
    });
    if (total === 0) return [];

    // 随机起点
    const skip = Math.floor(Math.random() * Math.max(1, total - limit));
    const questions = await prisma.question.findMany({
      where: {
        level: level.toLowerCase(),
        source: { in: ['pastExam', 'official', 'mock', 'textbook'] },
        ...(excludeIds.length ? { id: { notIn: excludeIds } } : {}),
      },
      orderBy: [{ order: 'asc' }, { id: 'asc' }],
      skip,
      take: Math.min(limit, total),
    });

    // Fisher-Yates shuffle 打乱顺序
    for (let i = questions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [questions[i], questions[j]] = [questions[j], questions[i]];
    }

    return questions.map(sanitizeQuestion);
  }
}

/**
 * 移除题目的正确答案等敏感字段，防止泄漏
 */
function sanitizeQuestion(q: any) {
  const { answer, explanationId, difficulty, ...visible } = q;
  if (visible.provenance) {
    const { correctOption, answer: sourceAnswer, ...source } = visible.provenance;
    visible.provenance = source;
  }
  return visible;
}
