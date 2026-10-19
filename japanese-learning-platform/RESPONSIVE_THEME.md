# 响应式主题系统文档

## 概述

日本語学習平台实现了基于屏幕宽度的响应式主题系统，自动在移动端和桌面端之间切换主题。

## 主题规则

| 屏幕宽度 | 布局类型 | 主题 | 背景色 | 文字色 |
|---------|---------|------|--------|--------|
| < 768px | Mobile | Dark Theme (深青色) | `#0D2B2A` | 白色 `#FFFFFF` |
| ≥ 768px | Desktop/Web | Light Theme (白色) | `#FFFFFF` | 深色 `#1A3C3B` |

## 技术实现

### 1. 响应式检测

在 `database_app.dart` 中使用 `LayoutBuilder` 检测视口宽度：

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final isMobile = constraints.maxWidth < 768;
    final themeData = isMobile ? AppTheme.dark : AppTheme.light;
    
    return MaterialApp.router(
      theme: themeData,
      darkTheme: AppTheme.dark,
      themeMode: isMobile ? ThemeMode.dark : ThemeMode.light,
      // ...
    );
  },
);
```

### 2. 主题配置

**Dark Theme (移动端)**
- 背景：深青色 `#0D2B2A`
- 表面：`#143D3B`
- 主色：`#268785` (深青色)
- 文字：白色 `#FFFFFF`
- 次要文字：`#B0BEC5`

**Light Theme (桌面端)**
- 背景：纯白 `#FFFFFF`
- 表面：纯白 `#FFFFFF`
- 主色：`#268785` (深青色)
- 文字：深色 `#1A3C3B`
- 次要文字：`#4A6564`
- 边框：`#B2DFDB`

### 3. 颜色定义

所有颜色在 `lib/core/theme/app_colors.dart` 中定义：

```dart
class AppColors {
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0D2B2A);
  static const Color darkSurface = Color(0xFF143D3B);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A3C3B);
  
  // Shared Colors (both themes)
  static const Color primary = Color(0xFF268785);
}
```

## 测试方法

### 浏览器测试

1. 启动 Flutter Web 应用：
```bash
flutter run -d chrome
```

2. 打开开发者工具 (F12)

3. 切换设备模式：
   - Mobile 模式：宽度 < 768px → 深青色深色主题
   - Desktop 模式：宽度 ≥ 768px → 白色浅色主题

### 响应式断点测试

```dart
// 在任意 Widget 中测试当前布局
LayoutBuilder(
  builder: (context, constraints) {
    print('当前宽度: ${constraints.maxWidth}');
    print('是否移动端: ${constraints.maxWidth < 768}');
    return YourWidget();
  },
);
```

## 设计原则

1. **无闪烁切换**：主题在 LayoutBuilder 中同步应用，避免主题切换时的视觉闪烁
2. **品牌一致性**：主色 `#268785` 在两个主题中保持一致
3. **可读性优先**：确保所有文字在对应背景上有足够的对比度
4. **Material Design 3**：遵循 MD3 规范，使用 `ColorScheme` 和 `ThemeData`

## 修改的文件

1. **lib/core/theme/app_colors.dart**
   - 更新 `lightBackground` 为纯白 `#FFFFFF`
   - 保持 dark theme 颜色不变

2. **lib/core/theme/app_theme.dart**
   - 更新 `AppTheme.light` 使用白色背景 + 深色文字
   - 更新 `lightSurface`、`lightBorder` 等颜色引用
   - 更新 `lightTextPrimary`、`lightTextSecondary` 等文字颜色
   - 更新 `lightNavigationBarTheme` 使用浅色背景

3. **lib/database_learning/database_app.dart**
   - 在 `build()` 方法中添加 `LayoutBuilder`
   - 根据 `constraints.maxWidth < 768` 动态选择主题
   - 设置 `themeMode` 为 `ThemeMode.dark` (移动端) 或 `ThemeMode.light` (桌面端)

## 注意事项

1. **Redux 主题状态**：当前实现绕过了 Redux 的 `themeMode` 状态，直接使用 LayoutBuilder 检测宽度。这是为了支持"响应式"而非"用户手动切换"。

2. **热重载**：修改主题颜色后，使用热重载 (Hot Reload) 即可看到效果，无需完全重启应用。

3. **自定义组件**：如果创建新的自定义组件，应使用 `Theme.of(context)` 获取颜色，而不是硬编码：

```dart
// ✅ 推荐
final theme = Theme.of(context);
Text(
  '标题',
  style: TextStyle(color: theme.colorScheme.onSurface),
);

// ❌ 避免
Text(
  '标题',
  style: TextStyle(color: Color(0xFF1A3C3B)), // 硬编码颜色
);
```

## 未来扩展

如需支持用户手动切换主题（而非响应式），可以：

1. 移除 LayoutBuilder 中的主题逻辑
2. 使用 Redux 的 `themeMode` 状态
3. 在设置页面添加主题切换按钮
4. 持久化用户选择到 SharedPreferences

当前实现优先满足"响应式"需求，如需"手动切换"可以后续迭代。
