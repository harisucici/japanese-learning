import express from 'express';
import path from 'path';
import cors from 'cors';
import morgan from 'morgan';
import { config } from './config/env';
import { envelopeResponse } from './utils/response';

import learningRoutes from './routes/learning.routes';
import practiceRoutes from './routes/practice.routes';

import authRoutes from './routes/auth.routes';
import questionRoutes from './routes/question.routes';
import recordRoutes from './routes/record.routes';
import reviewRoutes from './routes/review.routes';
import explanationRoutes from './routes/explanation.routes';
import statsRoutes from './routes/stats.routes';
import vocabularyRoutes from './routes/vocabulary.routes';
import grammarRoutes from './routes/grammar.routes';
import adminRoutes from './routes/admin.routes';
import ttsRoutes from './routes/tts.routes';

const app = express();

app.use(cors({ origin: (origin, done) => done(null, !origin || config.frontendOrigins.includes(origin)), credentials: true }));
app.use(express.json());
app.use(envelopeResponse());
app.use('/api/v1', (_req, res, next) => { res.setHeader('Cache-Control', 'no-store'); next(); });
app.use('/study-assets',express.static(path.join(__dirname,'../data/study-assets')));
app.use('/exam-assets',express.static(path.join(__dirname,'../data/exam-assets')));
app.use(morgan('dev'));

app.use('/api/v1/learning', learningRoutes);
app.use('/api/v1/practice', practiceRoutes);

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/questions', questionRoutes);
app.use('/api/v1/records', recordRoutes);
app.use('/api/v1/review', reviewRoutes);
app.use('/api/v1/explanations', explanationRoutes);
app.use('/api/v1/stats', statsRoutes);
app.use('/api/v1/vocabulary', vocabularyRoutes);
app.use('/api/v1/grammar', grammarRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/tts', ttsRoutes);

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

if (config.serveFrontend) {
  const siteDirectory = path.resolve(__dirname, '../../ja-learning-platform/dist');
  app.use(express.static(siteDirectory, { index: false }));
  app.get('*', (req, res, next) => {
    if (req.path.startsWith('/api/') || req.path.startsWith('/study-assets/') || req.path.startsWith('/exam-assets/')) return next();
    res.setHeader('Cache-Control', 'no-store');
    res.sendFile(path.join(siteDirectory, 'index.html'));
  });
}

app.use((_req, res) => {
  res.status(404).json({ error: '未找到该文件', message: '未找到该文件' });
});

// Global error handler — must be last middleware
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const { normalizeErrorBody, codeForStatus } = require('./utils/response');
  const status = typeof err?.status === 'number' ? err.status : 500;
  const message = status === 500 ? '服务暂时不可用，请重试' : (err?.message || '未知错误');
  const normalized = normalizeErrorBody(message);
  normalized.code = codeForStatus(status, normalized.code);
  res.status(status).json({ success: false, error: normalized });
});

export default app;
