#!/usr/bin/env node
/**
 * Cloudinary 音频批量上传脚本
 * 上传 200 个音频文件到 Cloudinary，并更新数据库 StudyMaterial 的 audioUrl
 *
 * 编号映射：
 *   - audio-001 ~ audio-100 → 附赠100篇（音频+PDF）编号 1-100
 *   - audio-101 ~ audio-200 → 短文视频 编号 1-100
 */

require('dotenv').config();
const cloudinary = require('cloudinary').v2;
const path = require('path');
const fs = require('fs');

// 配置 Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

const AUDIO_DIR = path.join(__dirname, '..', 'data', 'audio');
const MANIFEST_PATH = path.join(AUDIO_DIR, 'audio-manifest.json');
const CONCURRENCY = 5;
const TOTAL = 200;

// 已上传文件的路径记录（用于断点续传）
const PROGRESS_PATH = path.join(__dirname, '..', 'data', 'audio', '.upload-progress.json');

function loadProgress() {
  try {
    if (fs.existsSync(PROGRESS_PATH)) {
      return JSON.parse(fs.readFileSync(PROGRESS_PATH, 'utf8'));
    }
  } catch (e) { /* ignore */ }
  return {};
}

function saveProgress(progress) {
  fs.writeFileSync(PROGRESS_PATH, JSON.stringify(progress, null, 2));
}

async function uploadOne(filename, progress) {
  const publicId = filename.replace('.mp3', '');
  const filePath = path.join(AUDIO_DIR, filename);

  // 断点续传：如果已有记录，跳过
  if (progress[publicId] && progress[publicId].secure_url) {
    return progress[publicId];
  }

  const result = await cloudinary.uploader.upload(filePath, {
    resource_type: 'video',
    folder: 'ja-learning/audio',
    public_id: publicId,
    format: 'mp3',
    overwrite: false
  });

  const record = {
    filename,
    public_id: result.public_id,
    secure_url: result.secure_url,
    bytes: result.bytes,
    duration: result.duration
  };

  progress[publicId] = record;
  return record;
}

async function runBatch(items, progress, startIdx) {
  const results = [];
  // 按 CONCURRENCY 分批
  for (let i = 0; i < items.length; i += CONCURRENCY) {
    const batch = items.slice(i, i + CONCURRENCY);
    const batchResults = await Promise.all(
      batch.map(async (item, j) => {
        const idx = startIdx + i + j + 1;
        try {
          const r = await uploadOne(item.filename, progress);
          console.log(`[${String(idx).padStart(3, '0')}/${TOTAL}] ✅ ${item.filename}`);
          return r;
        } catch (err) {
          console.error(`[${String(idx).padStart(3, '0')}/${TOTAL}] ❌ ${item.filename}: ${err.message}`);
          return { filename: item.filename, error: err.message };
        }
      })
    );
    results.push(...batchResults);
    // 每批完成后保存进度
    saveProgress(progress);
  }
  return results;
}

async function updateDatabase(urlMap) {
  // 尝试更新数据库 StudyMaterial 表
  try {
    const { PrismaClient } = require('@prisma/client');
    const prisma = new PrismaClient();

    const count = await prisma.studyMaterial.count();
    console.log(`\n📊 StudyMaterial 记录数: ${count}`);

    if (count === 0) {
      console.log('⚠️  StudyMaterial 表为空，跳过数据库更新');
      console.log('   所有上传 URL 已保存到 data/audio/.upload-progress.json');
      await prisma.$disconnect();
      return 0;
    }

    let updated = 0;
    // 遍历所有记录，按 filename 匹配更新 audioUrl
    const materials = await prisma.studyMaterial.findMany({
      select: { id: true, filename: true, audioUrl: true }
    });

    for (const m of materials) {
      // 匹配逻辑： StudyMaterial.filename 可能是音频文件名或对应素材名
      // 尝试通过 audioUrl 对应的 audio-XXX 格式匹配
      const audioFilename = m.audioUrl ? path.basename(m.audioUrl) : null;

      // 如果 audioUrl 已经指向某个 audio-XXX.mp3
      if (audioFilename && /^audio-\d+\.mp3$/.test(audioFilename)) {
        const publicId = audioFilename.replace('.mp3', '');
        const newUrl = urlMap[publicId];
        if (newUrl && newUrl !== m.audioUrl) {
          await prisma.studyMaterial.update({
            where: { id: m.id },
            data: { audioUrl: newUrl }
          });
          updated++;
        }
      }
    }

    console.log(`\n📝 已更新 ${updated} 条 StudyMaterial 记录的 audioUrl`);
    await prisma.$disconnect();
    return updated;
  } catch (err) {
    console.error(`\n⚠️  数据库更新失败: ${err.message}`);
    return 0;
  }
}

async function main() {
  console.log('🚀 Cloudinary 音频批量上传');
  console.log(`   Cloud Name: ${process.env.CLOUDINARY_CLOUD_NAME}`);
  console.log(`   音频目录: ${AUDIO_DIR}`);
  console.log(`   并发数: ${CONCURRENCY}\n`);

  // 构造上传列表
  const items = [];
  for (let i = 1; i <= TOTAL; i++) {
    const filename = `audio-${String(i).padStart(3, '0')}.mp3`;
    if (!fs.existsSync(path.join(AUDIO_DIR, filename))) {
      console.warn(`⚠️  文件不存在，跳过: ${filename}`);
      continue;
    }
    items.push({ filename, index: i });
  }

  console.log(`📁 待上传: ${items.length} 个文件\n`);

  const progress = loadProgress();
  const alreadyDone = Object.keys(progress).length;
  if (alreadyDone > 0) {
    console.log(`📌 发现已有进度: ${alreadyDone} 个文件已上传，将跳过\n`);
  }

  const results = await runBatch(items, progress, 0);

  const successes = results.filter(r => r.secure_url);
  const failures = results.filter(r => r.error);

  console.log('\n' + '='.repeat(60));
  console.log(`📊 上传统计:`);
  console.log(`   总计: ${items.length}`);
  console.log(`   成功: ${successes.length}`);
  console.log(`   失败: ${failures.length}`);
  console.log(`   已存在(跳过): ${alreadyDone}`);

  // 输出所有 URL
  const urlMap = {};
  for (const r of successes) {
    urlMap[r.public_id] = r.secure_url;
  }

  console.log('\n📋 所有上传 URL:');
  const sortedKeys = Object.keys(urlMap).sort();
  for (const k of sortedKeys) {
    console.log(`  ${k}: ${urlMap[k]}`);
  }

  if (failures.length > 0) {
    console.log('\n❌ 失败列表:');
    for (const f of failures) {
      console.log(`  ${f.filename}: ${f.error}`);
    }
  }

  // 尝试更新数据库
  const dbUpdated = await updateDatabase(urlMap);

  // 保存最终结果
  const finalResult = {
    uploaded_at: new Date().toISOString(),
    total_files: items.length,
    success_count: successes.length,
    failure_count: failures.length,
    db_records_updated: dbUpdated,
    urls: urlMap
  };

  const resultPath = path.join(AUDIO_DIR, 'upload-result.json');
  fs.writeFileSync(resultPath, JSON.stringify(finalResult, null, 2));
  console.log(`\n💾 结果已保存: ${resultPath}`);

  return finalResult;
}

main()
  .then(result => {
    console.log('\n✨ 完成!');
    process.exit(result.failure_count > 0 ? 1 : 0);
  })
  .catch(err => {
    console.error('\n💥 致命错误:', err);
    process.exit(1);
  });
