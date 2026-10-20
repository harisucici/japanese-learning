/**
 * 复习系统增强的类型定义
 */

// ReviewMode: 复习模式
export type ReviewMode = 'original' | 'similar';

// ReviewItem 增强字段
export interface ReviewItemEnhanced {
  id: string;
  userId: string;
  questionId: string;
  level: string;
  type: string;
  status: string;
  reviewCount: number;
  nextReviewAt: Date | null;
  easeFactor: number;
  intervalDays: number;
  isFavorite: boolean;
  isWrongAnswer: boolean;
  wrongCount: number;
  correctStreak: number;
  lastCorrectAt: Date | null; // 新增：最近一次答对时间
  reviewMode: ReviewMode; // 新增：复习模式
  createdAt: Date;
  updatedAt: Date;
}

// 错题详情统计
export interface MistakesDetailStats {
  totalMistakes: number;
  typeDistribution: Record<string, number>; // 题型分布
  knowledgeDistribution: Record<string, { count: number; label: string }>; // 知识点分布
  timeTrend: Record<string, number>; // 时间趋势（按月）
  firstTimeWrong: number; // 首次答错数
  masteredAfterMistakes: number; // 多次稳定掌握数
  items: Array<{
    id: string;
    questionId: string;
    type: string;
    level: string;
    wrongCount: number;
    correctStreak: number;
    lastCorrectAt: Date | null;
    status: string;
    question: {
      id: string;
      type: string;
      level: string;
      content: string;
    };
  }>;
}

// 练习入口请求参数
export interface PracticeByTypeParams {
  questionType: string;
  level?: string;
  limit?: number;
}

export interface PracticeByGrammarParams {
  grammarId: string;
  limit?: number;
}

export interface PracticeMistakesParams {
  level?: string;
  limit?: number;
}

export interface PracticeRandomParams {
  level?: string;
  limit?: number;
  exclude?: string[];
}

// 复习路径选择请求
export interface ReviewNextRequest {
  mode: ReviewMode;
}

// 复习路径选择响应
export interface ReviewNextResponse {
  reviewItemId: string;
  mode: ReviewMode;
  question: any;
  explanation?: any;
  alternatives?: any[];
}

// 重做原题响应
export interface RetryOriginalResponse {
  sessionId: string;
  reviewItemId: string;
  question: any;
  message: string;
}
