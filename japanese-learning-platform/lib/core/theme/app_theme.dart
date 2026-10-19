/// 设计系统 - 主题配置（Material Design 3 + 深青色配色）
///
/// 整合所有设计令牌，构建 Flutter ThemeData
/// Material Design 3 组件系统 + 深青色/蓝绿色视觉风格
/// - 深青色背景 #0D2B2A
/// - 主色：#268785（深青色）
/// - 强调色：亮青色、翠绿、金色（高饱和度）
/// - 文字：白色
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 应用主题
///
/// Material Design 3 组件 + 日式古典配色
/// 主色：#1A1A2E（深靛蓝），辅色：#C73E3E（朱红），点缀：#D4A574（金色）
class AppTheme {
  AppTheme._();

  // ============================================================
  // 浅色主题
  // ============================================================

  /// 浅色主题 - 日式古典（白色背景 + 深色文字）
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      // 主色 - 深靛蓝（墨色）
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primary50,
      onPrimaryContainer: AppColors.primary900,

      // 辅色 - 朱红（点缀）
      secondary: AppColors.secondary,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.secondary50,
      onSecondaryContainer: AppColors.secondaryDark,

      // 第三色 - 金色（高级感）
      tertiary: AppColors.gold,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.gold50,
      onTertiaryContainer: AppColors.goldDark,

      // 错误色 - 朱红
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.secondaryDark,

      // 表面 - 纯白（卡片）
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.lightTextSecondary,

      // 边框 - 和纸边缘
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // 基础颜色 - 白色背景
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightSurface,
      cardColor: AppColors.lightSurface,
      dialogBackgroundColor: AppColors.lightSurface,
      dividerColor: AppColors.divider,

      // 字体配置
      fontFamily: AppTypography.fontFamily,
      textTheme: _buildLightTextTheme(),
      primaryTextTheme: _buildLightTextTheme(),

      // AppBar
      appBarTheme: _buildLightAppBarTheme(colorScheme),

      // 卡片 - 日式扁平（elevation 0-2）
      cardTheme: _buildLightCardTheme(colorScheme),

      // 按钮
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      // NOTE: Flutter 3.27.4 does not ship FilledTonalButtonThemeData.
      // The tonal variant is created via FilledButton.tonal() and shares
      // the filledButtonTheme via the `tonal` constructor's defaults.
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),

      // 输入框
      inputDecorationTheme: _buildLightInputDecorationTheme(colorScheme),

      // 底部导航栏
      navigationBarTheme: _buildLightNavigationBarTheme(colorScheme),

      // 标签栏
      tabBarTheme: _buildLightTabBarTheme(colorScheme),

      // 分割线
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: _buildLightChipTheme(colorScheme),

      // Tooltip
      tooltipTheme: _buildLightTooltipTheme(),

      // 页面过渡 - Material 3 标准
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // splashFactory - Material 3 墨水效果
      splashFactory: InkSparkle.splashFactory,

      // 视觉密度（适中）
      visualDensity: VisualDensity.standard,

      // 阴影 - 暖色调
      shadowColor: const Color(0xFF2D2D3D),
    );
  }

  // ============================================================
  // 深色主题
  // ============================================================

  /// 深色主题 - 日式夜（深墨色背景 + 米色文字）
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      // 主色 - 靛蓝浅色（深色模式调亮）
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primary900,
      primaryContainer: AppColors.primary700,
      onPrimaryContainer: AppColors.primary50,

      // 辅色 - 朱红浅色
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.secondaryDark,
      secondaryContainer: AppColors.secondaryDark,
      onSecondaryContainer: AppColors.secondary50,

      // 第三色 - 金色
      tertiary: AppColors.goldLight,
      onTertiary: AppColors.goldDark,
      tertiaryContainer: AppColors.goldDark,
      onTertiaryContainer: AppColors.gold50,

      // 错误色
      error: AppColors.errorLight,
      onError: AppColors.error,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.errorLight,

      // 表面 - 深墨色
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,

      // 边框
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,

      // 基础颜色 - 深墨色背景
      scaffoldBackgroundColor: AppColors.darkBackground,
      canvasColor: AppColors.darkSurface,
      cardColor: AppColors.darkSurface,
      dialogBackgroundColor: AppColors.darkSurface,
      dividerColor: AppColors.darkBorder,

      // 字体配置
      fontFamily: AppTypography.fontFamily,
      textTheme: _buildDarkTextTheme(),
      primaryTextTheme: _buildDarkTextTheme(),

      // AppBar
      appBarTheme: _buildDarkAppBarTheme(colorScheme),

      // 卡片
      cardTheme: _buildDarkCardTheme(colorScheme),

      // 按钮
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
      // NOTE: Flutter 3.27.4 does not ship FilledTonalButtonThemeData.
      // The tonal variant is created via FilledButton.tonal() and shares
      // the filledButtonTheme via the `tonal` constructor's defaults.
      outlinedButtonTheme: _buildOutlinedButtonTheme(colorScheme),
      textButtonTheme: _buildTextButtonTheme(colorScheme),

      // 输入框
      inputDecorationTheme: _buildDarkInputDecorationTheme(colorScheme),

      // 底部导航栏
      navigationBarTheme: _buildDarkNavigationBarTheme(colorScheme),

      // 标签栏
      tabBarTheme: _buildDarkTabBarTheme(colorScheme),

      // 分割线
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 1,
        space: 1,
      ),

      // Chip
      chipTheme: _buildDarkChipTheme(colorScheme),

      // Tooltip
      tooltipTheme: _buildDarkTooltipTheme(),

      // 页面过渡
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      // 视觉密度
      visualDensity: VisualDensity.standard,
    );
  }

  // ============================================================
  // 文字主题构建器
  // ============================================================

  /// 浅色文字主题
  static TextTheme _buildLightTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayLarge,
        fontWeight: AppTypography.bold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayMedium,
        fontWeight: AppTypography.bold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displaySmall,
        fontWeight: AppTypography.bold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightTight,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineLarge,
        fontWeight: AppTypography.semiBold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSmall,
        fontWeight: AppTypography.semiBold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleLarge,
        fontWeight: AppTypography.semiBold,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleMedium,
        fontWeight: AppTypography.medium,
        color: AppColors.lightTextSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyLarge,
        fontWeight: AppTypography.regular,
        color: AppColors.lightTextPrimary,
        height: AppTypography.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.regular,
        color: AppColors.lightTextSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.regular,
        color: AppColors.lightTextHint,
        height: AppTypography.lineHeightNormal,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.medium,
        color: AppColors.lightTextPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.medium,
        color: AppColors.lightTextSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: AppTypography.medium,
        color: AppColors.lightTextHint,
      ),
    );
  }

  /// 深色文字主题
  static TextTheme _buildDarkTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayLarge,
        fontWeight: AppTypography.bold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayMedium,
        fontWeight: AppTypography.bold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displaySmall,
        fontWeight: AppTypography.bold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightTight,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineLarge,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSmall,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleLarge,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      titleMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.titleMedium,
        fontWeight: AppTypography.medium,
        color: AppColors.darkTextSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyLarge,
        fontWeight: AppTypography.regular,
        color: AppColors.darkTextPrimary,
        height: AppTypography.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.regular,
        color: AppColors.darkTextSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.regular,
        color: AppColors.darkTextHint,
        height: AppTypography.lineHeightNormal,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.medium,
        color: AppColors.darkTextPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.medium,
        color: AppColors.darkTextSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: AppTypography.medium,
        color: AppColors.darkTextHint,
      ),
    );
  }

  // ============================================================
  // 组件主题构建器
  // ============================================================

  /// 浅色 AppBar 主题 - 日式古典（白色背景 + 深色文字）
  static AppBarTheme _buildLightAppBarTheme(ColorScheme colorScheme) {
    return const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0, // 日式扁平
      backgroundColor: AppColors.lightSurface,
      foregroundColor: AppColors.lightTextPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: AppSpacing.lg,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.lightTextPrimary,
      ),
    );
  }

  /// 深色 AppBar 主题
  static AppBarTheme _buildDarkAppBarTheme(ColorScheme colorScheme) {
    return const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: AppSpacing.lg,
      titleTextStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
      ),
    );
  }

  /// 浅色卡片主题 - 日式扁平（elevation 0-2，暖色调边框）
  static CardTheme _buildLightCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 0, // 日式极简
      color: AppColors.lightSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: const Color(0xFF2D2D3D), // 暖色调阴影
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg), // 16px
        side: const BorderSide(color: AppColors.lightBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  /// 深色卡片主题
  static CardTheme _buildDarkCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 0,
      color: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.darkBorder,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
      margin: EdgeInsets.zero,
    );
  }

  /// 输入框主题 - 浅色（Material 3 Outlined）
  static InputDecorationTheme _buildLightInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      hintStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        color: AppColors.textHint,
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        color: AppColors.textSecondary,
      ),
    );
  }

  /// 输入框主题 - 深色
  static InputDecorationTheme _buildDarkInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
      ),
      hintStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        color: AppColors.darkTextHint,
      ),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        color: AppColors.darkTextSecondary,
      ),
    );
  }

  /// 底部导航栏主题 - 浅色
  static NavigationBarThemeData _buildLightNavigationBarTheme(
    ColorScheme colorScheme,
  ) {
    return NavigationBarThemeData(
      elevation: 0, // 日式扁平
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary50, // 靛蓝极淡
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.labelSmall,
            fontWeight: AppTypography.semiBold,
            color: AppColors.primary,
          );
        }
        return const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelSmall,
          fontWeight: AppTypography.medium,
          color: AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primary,
            size: 24,
          );
        }
        return const IconThemeData(
          color: AppColors.textSecondary,
          size: 24,
        );
      }),
    );
  }

  /// 底部导航栏主题 - 深色
  static NavigationBarThemeData _buildDarkNavigationBarTheme(
    ColorScheme colorScheme,
  ) {
    return NavigationBarThemeData(
      elevation: 0,
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary900,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: AppTypography.labelSmall,
            fontWeight: AppTypography.semiBold,
            color: AppColors.primaryLight,
          );
        }
        return const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.labelSmall,
          fontWeight: AppTypography.medium,
          color: AppColors.darkTextSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: AppColors.primaryLight,
            size: 24,
          );
        }
        return const IconThemeData(
          color: AppColors.darkTextSecondary,
          size: 24,
        );
      }),
    );
  }

  /// 标签栏主题 - 浅色
  static TabBarTheme _buildLightTabBarTheme(ColorScheme colorScheme) {
    return const TabBarTheme(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.semiBold,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.medium,
      ),
    );
  }

  /// 标签栏主题 - 深色
  static TabBarTheme _buildDarkTabBarTheme(ColorScheme colorScheme) {
    return const TabBarTheme(
      labelColor: AppColors.primaryLight,
      unselectedLabelColor: AppColors.darkTextSecondary,
      indicatorColor: AppColors.primaryLight,
      labelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.semiBold,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.medium,
      ),
    );
  }

  /// Chip 主题 - 浅色（日式标签）
  static ChipThemeData _buildLightChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary50,
      disabledColor: AppColors.surfaceVariant.withAlphaCompat(0.5),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.medium,
        color: AppColors.textPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  /// Chip 主题 - 深色
  static ChipThemeData _buildDarkChipTheme(ColorScheme colorScheme) {
    return ChipThemeData(
      backgroundColor: AppColors.darkSurfaceVariant,
      selectedColor: AppColors.primary900,
      disabledColor: AppColors.darkSurfaceVariant.withAlphaCompat(0.5),
      labelStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.medium,
        color: AppColors.darkTextPrimary,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
    );
  }

  /// 提示主题 - 浅色
  static TooltipThemeData _buildLightTooltipTheme() {
    return const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.primary, // 深靛蓝
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        color: AppColors.textOnPrimary,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }

  /// 提示主题 - 深色
  static TooltipThemeData _buildDarkTooltipTheme() {
    return const TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.darkTextPrimary,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.sm)),
      ),
      textStyle: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        color: AppColors.darkBackground,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
    );
  }

  // ============================================================
  // 按钮主题（亮暗共用）
  // ============================================================

  /// 凸起按钮主题 - Material 3 规范
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2, // Material 3 默认 elevation
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: isDark ? AppColors.primary900 : AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md), // 12px
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.bodyMedium,
          fontWeight: AppTypography.semiBold,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  /// 填充按钮主题 - Material 3 FilledButton
  static FilledButtonThemeData _buildFilledButtonTheme(
    ColorScheme colorScheme,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: isDark ? AppColors.primary900 : AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.bodyMedium,
          fontWeight: AppTypography.semiBold,
          letterSpacing: AppTypography.letterSpacingWide,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  /// NOTE: FilledTonalButtonThemeData is not available in Flutter 3.27.4.
  /// For a tonal variant, call sites should use FilledButton.tonal(...) which
  /// uses its own built-in defaults. Keeping the style values documented
  /// here for reference (primary50 / primary on light, primary700 / primary50 on dark).

  /// 描边按钮主题 - Material 3 OutlinedButton
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(
    ColorScheme colorScheme,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        side: BorderSide(
          color: isDark ? AppColors.primaryLight : AppColors.primary,
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.bodyMedium,
          fontWeight: AppTypography.semiBold,
        ),
        minimumSize: const Size(0, 48),
      ),
    );
  }

  /// 文字按钮主题 - Material 3 TextButton
  static TextButtonThemeData _buildTextButtonTheme(ColorScheme colorScheme) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        elevation: 0,
        foregroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.bodyMedium,
          fontWeight: AppTypography.semiBold,
        ),
      ),
    );
  }
}
