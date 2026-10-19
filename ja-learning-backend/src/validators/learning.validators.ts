import { z } from 'zod';

export const startSchema = z.object({
  level: z.enum(['n1', 'n2', 'n3', 'n4', 'n5']),
  type: z.enum(['vocabulary', 'kanji', 'grammar', 'reading', 'listening', 'fillInBlank', 'comprehensive']).optional(),
  limit: z.number().int().min(1).max(200).optional(),
  mode: z.enum(['practice', 'exam', 'fun']).default('practice'),
  paperId: z.string().optional(),
  collectionId: z.string().optional(),
  instantFeedback: z.boolean().default(false),
});

export const answerSchema = z.object({
  questionId: z.string(),
  optionId: z.string(),
});

export const sectionActionSchema = z.object({
  action: z.enum(['start', 'submit']),
});
