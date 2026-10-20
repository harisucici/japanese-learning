#!/usr/bin/env node
/**
 * 测试导入 API 脚本
 * 使用方法: node scripts/test-import.js
 */

const fs = require('fs');
const path = require('path');
const http = require('http');

const API_BASE_URL = 'http://localhost:3000';
const ADMIN_API_KEY = process.env.ADMIN_API_KEY || 'test-admin-key';

// 读取示例数据
const sampleDataPath = path.join(__dirname, 'sample-import.json');
const sampleData = JSON.parse(fs.readFileSync(sampleDataPath, 'utf-8'));

/**
 * 发送 HTTP 请求
 */
function makeRequest(method, path, data = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, API_BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'x-admin-key': ADMIN_API_KEY,
      },
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }

    req.end();
  });
}

/**
 * 主测试流程
 */
async function main() {
  console.log('🧪 开始测试导入 API...\n');

  try {
    // 1. 测试导入接口
    console.log('📥 步骤 1: 测试导入 API');
    console.log(`   导入 ${sampleData.items.length} 条题目...`);

    const importResult = await makeRequest('POST', '/api/v1/admin/import/questions', sampleData);

    console.log(`   状态码: ${importResult.status}`);
    console.log(`   结果:`, JSON.stringify(importResult.data, null, 2));

    if (importResult.status !== 200) {
      console.error('❌ 导入失败');
      process.exit(1);
    }

    console.log(`   ✅ 导入成功\n`);

    // 2. 测试查询所有题目
    console.log('📋 步骤 2: 测试查询所有题目');
    const listResult = await makeRequest('GET', '/api/v1/admin/questions?limit=5');

    console.log(`   状态码: ${listResult.status}`);
    console.log(`   总数: ${listResult.data.total}`);
    console.log(`   返回: ${listResult.data.items.length} 条`);

    if (listResult.status !== 200) {
      console.error('❌ 查询失败');
      process.exit(1);
    }

    console.log(`   ✅ 查询成功\n`);

    // 3. 测试查询单个题目
    if (listResult.data.items.length > 0) {
      const questionId = listResult.data.items[0].id;

      console.log('🔍 步骤 3: 测试查询题目详情');
      console.log(`   题目 ID: ${questionId}`);

      const detailResult = await makeRequest('GET', `/api/v1/admin/questions/${questionId}`);

      console.log(`   状态码: ${detailResult.status}`);

      if (detailResult.status !== 200) {
        console.error('❌ 查询详情失败');
        process.exit(1);
      }

      console.log(`   题目内容: ${detailResult.data.content}`);
      console.log(`   解析翻译: ${detailResult.data.explanation?.translation}`);
      console.log(`   ✅ 查询详情成功\n`);

      // 4. 测试更新题目
      console.log('✏️  步骤 4: 测试更新题目');
      const updateResult = await makeRequest('PUT', `/api/v1/admin/questions/${questionId}`, {
        difficulty: 0.8,
        tags: ['updated', 'test'],
      });

      console.log(`   状态码: ${updateResult.status}`);

      if (updateResult.status !== 200) {
        console.error('❌ 更新失败');
        process.exit(1);
      }

      console.log(`   新难度: ${updateResult.data.difficulty}`);
      console.log(`   新标签: ${JSON.stringify(updateResult.data.tags)}`);
      console.log(`   ✅ 更新成功\n`);

      // 5. 测试发布题目
      console.log('📢 步骤 5: 测试发布题目');
      const publishResult = await makeRequest('POST', `/api/v1/admin/questions/${questionId}/publish`);

      console.log(`   状态码: ${publishResult.status}`);

      if (publishResult.status !== 200) {
        console.error('❌ 发布失败');
        process.exit(1);
      }

      console.log(`   消息: ${publishResult.data.message}`);
      console.log(`   ✅ 发布成功\n`);

      // 6. 测试撤回题目
      console.log('🔙 步骤 6: 测试撤回题目');
      const unpublishResult = await makeRequest('POST', `/api/v1/admin/questions/${questionId}/unpublish`);

      console.log(`   状态码: ${unpublishResult.status}`);

      if (unpublishResult.status !== 200) {
        console.error('❌ 撤回失败');
        process.exit(1);
      }

      console.log(`   消息: ${unpublishResult.data.message}`);
      console.log(`   ✅ 撤回成功\n`);

      // 7. 测试软删除题目
      console.log('🗑️  步骤 7: 测试软删除题目');
      const deleteResult = await makeRequest('DELETE', `/api/v1/admin/questions/${questionId}`);

      console.log(`   状态码: ${deleteResult.status}`);

      if (deleteResult.status !== 200) {
        console.error('❌ 删除失败');
        process.exit(1);
      }

      console.log(`   消息: ${deleteResult.data.message}`);
      console.log(`   ✅ 删除成功\n`);

      // 8. 验证软删除（查询应该返回 404）
      console.log('🔍 步骤 8: 验证软删除效果');
      const verifyResult = await makeRequest('GET', `/api/v1/admin/questions/${questionId}`);

      console.log(`   状态码: ${verifyResult.status}`);

      if (verifyResult.status !== 404) {
        console.error('❌ 软删除验证失败（应该返回 404）');
        process.exit(1);
      }

      console.log(`   ✅ 软删除验证成功（题目已不可见）\n`);
    }

    // 9. 测试数据校验（导入无效数据）
    console.log('🚫 步骤 9: 测试数据校验');
    const invalidData = {
      items: [
        {
          question: {
            level: 'n5',
            type: 'vocabulary',
            content: '测试题目',
            options: [
              { id: 'opt1', content: '选项1' },
              { id: 'opt2', content: '选项2' },
            ],
            answer: 'opt3', // 答案不在选项中
            explanationId: 'exp-invalid',
          },
          explanation: {
            translation: '测试翻译',
          },
        },
      ],
    };

    const validationTest = await makeRequest('POST', '/api/v1/admin/import/questions', invalidData);

    console.log(`   状态码: ${validationTest.status}`);
    console.log(`   失败数: ${validationTest.data.failed}`);
    console.log(`   错误原因: ${validationTest.data.errors?.[0]?.reason}`);

    if (validationTest.data.failed !== 1) {
      console.error('❌ 数据校验测试失败（应该捕获到验证错误）');
      process.exit(1);
    }

    console.log(`   ✅ 数据校验测试成功\n`);

    // 10. 测试认证（无 API Key）
    console.log('🔒 步骤 10: 测试认证中间件');
    const authTest = await makeRequest('GET', '/api/v1/admin/questions?limit=1');

    // 清除 API Key 再测试
    delete authTest;
    const noAuthResult = await new Promise((resolve) => {
      const url = new URL('/api/v1/admin/questions?limit=1', API_BASE_URL);
      const req = http.request(
        {
          hostname: url.hostname,
          port: url.port,
          path: url.pathname + url.search,
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            // 不发送 x-admin-key
          },
        },
        (res) => {
          let body = '';
          res.on('data', (chunk) => (body += chunk));
          res.on('end', () => resolve({ status: res.statusCode, data: JSON.parse(body) }));
        }
      );
      req.end();
    });

    console.log(`   无认证状态码: ${noAuthResult.status}`);

    if (noAuthResult.status !== 403) {
      console.error('❌ 认证测试失败（应该返回 403）');
      process.exit(1);
    }

    console.log(`   错误信息: ${noAuthResult.data.error}`);
    console.log(`   ✅ 认证测试成功\n`);

    // 完成
    console.log('═══════════════════════════════════════');
    console.log('✅ 所有测试通过！');
    console.log('═══════════════════════════════════════');
  } catch (error) {
    console.error('❌ 测试过程中发生错误:', error.message);
    console.error('   提示: 请确保后端服务已启动 (npm run dev)');
    process.exit(1);
  }
}

main();
