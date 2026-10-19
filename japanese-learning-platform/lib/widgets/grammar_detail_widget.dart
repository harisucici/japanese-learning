import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.5 语法详情组件
/// 9 字段：名称、含义、接续、公式、场景、例句、等级、标签、易混
class GrammarDetailWidget extends StatelessWidget {
  final GrammarPoint grammar;
  final int index;
  final int total;

  const GrammarDetailWidget({
    super.key,
    required this.grammar,
    required this.index,
    required this.total,
  });

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
            // 标题
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '语法 ${index + 1}/$total',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  grammar.level.name.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _levelBadge(grammar.level),
              ],
            ),
            const SizedBox(height: 12),
            // 名称
            Text(
              grammar.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            // 含义
            _field(Icons.menu_book, '含义', grammar.meaning, AppColors.primary),
            const SizedBox(height: 12),
            // 接续
            _field(Icons.link, '接续', grammar.connection, AppColors.primary),
            const SizedBox(height: 12),
            // 公式
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withAlphaCompat(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.success.withAlphaCompat(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.functions, color: AppColors.success, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        '公式',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    grammar.formula,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 场景
            _field(Icons.place, '使用场景', grammar.scenario, AppColors.primary),
            const SizedBox(height: 12),
            // 例句
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.format_quote, color: AppColors.warning, size: 18),
                    const SizedBox(width: 6),
                    const Text(
                      '例句',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...grammar.examples.map((ex) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        ex,
                        style: const TextStyle(fontSize: 15),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            // 标签
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: grammar.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlphaCompat(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$t',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            // 易混
            if (grammar.similar.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.compare_arrows, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 6),
                  const Text(
                    '相关语法',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: grammar.similar
                    .map((s) => Chip(
                          label: Text(s),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _levelBadge(JLPTLevel level) {
    const map = {
      JLPTLevel.n5: Color(0xFF10B981),
      JLPTLevel.n4: Color(0xFF3B82F6),
      JLPTLevel.n3: Color(0xFFF59E0B),
      JLPTLevel.n2: Color(0xFFEF4444),
      JLPTLevel.n1: Color(0xFF8B5CF6),
    };
    final c = map[level] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlphaCompat(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
