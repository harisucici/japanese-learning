import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.jaleaning.app',
  appName: '日语学习平台',
  webDir: 'dist',
  server: {
    url: 'http://192.168.0.14:5173',
    cleartext: true
  }
};

export default config;
