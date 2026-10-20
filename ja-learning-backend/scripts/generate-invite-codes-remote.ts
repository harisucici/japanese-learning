/**
 * 通过 userPrisma（连接 USER_TURSO_URL）生成50个邀请码
 */
import userPrisma from '../src/config/user-database.js';

function generateCode(length: number = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < length; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
}

async function main() {
  console.log('📋 清空现有邀请码...');
  await userPrisma.inviteCode.deleteMany();

  const codes: string[] = [];
  for (let i = 0; i < 50; i++) {
    let code = generateCode(8);
    while (codes.includes(code)) {
      code = generateCode(8);
    }
    codes.push(code);
  }

  console.log('📝 正在插入50个邀请码...');
  await userPrisma.inviteCode.createMany({
    data: codes.map(code => ({ code })),
  });

  console.log('✅ 50个邀请码已生成！\n');
  codes.forEach((code, i) => {
    console.log(`${String(i + 1).padStart(2, ' ')}. ${code}`);
  });

  // 验证
  const count = await userPrisma.inviteCode.count();
  console.log(`\n数据库中共 ${count} 个邀请码`);

  await userPrisma.$disconnect();
}

main().catch(e => {
  console.error('❌ 错误:', e);
  process.exit(1);
});
