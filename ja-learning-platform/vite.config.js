import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      '/api/core': { target: 'http://localhost:3002', changeOrigin: true, rewrite: path => path.replace(/^\/api\/core/, '/api/v1') },
      '/api/reading': { target: 'http://localhost:3003', changeOrigin: true, rewrite: path => path.replace(/^\/api\/reading/, '/api/v1') },
      '/study-assets': { target: 'http://localhost:3002', changeOrigin: true },
    },
  },
})
