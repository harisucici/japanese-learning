/**
 * 初始化远程用户数据库的 InviteCode 表
 * 并生成50个8位邀请码
 */
const { createClient } = require('@libsql/client');
require('dotenv').config();

async function initInviteCodeTable() {
  if (!process.env.USER_TURSO_URL) {
    console.error('❌ USER_TURSO_URL 环境变量未设置');
    process.exit(1);
  }

  const client = createClient({
    url: process.env.USER_TURSO_URL,
    authToken: process.env.USER_TURSO_AUTH_TOKEN
  });

  try {
    console.log('📋 正在创建 InviteCode 表...');
    
    // 创建 InviteCode 表
    await client.execute(`
      CREATE TABLE IF NOT EXISTS "InviteCode" (
        "id" TEXT PRIMARY KEY NOT NULL,
        "code" TEXT NOT NULL UNIQUE,
        "used" BOOLEAN NOT NULL DEFAULT false,
        "usedBy" TEXT,
        "usedAt" DATETIME,
        "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY ("usedBy") REFERENCES "User"("id") ON DELETE SET NULL
      )
    `);

    // 创建唯一索引
    await client.execute(`
      CREATE UNIQUE INDEX IF NOT EXISTS "InviteCode_code_key" ON "InviteCode"("code")
    `);

    console.log('✅ InviteCode 表创建成功');

    // 生成50个8位邀请码（只包含大写字母和数字，排除易混淆字符）
    const codes = [];
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 排除 0,1,I,L,O
    
    for (let i = 0; i < 50; i++) {
      let code = '';
      for (let j = 0; j < 8; j++) {
        code += chars[Math.floor(Math.random() * chars.length)];
      }
      codes.push({
        id: `inv_${Date.now()}_${i}`,
        code: code
      });
    }

    console.log('📝 正在插入50个邀请码...');

    // 批量插入
    const values = codes.map(c => `('${c.id}', '${c.code}')`).join(',');
    await client.execute(`
      INSERT INTO "InviteCode" ("id", "code") VALUES ${values}
    `);

    console.log('✅ 50个邀请码已生成并插入数据库');
    console.log('\n📋 邀请码列表:');
    codes.forEach((c, i) => {
      console.log(`${i + 1}. ${c.code}`);
    });

    console.log('\n✨ 初始化完成！');

  } catch (error) {
    console.error('❌ 错误:', error);
    process.exit(1);
  } finally {
    await client.close();
  }
}

initInviteCodeTable();
