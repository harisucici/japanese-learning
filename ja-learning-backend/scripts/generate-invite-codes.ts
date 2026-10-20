import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

function generateInviteCode(length: number = 8): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789' // 排除 0,1,I,L,O 避免混淆
  let code = ''
  for (let i = 0; i < length; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return code
}

async function main() {
  // 清空现有的邀请码
  await prisma.inviteCode.deleteMany()
  console.log('已清空现有邀请码')

  const codes = []
  const codeSet = new Set<string>()

  // 生成50个唯一的8位邀请码
  while (codes.length < 50) {
    const code = generateInviteCode(8)
    if (!codeSet.has(code)) {
      codeSet.add(code)
      codes.push(code)
    }
  }

  // 批量插入数据库
  await prisma.inviteCode.createMany({
    data: codes.map(code => ({ code, used: false }))
  })

  console.log('\n成功生成50个邀请码：')
  console.log('==================')
  codes.forEach((code, index) => {
    console.log(`${String(index + 1).padStart(2, '0')}. ${code}`)
  })
  console.log('\n邀请码已保存到数据库')
}

main()
  .catch(e => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })
