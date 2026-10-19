#!/usr/bin/env node
/**
 * Cloudflare R2 音频上传脚本
 * 
 * 功能：
 * 1. 读取 data/audio/ 下的所有 MP3 文件
 * 2. 读取 data/audio/audio-manifest.json 获取音频元数据
 * 3. 上传到 R2 bucket (ja-learning-audio)
 * 4. 生成公开访问 URL
 * 5. 更新数据库 StudyMaterial 表的 audioUrl 字段
 * 
 * 使用方法：
 * 1. 复制 .env.example 为 .env 并填入 R2 凭证
 * 2. 运行：node scripts/upload-r2.js
 * 
 * 需要的环境变量：
 * - R2_ACCOUNT_ID: Cloudflare Account ID
 * - R2_BUCKET_NAME: R2 bucket 名称 (默认: ja-learning-audio)
 * - R2_ACCESS_KEY_ID: R2 API Access Key
 * - R2_SECRET_ACCESS_KEY: R2 API Secret Key
 * - R2_PUBLIC_URL: R2 公开访问端点
 * - DATABASE_URL: PostgreSQL 数据库连接
 */

require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const { S3Client, PutObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');

// 初始化 Prisma 客户端
const prisma = new PrismaClient();

// R2 配置
const R2_CONFIG = {
  accountId: process.env.R2_ACCOUNT_ID,
  bucketName: process.env.R2_BUCKET_NAME || 'ja-learning-audio',
  accessKeyId: process.env.R2_ACCESS_KEY_ID,
  secretAccessKey: process.env.R2_SECRET_ACCESS_KEY,
  publicUrl: process.env.R2_PUBLIC_URL,
};

// 验证必需的环境变量
function validateConfig() {
  const missing = [];
  if (!R2_CONFIG.accountId) missing.push('R2_ACCOUNT_ID');
  if (!R2_CONFIG.accessKeyId) missing.push('R2_ACCESS_KEY_ID');
  if (!R2_CONFIG.secretAccessKey) missing.push('R2_SECRET_ACCESS_KEY');
  if (!R2_CONFIG.publicUrl) missing.push('R2_PUBLIC_URL');
  if (!process.env.DATABASE_URL) missing.push('DATABASE_URL');

  if (missing.length > 0) {
    console.error('❌ 缺少必需的环境变量：');
    missing.forEach(v => console.error(`   - ${v}`));
    console.error('\n请复制 .env.example 为 .env 并填入凭证');
    process.exit(1);
  }
}

// 创建 S3 客户端（R2 兼容 S3 API）
function createS3Client() {
  return new S3Client({
    region: 'auto',
    endpoint: `https://${R2_CONFIG.accountId}.r2.cloudflarestorage.com`,
    credentials: {
      accessKeyId: R2_CONFIG.accessKeyId,
      secretAccessKey: R2_CONFIG.secretAccessKey,
    },
  });
}

// 上传单个文件到 R2
async function uploadToR2(s3Client, localPath, r2Key, contentType = 'audio/mpeg') {
  const fileBuffer = fs.readFileSync(localPath);
  
  const command = new PutObjectCommand({
    Bucket: R2_CONFIG.bucketName,
    Key: r2Key,
    Body: fileBuffer,
    ContentType: contentType,
    CacheControl: 'public, max-age=31536000, immutable',
  });

  await s3Client.send(command);
  
  // 生成公开访问 URL
  const publicUrl = `${R2_CONFIG.publicUrl}/${r2Key}`;
  return publicUrl;
}

// 检查文件是否已存在于 R2
async function checkIfExists(s3Client, r2Key) {
  try {
    await s3Client.send(new HeadObjectCommand({
      Bucket: R2_CONFIG.bucketName,
      Key: r2Key,
    }));
    return true;
  } catch (err) {
    if (err.name === 'NotFound' || err.$metadata?.httpStatusCode === 404) {
      return false;
    }
    throw err;
  }
}

// 读取音频目录下的所有 MP3 文件
function getAudioFiles(audioDir) {
  if (!fs.existsSync(audioDir)) {
    console.error(`❌ 音频目录不存在: ${audioDir}`);
    process.exit(1);
  }

  const files = fs.readdirSync(audioDir);
  const mp3Files = files.filter(f => f.toLowerCase().endsWith('.mp3'));
  
  return mp3Files.map(filename => ({
    filename,
    localPath: path.join(audioDir, filename),
  }));
}

// 读取音频清单文件
function readManifest(audioDir) {
  const manifestPath = path.join(audioDir, 'audio-manifest.json');
  
  if (!fs.existsSync(manifestPath)) {
    console.warn(`⚠️  未找到清单文件: ${manifestPath}`);
    console.warn('   将继续上传所有 MP3 文件，但无法更新数据库关联');
    return null;
  }

  try {
    const content = fs.readFileSync(manifestPath, 'utf-8');
    return JSON.parse(content);
  } catch (err) {
    console.error(`❌ 解析清单文件失败: ${err.message}`);
    process.exit(1);
  }
}

// 主上传流程
async function uploadAudio() {
  console.log('🚀 开始 R2 音频上传...\n');
  
  // 1. 验证配置
  validateConfig();
  console.log('✅ 配置验证通过');
  
  // 2. 创建 S3 客户端
  const s3Client = createS3Client();
  console.log(`📦 R2 Bucket: ${R2_CONFIG.bucketName}`);
  console.log(`🌐 公开访问: ${R2_CONFIG.publicUrl}\n`);
  
  // 3. 获取音频文件列表
  const audioDir = path.join(__dirname, '..', 'data', 'audio');
  const audioFiles = getAudioFiles(audioDir);
  
  if (audioFiles.length === 0) {
    console.log('⚠️  未找到 MP3 文件');
    return;
  }
  
  console.log(`📂 找到 ${audioFiles.length} 个 MP3 文件\n`);
  
  // 4. 读取清单
  const manifest = readManifest(audioDir);
  
  // 5. 上传文件
  const uploadResults = [];
  const dbUpdates = [];
  
  for (const { filename, localPath } of audioFiles) {
    const r2Key = `audio/${filename}`;
    
    // 检查是否已存在
    const exists = await checkIfExists(s3Client, r2Key);
    if (exists) {
      console.log(`⏭️  跳过已存在: ${filename}`);
      const publicUrl = `${R2_CONFIG.publicUrl}/${r2Key}`;
      uploadResults.push({ filename, publicUrl, status: 'skipped' });
      continue;
    }
    
    // 上传
    console.log(`⬆️  上传中: ${filename}`);
    try {
      const publicUrl = await uploadToR2(s3Client, localPath, r2Key);
      console.log(`   ✓ 成功: ${publicUrl}`);
      uploadResults.push({ filename, publicUrl, status: 'uploaded' });
    } catch (err) {
      console.error(`   ❌ 失败: ${err.message}`);
      uploadResults.push({ filename, error: err.message, status: 'failed' });
    }
  }
  
  console.log('\n📊 上传完成统计：');
  console.log(`   上传成功: ${uploadResults.filter(r => r.status === 'uploaded').length}`);
  console.log(`   已存在: ${uploadResults.filter(r => r.status === 'skipped').length}`);
  console.log(`   失败: ${uploadResults.filter(r => r.status === 'failed').length}`);
  
  // 6. 更新数据库（如果有清单）
  if (manifest) {
    console.log('\n🔄 更新数据库关联...');
    
    for (const result of uploadResults) {
      if (result.status === 'failed') continue;
      
      // 在清单中查找对应的 materialId
      const manifestEntry = manifest.find(m => m.filename === result.filename);
      if (!manifestEntry || !manifestEntry.materialId) {
        console.warn(`   ⚠️  未找到 ${result.filename} 的 materialId，跳过数据库更新`);
        continue;
      }
      
      try {
        // 更新 StudyMaterial 表
        await prisma.studyMaterial.update({
          where: { id: manifestEntry.materialId },
          data: { audioUrl: result.publicUrl },
        });
        
        console.log(`   ✓ 已更新 materialId: ${manifestEntry.materialId}`);
        dbUpdates.push({ materialId: manifestEntry.materialId, audioUrl: result.publicUrl });
      } catch (err) {
        console.error(`   ❌ 更新失败 (materialId: ${manifestEntry.materialId}): ${err.message}`);
        dbUpdates.push({ materialId: manifestEntry.materialId, error: err.message });
      }
    }
  }
  
  // 7. 生成上传报告
  const reportPath = path.join(__dirname, '..', 'data', 'audio', 'upload-report.json');
  const report = {
    timestamp: new Date().toISOString(),
    bucket: R2_CONFIG.bucketName,
    publicUrl: R2_CONFIG.publicUrl,
    totalFiles: audioFiles.length,
    uploaded: uploadResults.filter(r => r.status === 'uploaded').length,
    skipped: uploadResults.filter(r => r.status === 'skipped').length,
    failed: uploadResults.filter(r => r.status === 'failed').length,
    results: uploadResults,
    databaseUpdates: dbUpdates,
  };
  
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));
  console.log(`\n📝 上传报告已保存: ${reportPath}`);
  
  console.log('\n✅ 全部完成！');
}

// 运行主流程
uploadAudio()
  .catch(err => {
    console.error('\n❌ 上传过程中发生错误:', err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
