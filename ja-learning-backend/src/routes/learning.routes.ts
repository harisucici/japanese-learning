import { Router, Response } from 'express';
import { randomUUID } from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { Prisma } from '@prisma/client';
import { z } from 'zod';
import prisma from '../config/database';
import { examSections, examConfig, timingSource } from '../services/exam-rules';
import { config } from '../config/env';
import { authMiddleware, AuthRequest } from '../middleware/auth';

const router = Router();
const verified: Prisma.QuestionWhereInput = { source: { in: ['pastExam', 'official'] }, provenance: { not: Prisma.DbNull } };
class HttpError extends Error { constructor(public status: number, message: string) { super(message); } }
const ids = (value: Prisma.JsonValue): string[] => {
  if (!Array.isArray(value) || !value.every(item => typeof item === 'string')) throw new HttpError(500, '题目编号格式无效');
  return value as string[];
};
const run = (fn: (req: AuthRequest, res: Response) => Promise<unknown>) => async (req: AuthRequest, res: Response) => {
  try { await fn(req, res); } catch (e: any) {
    const conflict = ['P2002', 'P2034'].includes(e.code);
    const status = e instanceof HttpError ? e.status : e instanceof z.ZodError ? 400 : e.code === 'P2025' ? 404 : conflict ? 409 : 500;
    if (status === 500) console.error(e);
    res.status(status).json({ error: status === 500 ? '服务暂时不可用，请重试' : conflict ? '该题已提交或状态已更新，请刷新' : e.code === 'P2025' ? '记录不存在，请重新连接' : e.message });
  }
};
const publicQuestion = (q: any) => {
  const { answer, explanationId, difficulty, ...visible } = q;
  if (visible.provenance) {
    const { correctOption, ...source } = visible.provenance;
    visible.provenance = source;
  }
  return visible;
};
const points = (answers: {isCorrect: boolean}[], total: number) => ({
  correctCount: answers.filter(a => a.isCorrect).length,
  answeredCount: answers.length,
  totalQuestions: total,
  score: total ? Math.round(100 * answers.filter(a => a.isCorrect).length / total) : 0,
});
async function endExamSection(db: Prisma.TransactionClient, session: any) {
  const c=session.examConfig as any;const i=c.sectionIndex;
  if(i+1>=c.sections.length){await finish(db,session);return;}
  const next=c.sections[i+1];
  await db.learningSession.update({where:{id:session.id},data:{currentIndex:session.questionIds.indexOf(next.questionIds[0]),awaitingNext:false,examConfig:{...c,waitingSection:true,deadline:null}}});
}
async function clockSync(db: Prisma.TransactionClient,id:string,userId:string) {
  const s=await db.learningSession.findFirst({where:{id,userId}});
  const c=s?.examConfig as any;
  if(s&&!s.completedAt&&c&&!c.waitingSection&&c.deadline&&Date.now()>=Date.parse(c.deadline))await endExamSection(db,s);
}
async function advance(db:Prisma.TransactionClient,session:any) {
  const c=session.examConfig as any;
  if(c){
    const section=c.sections[c.sectionIndex];
    if(section.questionIds[section.questionIds.length-1]===session.questionIds[session.currentIndex]){await endExamSection(db,session);return;}
  }
  if(session.currentIndex+1===session.questionIds.length)await finish(db,session);
  else await db.learningSession.update({where:{id:session.id},data:{currentIndex:{increment:1},awaitingNext:false}});
}
async function state(db: Prisma.TransactionClient, id: string, userId: string) {
  await clockSync(db,id,userId);
  const session = await db.learningSession.findFirst({ where: { id, userId }, include: { answers: { orderBy: { answeredAt: 'asc' } } } });
  if (!session) throw new HttpError(404, '练习不存在');
  const questionIds = ids(session.questionIds);
  const qs = await db.question.findMany({ where: { id: { in: questionIds } } });
  const es = session.answers.length ? await db.explanation.findMany({ where: { questionId: { in: session.answers.map(a => a.questionId) } } }) : [];
  const activity=session.collectionId?await db.funPaper.findUnique({where:{id:session.collectionId}}):null;
  const config=session.examConfig as any;
  const hide=config&&!config.instantFeedback&&!session.completedAt;
  return {
    ...session, activity, serverNow:new Date().toISOString(), ...points(session.answers, questionIds.length),
    questions: questionIds.map(qid => publicQuestion(qs.find(q => q.id === qid))),
    ...(hide?{score:null,correctCount:null}:{}),
    answers: session.answers.map(a => hide ? {questionId:a.questionId,selectedOptionId:a.selectedOptionId,answeredAt:a.answeredAt} : ({ ...a, correctOptionId: qs.find(q => q.id === a.questionId)!.answer, explanation: es.find(e => e.questionId === a.questionId) ?? null })),
  };
}
async function finish(db: Prisma.TransactionClient, session: any) {
  const answers = await db.learningAnswer.findMany({ where: { sessionId: session.id } });
  if (!session.examConfig && answers.length !== session.questionIds.length) throw new HttpError(409, '请完成全部题目后查看总分');
  const now = new Date();
  await db.learningSession.update({ where: { id: session.id }, data: { completedAt: now, awaitingNext: false } });
  const p = points(answers, session.questionIds.length);
  await db.examRecord.upsert({ where: { id: session.id }, update: {}, create: {
    id: session.id, userId: session.userId, level: session.level,
    recordType: session.mode === 'exam' ? 'exam' : 'practice', questionIds: session.questionIds,
    answers: answers.map(a => ({questionId:a.questionId,selectedOptionId:a.selectedOptionId,isCorrect:a.isCorrect})),
    totalQuestions: p.totalQuestions, correctCount: p.correctCount, score: p.score,
    durationMs: now.getTime() - session.createdAt.getTime(),
  } });
}

// A genuine local learner account, persisted in PostgreSQL; never a demo profile.
router.post('/guest', run(async (_req, res) => {
  const id = randomUUID();
  const user = await prisma.user.create({ data: { id, email: `${id}@local.invalid`, name: '本机学习者', passwordHash: await bcrypt.hash(randomUUID(), 10) } });
  const token = jwt.sign({ userId: id }, config.jwtSecret, { expiresIn: '365d' });
  res.status(201).json({ token, user: { id, name: user.name } });
}));
router.get('/catalog', run(async (_req, res) => {
  const groups = await prisma.question.groupBy({ by: ['level', 'type'], where: verified, _count: { _all: true } });
  res.json({ total: groups.reduce((s, g) => s + g._count._all, 0), groups: groups.map(g => ({ level: g.level, type: g.type, count: g._count._all })) });
}));
router.get('/exam-papers',run(async(_req,res)=>{
  const papers=await prisma.examPaper.findMany({orderBy:[{examYear:'desc'},{level:'desc'}]});
  res.json({papers,timingSource,rules:Object.fromEntries(['n5','n4','n3','n2','n1'].map(l=>[l,examSections(l)]))});
}));
router.get('/fun-papers',run(async(_req,res)=>{
 const novel=await prisma.novelLesson.findMany({select:{paperId:true}});
 const reading=await prisma.readingArticle.findMany({select:{paperId:true}});
 const papers=await prisma.funPaper.findMany({where:{published:true,id:{notIn:[...novel.map(l=>l.paperId),...reading.map(l=>l.paperId)]}},orderBy:{id:'asc'}});
 const qs=await prisma.question.findMany({where:{id:{in:papers.flatMap(p=>ids(p.questionIds))},source:'custom'},select:{id:true}});
 const known=new Set(qs.map(q=>q.id));
 res.json({papers:papers.map(p=>({...p,questionCount:ids(p.questionIds).filter(id=>known.has(id)).length,ready:ids(p.questionIds).length>0&&ids(p.questionIds).every(id=>known.has(id))})),label:'用户素材改编练习，非JLPT真题，不作等级认证'});
}));
router.get('/novel-lessons',run(async(_req,res)=>{
 const rows=await prisma.readingArticle.findMany({orderBy:{position:'asc'}});
 res.json({title:'小说词汇阅读与练习',attribution:rows[0]?.attribution??null,sourceTitle:rows[0]?.sourceTitle??null,sourcePages:rows[0]?.sourcePages??0,
 lessons:rows.map(({pages,vocabulary,...article})=>({...article,vocabularyCount:(vocabulary as any[]).length}))});
}));
router.get('/novel-lessons/:id',run(async(req,res)=>{
 const l=await prisma.readingArticle.findUnique({where:{id:req.params.id as string}});
 if(!l)throw new HttpError(404,'小说章节不存在');
 res.json(l);
}));
router.get('/materials',run(async(_req,res)=>{
 const rows=await prisma.studyMaterial.findMany({select:{id:true,title:true,collection:true,textStatus:true,japanese:true,videoUrl:true,audioLinks:{orderBy:{position:'asc'},include:{audio:{select:{id:true,title:true,url:true,durationSeconds:true}}}}},orderBy:[{collection:'asc'},{id:'asc'}]});
 const items=rows.map(({audioLinks,japanese,...item})=>({...item,hasText:!!japanese,audios:audioLinks.map(l=>l.audio)}));
 res.json({items,total:items.length,audioCount:items.filter(i=>i.audios.length).length,videoCount:items.filter(i=>i.videoUrl).length});
}));
router.get('/materials/:id',run(async(req,res)=>{
 const m=await prisma.studyMaterial.findUnique({where:{id:req.params.id as string},include:{audioLinks:{orderBy:{position:'asc'},include:{audio:true}}}});
 if(!m)throw new HttpError(404,'素材不存在');
 const {sourcePath,...metadata}=m.metadata as any;
 const {audioLinks,filename,fileUrl,sha256,audioUrl,...article}=m;
 res.json({...article,metadata,audios:audioLinks.map(l=>l.audio)});
}));
router.use(authMiddleware);
router.get('/dashboard', run(async (req, res) => {
  const [user, sessions, attempts] = await Promise.all([
    prisma.user.findUniqueOrThrow({ where: { id: req.userId }, select: { id: true, name: true, createdAt: true } }),
    prisma.learningSession.findMany({ where: { userId: req.userId }, orderBy: { createdAt: 'desc' }, include: { answers: true } }),
    prisma.learningAnswer.findMany({ where: { session: { userId: req.userId,OR:[{mode:{not:'exam'}},{completedAt:{not:null}}] } }, select: { isCorrect: true } }),
  ]);
  const activities=await prisma.funPaper.findMany({where:{id:{in:sessions.flatMap(s=>s.collectionId?[s.collectionId]:[])}}});
  const done = sessions.filter(s => s.completedAt);
  res.json({ user, totalAnswered: attempts.length, correctCount: attempts.filter(a => a.isCorrect).length, wrongCount: attempts.filter(a => !a.isCorrect).length,
    completedSessions: done.length, accuracy: attempts.length ? attempts.filter(a => a.isCorrect).length / attempts.length : null,
    sessions: sessions.map(({answers, ...s}) => ({...s,activityTitle:activities.find(p=>p.id===s.collectionId)?.title??null,...points(answers,ids(s.questionIds).length)})) });
}));
const startSchema = z.object({ level: z.enum(['n1','n2','n3','n4','n5']), type: z.enum(['vocabulary','kanji','grammar','reading','listening','fillInBlank','comprehensive']).optional(), limit: z.number().int().min(1).max(200).optional(), mode: z.enum(['practice','exam','fun']).default('practice'), paperId:z.string().optional(), collectionId:z.string().optional(), instantFeedback:z.boolean().default(false) });
router.post('/sessions', run(async (req, res) => {
  const data = startSchema.parse(req.body);
  if(data.mode==='fun'){
    const paper=data.collectionId?await prisma.funPaper.findUnique({where:{id:data.collectionId}}):null;
    if(!paper?.published)throw new HttpError(404,'趣味题组不存在');
    const paperQuestionIds=ids(paper.questionIds);
    const qs=await prisma.question.findMany({where:{id:{in:paperQuestionIds},source:'custom',level:'ungraded'}});
    if(qs.length!==paperQuestionIds.length||!qs.length)throw new HttpError(409,'题组尚未完整入库');
    const session=await prisma.learningSession.create({data:{userId:req.userId!,level:'ungraded',mode:'fun',collectionId:paper.id,questionIds:paperQuestionIds}});
    res.status(201).json(await state(prisma,session.id,req.userId!));return;
  }
  if(data.mode==='exam'){
    const paper=data.paperId?await prisma.examPaper.findUnique({where:{id:data.paperId}}):null;
    if(!paper?.ready)throw new HttpError(400,'完整试卷尚未通过校验：必须具备所有科目、标准答案和听力材料');
    const config=examConfig(paper,data.instantFeedback);const questionIds=config.sections.flatMap((s:any)=>s.questionIds);
    if(data.instantFeedback){const count=await prisma.explanation.count({where:{questionId:{in:questionIds},sentenceStructure:{not:''}}});if(count!==questionIds.length)throw new HttpError(400,'本卷尚有题目缺少已核验讲解，请关闭即时讲解或补齐讲解后开始');}
    const s=await prisma.learningSession.create({data:{userId:req.userId!,level:paper.level,mode:'exam',questionIds,examConfig:config}});
    res.status(201).json(await state(prisma,s.id,req.userId!));return;
  }
  const qs = await prisma.question.findMany({ where: { ...verified, level: data.level, ...(data.type ? { type: data.type } : {}) }, orderBy: [{order:'asc'},{id:'asc'}], ...(data.limit ? {take:data.limit} : {}) });
  if (!qs.length) throw new HttpError(400, '该等级和题型暂无已核验题目');
  const session = await prisma.learningSession.create({ data: { userId: req.userId!, level: data.level, mode: data.mode, questionIds: qs.map(q => q.id) } });
  res.status(201).json(await state(prisma, session.id, req.userId!));
}));
router.get('/sessions/:id', run(async (req, res) => res.json(await state(prisma, req.params.id as string, req.userId!))));
router.post('/sessions/:id/answers', run(async (req, res) => {
  const body = z.object({ questionId: z.string(), optionId: z.string() }).parse(req.body);
  const result = await prisma.$transaction(async db => {
    await clockSync(db,req.params.id as string,req.userId!);
    const s = await db.learningSession.findFirst({ where: { id: req.params.id as string, userId: req.userId }, include: { answers: true } });
    if (!s) throw new HttpError(404, '练习不存在');
    if (s.answers.some(a => a.questionId === body.questionId)) throw new HttpError(409, '本题已作答，首次答案已锁定，不能重答');
    if ((s.examConfig as any)?.waitingSection)throw new HttpError(409,'请先开始下一科目');
    if (s.completedAt || s.awaitingNext || ids(s.questionIds)[s.currentIndex] !== body.questionId) throw new HttpError(409, '请按顺序完成当前题目');
    const q = await db.question.findUniqueOrThrow({ where: { id: body.questionId } });
    if (!(q.options as any[]).some(o => o.id === body.optionId)) throw new HttpError(400, '选项无效');
    const correct = q.answer === body.optionId;
    await db.learningAnswer.create({ data: { sessionId: s.id, questionId: q.id, selectedOptionId: body.optionId, isCorrect: correct } });
    const c=s.examConfig as any;
    if(!correct&&(!c||c.instantFeedback))await db.learningSession.update({where:{id:s.id},data:{awaitingNext:true}});
    else await advance(db,s);
    return state(db,s.id,req.userId!);
  }, { isolationLevel:'Serializable' });
  res.json(result);
}));
router.post('/sessions/:id/next', run(async (req, res) => {
  const result = await prisma.$transaction(async db => {
    const s = await db.learningSession.findFirst({ where: { id:req.params.id as string,userId:req.userId } });
    if (!s) throw new HttpError(404,'练习不存在');
    if (s.completedAt || !s.awaitingNext) throw new HttpError(409,'当前题目尚未完成');
    await clockSync(db,s.id,req.userId!);
    const fresh=await db.learningSession.findUniqueOrThrow({where:{id:s.id}});
    if(!fresh.completedAt&&!(fresh.examConfig as any)?.waitingSection)await advance(db,fresh);
    return state(db,s.id,req.userId!);
  },{isolationLevel:'Serializable'});
  res.json(result);
}));
router.post('/sessions/:id/section',run(async(req,res)=>{
 const action=z.enum(['start','submit']).parse(req.body.action);
 res.json(await prisma.$transaction(async db=>{
  await clockSync(db,req.params.id as string,req.userId!);
  const s=await db.learningSession.findFirst({where:{id:req.params.id as string,userId:req.userId}});
  if(!s||s.completedAt||!s.examConfig)throw new HttpError(409,'考试状态不可用');
  const c=s.examConfig as any;
  if(action==='submit'){
   if(c.waitingSection)throw new HttpError(409,'本科目已结束');
   await endExamSection(db,s);
  }else{
   if(!c.waitingSection)throw new HttpError(409,'科目已经开始');
   const i=c.sectionIndex+1;const now=Date.now();
   await db.learningSession.update({where:{id:s.id},data:{examConfig:{...c,sectionIndex:i,waitingSection:false,sectionStartedAt:new Date(now).toISOString(),deadline:new Date(now+c.sections[i].minutes*60000).toISOString()}}});
  }
  return state(db,s.id,req.userId!);
 },{isolationLevel:'Serializable'}));
}));
router.get('/mistakes', run(async (req,res) => {
  const answers=await prisma.learningAnswer.findMany({where:{isCorrect:false,session:{userId:req.userId,OR:[{mode:{not:'exam'}},{completedAt:{not:null}}]}},orderBy:{answeredAt:'desc'},include:{question:true}});
  const es=await prisma.explanation.findMany({where:{questionId:{in:answers.map(a=>a.questionId)}}});
  res.json({items:answers.map(a=>({...a,question:a.question,explanation:es.find(e=>e.questionId===a.questionId)??null}))});
}));
export default router;
