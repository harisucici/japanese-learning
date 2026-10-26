import type { CapacitorConfig } from '@capacitor/cli';

// URLs are selected by Android buildTypes, never by the last cap sync environment.
const config: CapacitorConfig = {
  appId: 'com.jaleaning.app',
  appName: '日语学习平台',
  webDir: 'dist',
};
export default config;
