/**
 * 管理端控制器
 * 处理内容管理相关的 HTTP 请求
 */
import { Request, Response } from 'express';
import { ContentService } from '../services/content.service';

const svc = new ContentService();

export class AdminController {
  /**
   * GET /admin/questions - 查询所有题目（支持分页、过滤）
   */
  async listQuestions(req: Request, res: Response) {
    try {
      const { level, type, status, source, limit, offset } = req.query;
      const parsedLimit = limit ? parseInt(limit as string, 10) : 20;
      const parsedOffset = offset ? parseInt(offset as string, 10) : 0;
      const result = await svc.list({
        level: level as string | undefined,
        type: type as string | undefined,
        status: status as string | undefined,
        source: source as string | undefined,
        limit: parsedLimit,
        offset: parsedOffset,
      });
      res.json({ ...result, limit: parsedLimit, offset: parsedOffset });
    } catch (e: any) {
      console.error('List questions error:', e);
      res.status(e.status || 500).json({ error: e.message });
    }
  }

  /**
   * GET /admin/questions/:id - 查询题目详情
   */
  async getQuestion(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const item = await svc.getById(id);
      if (!item) return res.status(404).json({ error: '题目不存在' });
      res.json(item);
    } catch (e: any) {
      console.error('Get question error:', e);
      res.status(500).json({ error: e.message });
    }
  }

  /**
   * PUT /admin/questions/:id - 更新题目
   */
  async updateQuestion(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const data = req.body;
      const item = await svc.update(id, data);
      if (!item) return res.status(404).json({ error: '题目不存在' });
      res.json(item);
    } catch (e: any) {
      console.error('Update question error:', e);
      res.status(500).json({ error: e.message });
    }
  }

  /**
   * DELETE /admin/questions/:id - 软删除题目
   */
  async deleteQuestion(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const item = await svc.delete(id);
      if (!item) return res.status(404).json({ error: '题目不存在' });
      res.json({ success: true, message: '题目已删除' });
    } catch (e: any) {
      console.error('Delete question error:', e);
      res.status(500).json({ error: e.message });
    }
  }

  /**
   * POST /admin/questions/:id/publish - 发布题目
   */
  async publishQuestion(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const item = await svc.publish(id);
      if (!item) return res.status(404).json({ error: '题目不存在' });
      res.json({ success: true, message: '题目已发布' });
    } catch (e: any) {
      console.error('Publish question error:', e);
      res.status(e.status || 500).json({ error: e.message });
    }
  }

  /**
   * POST /admin/questions/:id/unpublish - 撤回题目
   */
  async unpublishQuestion(req: Request, res: Response) {
    try {
      const id = req.params.id as string;
      const item = await svc.unpublish(id);
      if (!item) return res.status(404).json({ error: '题目不存在' });
      res.json({ success: true, message: '题目已撤回' });
    } catch (e: any) {
      console.error('Unpublish question error:', e);
      res.status(500).json({ error: e.message });
    }
  }
}
