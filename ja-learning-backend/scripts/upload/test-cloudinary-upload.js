#!/usr/bin/env node
/**
 * Cloudinary 音频上传测试脚本
 * 先测试 1-2 个文件确认能成功
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

async function testUpload() {
  const audioDir = path.join(__dirname, '..', 'data', 'audio');
  const testFiles = ['audio-001.mp3', 'audio-002.mp3'];
  
  console.log('🧪 开始测试上传...\n');
  console.log(`Cloud Name: ${process.env.CLOUDINARY_CLOUD_NAME}`);
  console.log(`API Key: ${process.env.CLOUDINARY_API_KEY}\n`);
  
  const results = [];
  
  for (const filename of testFiles) {
    const filePath = path.join(audioDir, filename);
    
    if (!fs.existsSync(filePath)) {
      console.log(`❌ 文件不存在: ${filename}`);
      continue;
    }
    
    console.log(`📤 正在上传: ${filename}`);
    
    try {
      const result = await cloudinary.uploader.upload(filePath, {
        resource_type: 'video', // 音频文件使用 video 资源类型
        folder: 'ja-learning/audio',
        public_id: filename.replace('.mp3', ''),
        format: 'mp3'
      });
      
      console.log(`✅ 上传成功!`);
      console.log(`   URL: ${result.secure_url}`);
      console.log(`   Public ID: ${result.public_id}\n`);
      
      results.push({
        filename,
        url: result.secure_url,
        publicId: result.public_id
      });
    } catch (error) {
      console.error(`❌ 上传失败: ${error.message}\n`);
    }
  }
  
  console.log('\n📊 测试结果:');
  console.log(`成功: ${results.length}/${testFiles.length}`);
  console.log('\n上传的 URL:');
  results.forEach(r => console.log(`  ${r.filename}: ${r.url}`));
  
  return results;
}

testUpload()
  .then(results => {
    if (results.length === testFiles.length) {
      console.log('\n✨ 测试通过！可以运行完整上传脚本');
    }
    process.exit(0);
  })
  .catch(err => {
    console.error('\n💥 测试失败:', err);
    process.exit(1);
  });
