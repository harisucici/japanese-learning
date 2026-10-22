<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter, RouterLink } from 'vue-router'
import { useAuthStore } from '../store'

const auth = useAuthStore()
const route = useRoute()
const router = useRouter()
const mode = ref(route.path === '/reset-password' ? 'reset' : 'login')
const busy = ref(false)
const error = ref('')
const notice = ref('')
const showRegisterHint = ref(false)
const account = reactive({ identifier: '', username: '', email: '', password: '', nickname: '', inviteCode: '', currentLevel: 'n5', targetLevel: 'n5' })
const profile = reactive({ nickname: '', currentLevel: 'n5', targetLevel: 'n5' })
const password = reactive({ oldPassword: '', newPassword: '' })
const levels = ['n5', 'n4', 'n3', 'n2', 'n1']
const isReset = computed(() => mode.value === 'reset')

function syncProfile() {
  if (!auth.user) return
  profile.nickname = auth.user.nickname || ''
  profile.currentLevel = auth.user.currentLevel || 'n5'
  profile.targetLevel = auth.user.targetLevel || 'n5'
}
onMounted(async () => {
  await auth.check()
  syncProfile()
  if (!auth.user) {
    showRegisterHint.value = true
  }
})
watch(() => auth.user, syncProfile)
watch(() => route.path, path => { mode.value = path === '/reset-password' ? 'reset' : 'login' })

async function perform(action, success) {
  busy.value = true
  error.value = ''
  notice.value = ''
  try { await action(); notice.value = success || '' }
  catch (e) {
    const msg = e.message || '请求失败，请重试'
    if (msg.includes('不存在') || msg.includes('无效') || msg.includes('Invalid credentials') || msg.includes('账户不存在') || msg.includes('not found')) {
      error.value = msg
      showRegisterHint.value = true
    } else {
      error.value = msg
      showRegisterHint.value = false
    }
  }
  finally { busy.value = false }
}

function submitAccount() {
  if (mode.value === 'register') {
    return perform(async () => {
      await auth.register({
        username: account.username,
        password: account.password,
        inviteCode: account.inviteCode,
        currentLevel: account.currentLevel,
        targetLevel: account.targetLevel,
        ...(account.nickname ? { nickname: account.nickname } : {}),
        ...(account.email ? { email: account.email } : {})
      })
      syncProfile()
    }, '账户已创建，学习进度将保存在你的账户中。')
  }
  return perform(async () => { await auth.login({ identifier: account.identifier, password: account.password }); syncProfile() }, '欢迎回来。')
}

function submitProfile() {
  return perform(() => auth.saveProfile({ ...profile }), '个人资料已保存。')
}

function submitPassword() {
  return perform(async () => {
    await auth.request('change-password', { ...password })
    password.oldPassword = ''
    password.newPassword = ''
  }, '密码已更新。')
}

function requestReset() {
  return perform(() => auth.request('forgot-password', { email: account.email }), '如果该邮箱已注册，重置说明会发送到邮箱。')
}

function resetPassword() {
  if (!account.password || account.password.length < 8) {
    error.value = '密码不能为空且长度至少为8位'
    showRegisterHint.value = false
    return Promise.resolve()
  }
  return perform(async () => {
    await auth.request('reset-password', { token: String(route.query.token || ''), password: account.password })
    account.password = ''
    mode.value = 'login'
    await router.replace('/account')
  }, '密码已重置，请登录。')
}

function signOut() {
  return perform(async () => { await auth.logout(); mode.value = 'login' }, '已退出账户。')
}

function goToRegister() {
  mode.value = 'register'
  showRegisterHint.value = false
  error.value = ''
  notice.value = ''
}
</script>

<template>
  <div class="account-page content-page">
    <div class="section-top"><p class="eyebrow">YOUR OWN JOURNEY</p><span>账户与学习进度</span></div>
    <div v-if="auth.loading" class="state-box">正在读取账户信息…</div>
    <template v-else>
      <div v-if="error" class="account-message error" role="alert">{{ error }}</div>
      <div v-if="notice" class="account-message" role="status">{{ notice }}</div>

      <template v-if="auth.user">
        <div class="account-intro"><div class="account-monogram">{{ auth.user.nickname?.slice(0, 1) || '学' }}</div><div><p class="eyebrow">LEARNER PROFILE</p><h2>{{ auth.user.nickname }}</h2><p>{{ auth.user.username ? `@${auth.user.username}` : auth.user.email }}</p></div></div>
        <div class="account-summary"><div><small>当前等级</small><strong>{{ auth.user.currentLevel?.toUpperCase() }}</strong></div><div><small>目标等级</small><strong>{{ auth.user.targetLevel?.toUpperCase() }}</strong></div><div><small>我的学习</small><RouterLink to="/history">查看记录 ↗</RouterLink></div></div>
        <RouterLink v-if="auth.user.role==='admin'" class="secondary-action" to="/admin">打开题库管理 ↗</RouterLink>
        <div class="account-columns">
          <section class="account-card"><p class="eyebrow">01 / PROFILE</p><h3>个人资料</h3><p>设置你的称呼和学习目标。</p><form @submit.prevent="submitProfile"><label>昵称<input v-model.trim="profile.nickname" required maxlength="50" autocomplete="nickname"></label><div class="account-fields"><label>当前等级<select v-model="profile.currentLevel"><option v-for="level in levels" :key="level" :value="level">{{ level.toUpperCase() }}</option></select></label><label>目标等级<select v-model="profile.targetLevel"><option v-for="level in levels" :key="level" :value="level">{{ level.toUpperCase() }}</option></select></label></div><button class="primary-action" :disabled="busy">保存资料</button></form></section>
          <section class="account-card"><p class="eyebrow">02 / SECURITY</p><h3>账户安全</h3><p>修改密码后，请使用新密码登录其他设备。</p><form @submit.prevent="submitPassword"><label>当前密码<input v-model="password.oldPassword" type="password" required autocomplete="current-password"></label><label>新密码<input v-model="password.newPassword" type="password" required minlength="8" autocomplete="new-password" aria-describedby="password-hint"></label><small id="password-hint">至少 8 位。</small><button class="secondary-action" :disabled="busy">修改密码</button></form></section>
        </div>
        <button class="account-logout" :disabled="busy" @click="signOut">退出登录 ↗</button>
      </template>

      <section v-else class="account-card account-auth"><p class="eyebrow">A PLACE TO CONTINUE</p><h2>{{ mode === 'register' ? '开始属于你的学习旅程' : mode === 'forgot' ? '找回密码' : isReset ? '设置新密码' : '欢迎回来' }}</h2><p>登录后，成绩、错题和学习目标会关联到你的账户。</p>
        <div v-if="mode === 'login' || mode === 'register'" class="account-tabs" role="tablist"><button type="button" :aria-selected="mode === 'login'" @click="mode = 'login'; error = ''; notice = ''">登录</button><button type="button" :aria-selected="mode === 'register'" @click="mode = 'register'; error = ''; notice = ''">注册</button></div>
        <form v-if="mode === 'login' || mode === 'register'" @submit.prevent="submitAccount"><label v-if="mode==='login'">账户名或邮箱<input v-model.trim="account.identifier" required autocomplete="username"></label><template v-else><label>账户名<input v-model.trim="account.username" required minlength="3" maxlength="32" autocomplete="username"></label><label>昵称（可选）<input v-model.trim="account.nickname" maxlength="50" autocomplete="nickname"></label><label>邮箱（可选，用于找回密码）<input v-model.trim="account.email" type="email" autocomplete="email"></label><label>邀请码<input v-model.trim="account.inviteCode" required maxlength="8" pattern="[A-Z0-9]{8}" placeholder="8位大写字母或数字" autocomplete="off"></label></template><label>密码<input v-model="account.password" type="password" required :minlength="mode === 'register' ? 8 : 1" :autocomplete="mode === 'register' ? 'new-password' : 'current-password'"></label><template v-if="mode === 'register'"><small>密码至少 8 位。未绑定邮箱时无法通过邮件找回密码。</small><div class="account-fields"><label>当前等级<select v-model="account.currentLevel"><option v-for="level in levels" :key="level" :value="level">{{ level.toUpperCase() }}</option></select></label><label>目标等级<select v-model="account.targetLevel"><option v-for="level in levels" :key="level" :value="level">{{ level.toUpperCase() }}</option></select></label></div></template><button class="primary-action" :disabled="busy">{{ busy ? '请稍候…' : mode === 'register' ? '创建账户' : '登录账户' }}</button></form>
        <form v-else-if="mode === 'forgot'" @submit.prevent="requestReset"><label>注册邮箱<input v-model.trim="account.email" type="email" required autocomplete="email"></label><button class="primary-action" :disabled="busy">发送重置说明</button></form>
        <form v-else @submit.prevent="resetPassword"><div v-if="!route.query.token" class="account-message error">重置链接缺少令牌，请重新申请。</div><label>新密码<input v-model="account.password" type="password" required minlength="8" autocomplete="new-password"></label><small>至少 8 位。</small><button class="primary-action" :disabled="busy || !route.query.token">保存新密码</button></form>
        <button v-if="mode === 'login'" class="account-text-button" @click="mode = 'forgot'; error = ''; notice = ''">忘记密码？</button><button v-else-if="mode === 'forgot' || isReset" class="account-text-button" @click="mode = 'login'; error = ''; notice = ''">返回登录</button>
        <div v-if="showRegisterHint && mode === 'login'" class="register-hint">
          <span>还没有账户？</span>
          <button type="button" class="register-link" @click="goToRegister">
            立即注册 →
          </button>
        </div>
      </section>
    </template>
  </div>
</template>

<style scoped>
.account-page{padding-bottom:90px}.account-intro{display:flex;align-items:center;gap:24px;margin:36px 0}.account-intro h2,.account-auth h2{font:clamp(28px,3vw,42px)/1.4 'Zen Kaku Gothic New',sans-serif;margin:6px 0}.account-intro p:last-child,.account-card>p{color:#67746a;font-size:13px;line-height:1.8}.account-monogram{width:82px;height:82px;display:grid;place-items:center;border-radius:50%;background:#355247;color:#f5f2e9;font-size:32px}.account-summary{display:grid;grid-template-columns:repeat(3,1fr);background:#eae9dc;margin:30px 0 42px}.account-summary>div{padding:22px 28px;border-right:1px solid #d5d1c3}.account-summary small{display:block;color:#69776e;font-size:11px;margin-bottom:9px}.account-summary strong{font-size:22px;color:#355247}.account-summary a{font-size:14px;border-bottom:1px solid #355247}.account-columns{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}.account-card{background:#fffdf8;border:1px solid #e2ded3;padding:clamp(25px,4vw,42px)}.account-card h3{font:25px 'Zen Kaku Gothic New',sans-serif;margin:12px 0}.account-card form{display:grid;gap:18px;margin-top:26px}.account-card label{display:block;color:#4c6154;font-size:12px}.account-card input,.account-card select{display:block;width:100%;margin-top:8px;border:1px solid #cac9bd;background:#fffdf8;color:#27302b;padding:13px 14px;font:15px 'Zen Kaku Gothic New',sans-serif}.account-card input:focus,.account-card select:focus{outline:2px solid #789887;outline-offset:2px}.account-card small{color:#788279;font-size:11px}.account-fields{display:grid;grid-template-columns:repeat(2,1fr);gap:15px}.account-card .primary-action,.account-card .secondary-action{justify-self:start}.account-auth{width:min(560px,100%);margin:35px auto}.account-tabs{display:flex;border-bottom:1px solid #d8d5c9;margin-top:28px}.account-tabs button{border:0;background:transparent;padding:13px 26px;color:#67746a;cursor:pointer}.account-tabs button[aria-selected=true]{color:#355247;border-bottom:2px solid #355247}.account-message{padding:14px 18px;background:#e5eee5;color:#355247;margin:22px 0}.account-message.error{background:#f9eae5;color:#984d45}.account-text-button,.account-logout{border:0;background:transparent;color:#355247;border-bottom:1px solid #355247;padding:5px 0;cursor:pointer;font-size:12px;margin-top:23px}.account-logout{margin-top:38px}.register-hint{margin:18px 0 0;padding:12px 16px;background:rgba(37,99,235,0.08);border:1px solid rgba(37,99,235,0.2);border-radius:8px;display:flex;align-items:center;justify-content:space-between;gap:12px;font-size:13px;color:#1e40af}.register-link{color:#2563EB;font-weight:500;background:none;border:none;cursor:pointer;padding:0;font-size:inherit}.register-link:hover{text-decoration:underline}@media(max-width:700px){.account-columns,.account-summary{grid-template-columns:1fr}.account-summary>div{border-right:0;border-bottom:1px solid #d5d1c3}.account-intro{align-items:flex-start}.account-monogram{width:62px;height:62px;flex:none}}
</style>
