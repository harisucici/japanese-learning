const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function updateFurigana() {
  const data = JSON.parse(fs.readFileSync(
    path.join(__dirname, '..', 'data', 'short-essay-extracted.json'),
    'utf8'
  ));

  console.log(`找到 ${data.length} 条记录需要更新`);

  let updated = 0;
  let skipped = 0;

  for (const entry of data) {
    const materialId = `material-${100 + entry.number}`;

    // 检查数据库中当前的假名
    const current = await prisma.studyMaterial.findUnique({
      where: { id: materialId },
      select: { japanese: true }
    });

    if (!current) {
      console.log(`跳过 ${materialId}: 数据库中不存在`);
      skipped++;
      continue;
    }

    const currentCount = (current.japanese.match(/\[.*?\]/g) || []).length;
    const newCount = (entry.japanese.match(/\[.*?\]/g) || []).length;

    // 如果新数据的标注数量更多，则更新
    if (newCount > currentCount) {
      await prisma.studyMaterial.update({
        where: { id: materialId },
        data: { japanese: entry.japanese }
      });
      console.log(`✓ 更新 ${materialId} (${entry.title}): ${currentCount} -> ${newCount} 个标注`);
      updated++;
    } else {
      console.log(`= 跳过 ${materialId} (${entry.title}): ${currentCount} >= ${newCount}`);
      skipped++;
    }
  }

  console.log(`\n完成: 更新 ${updated} 条, 跳过 ${skipped} 条`);
  await prisma.$disconnect();
}

updateFurigana().catch(err => {
  console.error('更新失败:', err);
  process.exit(1);
});
