import { z } from 'zod';

// JLPT 等级校验
const levelSchema = z.enum(['n5', 'n4', 'n3', 'n2', 'n1']);

// 密码长度校验；使用 bcrypt 存储，允许用户明确指定的数字密码。
const passwordSchema = z
  .string()
  .min(8, '密码长度至少 8 位');

export const loginSchema = z.object({
  identifier: z.string().trim().min(1, '请输入账户名或邮箱').optional(),
  email: z.string().email('邮箱格式不正确').optional(),
  password: z.string().min(1, '请输入密码'),
}).refine(data => Boolean(data.identifier || data.email), { message: '请输入账户名或邮箱' });

export const registerSchema = z.object({
  username: z.string().trim().regex(/^[A-Za-z][A-Za-z0-9_]{2,31}$/, '账户名需为 3–32 位字母、数字或下划线，并以字母开头').optional(),
  email: z.string().email('邮箱格式不正确').optional(),
  password: passwordSchema,
  nickname: z.string().min(1, '昵称不能为空').max(50, '昵称最多 50 个字符').optional(),
  currentLevel: levelSchema.optional(),
  targetLevel: levelSchema.optional(),
  inviteCode: z.string().length(8, '邀请码必须为8位').transform(v => v.toUpperCase()).pipe(z.string().regex(/^[A-Z0-9]{8}$/, '邀请码只能包含大写字母和数字')),
}).refine(data => Boolean(data.username || data.email), { message: '请输入账户名或邮箱' });

export const updateProfileSchema = z.object({
  nickname: z.string().min(1).max(50).optional(),
  currentLevel: levelSchema.optional(),
  targetLevel: levelSchema.optional(),
  avatarUrl: z.string().url().optional().nullable(),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email('邮箱格式不正确'),
});

export const resetPasswordSchema = z.object({
  token: z.string().min(1, '重置令牌不能为空'),
  password: passwordSchema,
});

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, '请输入当前密码'),
  oldPassword: z.string().min(1, '请输入当前密码').optional(),
  newPassword: passwordSchema,
}).refine(data => Boolean(data.currentPassword || data.oldPassword), {
  message: '请输入当前密码',
  path: ['currentPassword'],
});

export const migrateFromAnonymousSchema = z.object({
  anonymousId: z.string().uuid('无效的匿名学习者 ID'),
});

export const createRecordSchema = z.object({
  level: levelSchema,
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
