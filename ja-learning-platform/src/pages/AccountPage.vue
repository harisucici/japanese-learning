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
    <!-- 骨架屏 -->
    <div v-if="auth.loading" class="mob-acct-skeleton" aria-hidden="true">
      <div class="mob-acct-sk-intro">
        <div class="skeleton mob-acct-sk-avatar"></div>
        <div class="mob-acct-sk-text">
          <div class="skeleton mob-acct-sk-name"></div>
          <div class="skeleton mob-acct-sk-handle"></div>
        </div>
      </div>
      <div class="mob-acct-sk-summary">
        <div v-for="n in 3" :key="n" class="mob-acct-sk-cell">
          <div class="skeleton mob-acct-sk-cell-label"></div>
          <div class="skeleton mob-acct-sk-cell-value"></div>
        </div>
      </div>
      <div class="mob-acct-sk-card">
        <div class="skeleton mob-acct-sk-heading"></div>
        <div class="skeleton mob-acct-sk-input"></div>
        <div class="skeleton mob-acct-skinput"></div>
        <div class="skeleton mob-acct-sk-btn"></div>
      </div>
    </div>
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
/* ===== Design tokens ===== */
.account-page {
  --accent: #355247;
  --bg: #f5f2e9;
  --surface: #fffdf8;
  --border: #e2ded3;
  --border-soft: #cac9bd;
  --text: #27302b;
  --text-secondary: #67746a;
  --label: #4c6154;
  --spring: cubic-bezier(0.34, 1.56, 0.64, 1);
}

.account-page {
  padding-bottom: 90px;
  color: var(--text);
}

/* ===== Eyebrow + Page Heading (inherits content-page) ===== */
.account-intro {
  display: flex;
  align-items: center;
  gap: 24px;
  margin: 36px 0;
}
.account-intro h2,
.account-auth h2 {
  font: clamp(28px, 3vw, 42px) / 1.4 'Zen Kaku Gothic New', sans-serif;
  margin: 6px 0;
  color: var(--text);
}
.account-intro p:last-child,
.account-card > p {
  color: var(--text-secondary);
  font-size: 15px;
  line-height: 1.8;
}

/* ===== User monogram ===== */
.account-monogram {
  width: 82px;
  height: 82px;
  display: grid;
  place-items: center;
  border-radius: 50%;
  background: var(--accent);
  color: var(--bg);
  font: 600 32px/1 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0;
}

/* ===== Summary grid ===== */
.account-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  margin: 30px 0 42px;
  overflow: hidden;
}
.account-summary > div {
  padding: 22px 28px;
  border-right: 1px solid var(--border);
}
.account-summary > div:last-child { border-right: 0; }
.account-summary small {
  display: block;
  color: var(--text-secondary);
  font-size: 12px;
  margin-bottom: 9px;
  letter-spacing: 0.05em;
}
.account-summary strong {
  font: 600 22px/1.2 'Zen Kaku Gothic New', sans-serif;
  color: var(--accent);
}
.account-summary a {
  font-size: 14px;
  color: var(--accent);
  border-bottom: 1px solid var(--accent);
  text-decoration: none;
  transition: opacity 0.3s var(--spring);
}
.account-summary a:hover { opacity: 0.7; }

/* ===== Two-column cards ===== */
.account-columns {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 22px;
}

/* ===== Card ===== */
.account-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  padding: clamp(25px, 4vw, 42px);
  transition: box-shadow 0.3s var(--spring);
}
.account-card:hover {
  box-shadow: 0 8px 24px -12px rgba(53, 82, 71, 0.12);
}
.account-card h3 {
  font: 600 22px/1.3 'Zen Kaku Gothic New', sans-serif;
  margin: 12px 0;
  color: var(--text);
}

/* ===== Forms ===== */
.account-card form {
  display: grid;
  gap: 18px;
  margin-top: 26px;
}
.account-card label {
  display: block;
  color: var(--label);
  font-size: 12px;
  letter-spacing: 0.04em;
  font-weight: 500;
}
.account-card input,
.account-card select {
  display: block;
  width: 100%;
  margin-top: 8px;
  height: 48px;
  border: 1px solid var(--border-soft);
  border-radius: 8px;
  background: var(--surface);
  color: var(--text);
  padding: 0 14px;
  font: 16px/1.4 'Zen Kaku Gothic New', sans-serif;
  transition: border-color 0.3s var(--spring),
              box-shadow 0.3s var(--spring),
              transform 0.2s var(--spring);
}
.account-card select {
  appearance: none;
  -webkit-appearance: none;
  background-image: url("data:image/svg+xml;charset=UTF-8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath fill='%2367746a' d='M6 8L0 0h12z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 14px center;
  padding-right: 38px;
}
.account-card input:focus,
.account-card select:focus {
  outline: 2px solid #789887;
  outline-offset: 2px;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px rgba(53, 82, 71, 0.1);
}
.account-card input:active,
.account-card select:active {
  transform: scale(0.995);
}
.account-card small {
  color: var(--text-secondary);
  font-size: 12px;
  line-height: 1.6;
}

/* ===== Two-field row ===== */
.account-fields {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 15px;
}

/* ===== Buttons (override global) ===== */
.account-card .primary-action,
.account-card .secondary-action,
.account-auth .primary-action,
.account-logout {
  justify-self: start;
  height: 48px;
  padding: 0 24px;
  border-radius: 8px;
  font: 500 13px/1 'Noto Sans JP', 'Geist', system-ui, sans-serif;
  letter-spacing: 0.08em;
  transition: transform 0.3s var(--spring),
              background 0.3s var(--spring),
              color 0.3s var(--spring),
              border-color 0.3s var(--spring),
              box-shadow 0.3s var(--spring);
}
.account-card .primary-action,
.account-auth .primary-action {
  background: var(--accent);
  color: #fff;
  border-color: var(--accent);
}
.account-card .secondary-action {
  background: transparent;
  color: var(--accent);
  border: 1px solid var(--accent);
}
.account-card .primary-action:active,
.account-card .secondary-action:active,
.account-logout:active {
  transform: scale(0.97);
}
.account-card .primary-action:hover,
.account-auth .primary-action:hover {
  box-shadow: 0 6px 18px -6px rgba(53, 82, 71, 0.4);
}

/* ===== Auth card ===== */
.account-auth {
  width: min(560px, 100%);
  margin: 35px auto;
}

/* ===== Tabs ===== */
.account-tabs {
  display: flex;
  border-bottom: 1px solid var(--border);
  margin-top: 28px;
}
.account-tabs button {
  flex: 1;
  min-height: 48px;
  border: 0;
  background: transparent;
  padding: 13px 26px;
  color: var(--text-secondary);
  font: 500 14px/1 'Zen Kaku Gothic New', sans-serif;
  letter-spacing: 0.04em;
  cursor: pointer;
  border-bottom: 3px solid transparent;
  margin-bottom: -1px;
  transition: color 0.3s var(--spring),
              border-color 0.3s var(--spring),
              transform 0.2s var(--spring);
}
.account-tabs button[aria-selected="true"] {
  color: var(--accent);
  border-bottom-color: var(--accent);
  font-weight: 600;
}
.account-tabs button:active {
  transform: scale(0.97);
}

/* ===== Messages ===== */
.account-message {
  padding: 14px 18px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  color: var(--accent);
  margin: 22px 0;
  border-radius: 8px;
  font-size: 14px;
  line-height: 1.6;
}
.account-message.error {
  background: #fef2f2;
  border-color: #fecaca;
  color: #c44536;
}

/* ===== Text buttons / logout ===== */
.account-text-button,
.account-logout {
  border: 0;
  background: transparent;
  color: var(--accent);
  border-bottom: 1px solid var(--accent);
  padding: 5px 0;
  cursor: pointer;
  font-size: 12px;
  letter-spacing: 0.04em;
  margin-top: 23px;
  align-self: start;
  transition: opacity 0.3s var(--spring), transform 0.2s var(--spring);
}
.account-logout {
  margin-top: 38px;
  font-size: 13px;
  padding: 8px 0;
}
.account-text-button:hover,
.account-logout:hover {
  opacity: 0.7;
}
.account-text-button:active,
.account-logout:active {
  transform: scale(0.97);
}

/* ===== Register hint ===== */
.register-hint {
  margin: 18px 0 0;
  padding: 14px 18px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 14px;
  color: var(--text);
}
.register-link {
  color: var(--accent);
  font-weight: 600;
  background: none;
  border: none;
  cursor: pointer;
  padding: 4px 0;
  font-size: inherit;
  border-bottom: 1px solid var(--accent);
  transition: opacity 0.3s var(--spring);
}
.register-link:hover { opacity: 0.7; }

/* ===== Secondary action link (admin) ===== */
.account-page .secondary-action[href] {
  display: inline-flex;
  align-items: center;
  height: 48px;
  padding: 0 24px;
  margin: 8px 0 0;
  border-radius: 8px;
}

/* ===== Responsive: tablet and below (≤ 768px) ===== */
@media (max-width: 768px) {
  .account-columns {
    grid-template-columns: 1fr;
  }
  .account-summary {
    grid-template-columns: 1fr;
  }
  .account-summary > div {
    border-right: 0;
    border-bottom: 1px solid var(--border);
  }
  .account-summary > div:last-child {
    border-bottom: 0;
  }
  .account-intro {
    align-items: flex-start;
  }
  .account-monogram {
    width: 62px;
    height: 62px;
    font-size: 24px;
    flex: none;
  }
}

/* ===== Mobile touch-friendly overrides (≤ 640px) ===== */
@media (max-width: 640px) {
  .account-page {
    padding: 0 16px 60px;
    width: 100%;
  }

  /* Auth card: full width on mobile */
  .account-auth {
    width: 100%;
    padding: 24px 20px;
    margin: 24px auto;
  }

  /* Buttons: full width for easier tapping */
  .account-card .primary-action,
  .account-card .secondary-action,
  .account-auth .primary-action,
  .account-logout {
    width: 100%;
    justify-self: stretch;
  }

  /* Logged-in summary: bigger tap targets */
  .account-summary > div {
    padding: 18px 16px;
    min-height: 56px;
  }

  /* Text links need ≥ 44px tap area */
  .account-text-button {
    min-height: 44px;
    padding: 10px 0;
    font-size: 14px;
  }

  .register-hint {
    flex-direction: column;
    align-items: flex-start;
    padding: 14px 16px;
  }
  .register-link {
    padding: 8px 0;
    font-size: 14px;
  }
}

/* ===== Very small screens (≤ 380px) ===== */
@media (max-width: 380px) {
  .account-page {
    padding: 0 12px 60px;
  }
  .account-card {
    padding: 20px 16px;
  }
  .account-auth {
    padding: 20px 16px;
  }
}

/* ===== 骨架屏（移动端账户页） ===== */
.mob-acct-skeleton {
  padding: 20px 16px;
  display: flex;
  flex-direction: column;
  gap: 20px;
}
.mob-acct-sk-intro {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 0;
}
.mob-acct-sk-avatar {
  width: 64px;
  height: 64px;
  border-radius: 50%;
  flex: none;
}
.mob-acct-sk-text {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.mob-acct-sk-name {
  width: 60%;
  height: 18px;
  border-radius: 4px;
}
.mob-acct-sk-handle {
  width: 40%;
  height: 14px;
  border-radius: 3px;
}
.mob-acct-sk-summary {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  padding: 16px;
  background: var(--theme-surface-alt, #f5f2e9);
  border-radius: 12px;
}
.mob-acct-sk-cell {
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.mob-acct-sk-cell-label {
  width: 80%;
  height: 12px;
  border-radius: 3px;
}
.mob-acct-sk-cell-value {
  width: 50%;
  height: 16px;
  border-radius: 4px;
}
.mob-acct-sk-card {
  padding: 20px;
  background: var(--theme-surface, #fffdf8);
  border: 1px solid var(--theme-border-soft, #e2ded3);
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.mob-acct-sk-heading {
  width: 50%;
  height: 18px;
  border-radius: 4px;
}
.mob-acct-sk-input {
  width: 100%;
  height: 44px;
  border-radius: 8px;
}
.mob-acct-skinput {
  width: 100%;
  height: 44px;
  border-radius: 8px;
}
.mob-acct-sk-btn {
  width: 120px;
  height: 44px;
  border-radius: 8px;
  margin-top: 4px;
}
</style>
