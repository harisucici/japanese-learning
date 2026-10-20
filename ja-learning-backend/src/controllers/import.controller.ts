/**
 * 导入控制器
 * 处理题库导入相关的 HTTP 请求
 */
import { Request, Response } from 'express';
import { ImportService } from '../services/import.service';

const svc = new ImportService();

export class ImportController {
  /**
   * POST /admin/import/questions - 批量导入题目
   * 请求体格式: { items: Array<ImportQuestionInput> }
   */
  async importQuestions(req: Request, res: Response) {
    try {
      const { items } = req.body;

      // 验证输入格式
      if (!Array.isArray(items)) {
        return res.status(400).json({ error: '请求体必须包含 items 数组' });
      }

      if (items.length === 0) {
        return res.status(400).json({ error: 'items 数组不能为空' });
      }

      // 执行导入
      const result = await svc.importQuestions(items);

      const { success: successCount, ...rest } = result;
      res.json({
        success: true,
        message: `导入完成：成功 ${successCount} 条，失败 ${rest.failed} 条，跳过 ${rest.skipped} 条`,
        ...rest,
        successCount,
      });
    } catch (e: any) {
      console.error('Import questions error:', e);
      res.status(500).json({ error: e.message });
    }
  }
}
