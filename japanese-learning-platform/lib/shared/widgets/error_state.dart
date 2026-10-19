/// 错误状态组件
/// 
/// 在请求失败或异常时显示错误提示
/// 提供重试功能
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
/// 错误状态组件
/// 
/// 使用规范：
/// - 用于网络错误、数据加载失败等场景
/// - 清晰展示错误信息
/// - 提供"重试"按钮恢复操作
class ErrorState extends StatelessWidget {
  /// 错误信息
  final String message;
  
  /// 重试回调
  final VoidCallback? onRetry;
  
  /// 是否显示重试按钮（默认 true）
  final bool showRetryButton;
  
  /// 图标（默认 Icons.error_outline）
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.showRetryButton = true,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 错误图标
            Icon(
              icon,
              size: 64,
              color: colorScheme.error,
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // 错误信息
            Text(
              message,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 重试按钮
            if (showRetryButton && onRetry != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
