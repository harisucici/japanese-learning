import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.2 原文与翻译组件
/// 显示：日文（假名注音可开关）、直译、意译
class AnnotatedTextWidget extends StatefulWidget {
  final List<AnnotatedSegment> segments;
  final String literalTranslation;
  final String naturalTranslation;
  final bool showFilledAnswer; // 是否填答案后的句子

  const AnnotatedTextWidget({
    super.key,
    required this.segments,
    required this.literalTranslation,
    required this.naturalTranslation,
    this.showFilledAnswer = false,
  });

  @override
  State<AnnotatedTextWidget> createState() => _AnnotatedTextWidgetState();
}

class _AnnotatedTextWidgetState extends State<AnnotatedTextWidget> {
  bool _showRuby = true; // 是否显示假名注音

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题 + 注音开关
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '原文与翻译',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Text('假名注音'),
                    Switch(
                      value: _showRuby,
                      onChanged: (v) => setState(() => _showRuby = v),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 日文原文（带注音）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 2,
                runSpacing: _showRuby ? 24 : 8,
                children: widget.segments.map((seg) {
                  return _buildSegment(seg, _showRuby);
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // 直译
            _buildTranslationRow(
              label: '直译',
              text: widget.literalTranslation,
              color: AppColors.primary,
            ),
            const SizedBox(height: 8),
            // 意译
            _buildTranslationRow(
              label: '意译',
              text: widget.naturalTranslation,
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(AnnotatedSegment seg, bool showRuby) {
    if (seg.isBlank) {
      return Container(
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
          color: AppColors.primary.withAlphaCompat(0.1),
        ),
        child: const Center(child: Text('？？？', style: TextStyle(color: AppColors.primary))),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRuby && seg.rubyText != null)
          Text(
            seg.rubyText!,
            style: TextStyle(
              fontSize: 12,
              color: seg.isAnswer ? AppColors.success : Colors.grey.shade600,
              fontWeight: seg.isAnswer ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        Text(
          seg.surface,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: seg.isAnswer ? AppColors.success : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationRow({
    required String label,
    required String text,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15)),
        ),
      ],
    );
  }
}
