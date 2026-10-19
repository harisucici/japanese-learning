/// 应用常量配置
/// 
/// 集中管理应用级别的全局常量
library;

/// 应用常量
class AppConstants {
  AppConstants._();

  // ============================================================
  // 应用信息
  // ============================================================
  
  /// 应用名称
  static const String appName = '日本語学習';
  
  /// 应用描述
  static const String appDescription = '日语 N5-N1 刷题与深度解析平台';
  
  /// 应用版本号
  static const String appVersion = '1.0.0';

  // ============================================================
  // JLPT 等级
  // ============================================================
  
  /// JLPT 等级列表
  static const List<String> jlptLevels = ['N5', 'N4', 'N3', 'N2', 'N1'];
  
  /// 默认 JLPT 等级
  static const String defaultJlptLevel = 'N5';

  // ============================================================
  // 本地化
  // ============================================================
  
  /// 默认语言
  static const String defaultLocale = 'zh';
  
  /// 支持的语言列表
  static const List<String> supportedLocales = ['zh', 'ja', 'en'];

  // ============================================================
  // 本地存储键
  // ============================================================
  
  /// 主题模式存储键
  static const String keyThemeMode = 'theme_mode';
  
  /// 用户偏好设置键
  static const String keyUserPreferences = 'user_preferences';
  
  /// 每日目标键
  static const String keyDailyGoal = 'daily_goal';

  // ============================================================
  // 数值限制
  // ============================================================
  
  /// 每日默认学习目标（题目数）
  static const int defaultDailyGoal = 20;
  
  /// 最大每日学习目标
  static const int maxDailyGoal = 200;
  
  /// 练习页面每页题目数
  static const int questionsPerPage = 10;
  
  /// 复习间隔天数（基于艾宾浩斯曲线）
  static const List<int> reviewIntervals = [1, 2, 4, 7, 15, 30];
}
