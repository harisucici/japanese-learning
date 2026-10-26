import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd())
  const proxyTarget = env.VITE_PROXY_TARGET || 'http://localhost:3000'

  return {
    plugins: [vue()],
    server: {
      host: true,
      port: 8080,
      strictPort: true,
      proxy: {
        '/api/core': {
          target: proxyTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api\/core/, '/api/v1'),
        },
        '/api/reading': {
          target: proxyTarget,
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api\/reading/, '/api/v1'),
        },
        '/study-assets': {
          target: proxyTarget,
          changeOrigin: true,
        },
        '/exam-assets': {
          target: proxyTarget,
          changeOrigin: true,
        },
      },
    },
  }
})
