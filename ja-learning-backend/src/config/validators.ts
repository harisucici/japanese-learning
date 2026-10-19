import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
  name: z.string().min(1).max(50),
  targetLevel: z.enum(['n5', 'n4', 'n3', 'n2', 'n1']).optional(),
});

export const createRecordSchema = z.object({
  level: z.enum(['n5', 'n4', 'n3', 'n2', 'n1']),
  recordType: z.enum(['practice', 'exam', 'review']),
  questionIds: z.array(z.string()),
  answers: z.array(z.object({
    questionId: z.string(),
    selectedOptionId: z.string().optional(),
    userAnswer: z.string().optional(),
    isCorrect: z.boolean(),
    timeSpent: z.number().optional(),
  }).refine(
    (data) => data.selectedOptionId || data.userAnswer,
    { message: 'Either selectedOptionId or userAnswer is required' }
  )),
  durationMs: z.number().int().positive(),
});

export const markReviewSchema = z.object({
  itemId: z.string(),
  correct: z.boolean(),
});
