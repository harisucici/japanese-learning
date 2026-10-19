/// 设计系统 - 主题配置
/// 
/// 整合所有设计令牌，构建 Flutter ThemeData
/// 支持浅色/深色/跟随系统三种模式
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 应用主题
/// 
/// 提供浅色和深色两套主题，统一所有视觉属性
/// 主色：#2563EB（深蓝），辅色：#10B981（绿）
class AppTheme {
  AppTheme._();

  // ============================================================
  // 浅色主题
  // ============================================================
  
  /// 浅色主题 - 默认使用
  static ThemeData get light {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.textOnPrimary,
      primaryContainer: AppColors.primary100,
      onPrimaryContainer: AppColors.primary900,
      secondary: AppColors.success,
      onSecondary: AppColors.textOnPrimary,
      secondaryContainer: AppColors.success100,
      onSecondaryContainer: AppColors.successDark,
      error: AppColors.error,
      onError: AppColors.textOnPrimary,
      errorContainer: AppColors.errorLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      
      // 基础颜色
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      cardColor: AppColors.surface,
      dialogBackgroundColor: AppColors.surface,
      dividerColor: AppColors.divider,
      
      // 字体配置
      fontFamily: AppTypography.fontFamily,
      textTheme: _buildLightTextTheme(),
      primaryTextTheme: _buildLightTextTheme(),
      
      //  AppBar
      appBarTheme: _buildLightAppBarTheme(colorScheme),
      
      // 卡片
      cardTheme: _buildLightCardTheme(colorScheme),
      
      // 按钮
      elevatedButtonTheme: _buildElevatedButtonTheme(colorScheme),
      filledButtonTheme: _buildFilledButtonTheme(colorScheme),
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
      
      // 页面过渡
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      
      //  splashFactory
      splashFactory: InkSparkle.splashFactory,
      
      // 视觉密度（VISUAL_DENSITY: 4 → 适中密度）
      visualDensity: VisualDensity.standard,
    );
  }

  // ============================================================
  // 深色主题
  // ============================================================
  
  /// 深色主题
  static ThemeData get dark {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.primary900,
      primaryContainer: AppColors.primary700,
      onPrimaryContainer: AppColors.primary100,
      secondary: AppColors.successLight,
      onSecondary: AppColors.successDark,
      secondaryContainer: AppColors.successDark,
      onSecondaryContainer: AppColors.success100,
      error: AppColors.errorLight,
      onError: AppColors.error,
      errorContainer: AppColors.error,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkSurfaceVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      
      // 基础颜色
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
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displayMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displayMedium,
        fontWeight: AppTypography.bold,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
        letterSpacing: AppTypography.letterSpacingTight,
      ),
      displaySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.displaySmall,
        fontWeight: AppTypography.bold,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightTight,
      ),
      headlineLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineLarge,
        fontWeight: AppTypography.semiBold,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineSmall,
        fontWeight: AppTypography.semiBold,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightNormal,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyLarge,
        fontWeight: AppTypography.regular,
        color: AppColors.textPrimary,
        height: AppTypography.lineHeightRelaxed,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.regular,
        color: AppColors.textSecondary,
        height: AppTypography.lineHeightNormal,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.regular,
        color: AppColors.textHint,
        height: AppTypography.lineHeightNormal,
      ),
      labelLarge: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodyMedium,
        fontWeight: AppTypography.medium,
        color: AppColors.textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.medium,
        color: AppColors.textSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.labelSmall,
        fontWeight: AppTypography.medium,
        color: AppColors.textHint,
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
  
  /// 浅色 AppBar 主题
  static AppBarTheme _buildLightAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: AppSpacing.lg,
      titleTextStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.textPrimary,
      ),
    );
  }

  /// 深色 AppBar 主题
  static AppBarTheme _buildDarkAppBarTheme(ColorScheme colorScheme) {
    return AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: AppColors.darkSurface,
      foregroundColor: AppColors.darkTextPrimary,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      titleSpacing: AppSpacing.lg,
      titleTextStyle: const TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: AppTypography.headlineMedium,
        fontWeight: AppTypography.semiBold,
        color: AppColors.darkTextPrimary,
      ),
    );
  }

  /// 浅色卡片主题
  static CardTheme _buildLightCardTheme(ColorScheme colorScheme) {
    return CardTheme(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: AppColors.border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.border, width: 1),
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

  /// 输入框主题 - 浅色
  static InputDecorationTheme _buildLightInputDecorationTheme(
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
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
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
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
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primary50,
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

  /// Chip 主题 - 浅色
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
        color: AppColors.textPrimary,
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
  
  /// 凸起按钮主题
  static ElevatedButtonThemeData _buildElevatedButtonTheme(
    ColorScheme colorScheme,
  ) {
    final isDark = colorScheme.brightness == Brightness.dark;
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
        foregroundColor: isDark ? AppColors.primary900 : AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
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

  /// 填充按钮主题
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
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
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

  /// 描边按钮主题
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

  /// 文字按钮主题
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
