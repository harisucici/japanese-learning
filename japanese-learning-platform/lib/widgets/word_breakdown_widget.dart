import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.3 逐词拆解组件
/// 点击词显示：原形、读音、词性、含义、活用过程
class WordBreakdownWidget extends StatelessWidget {
  final List<WordBreakdown> words;

  const WordBreakdownWidget({super.key, required this.words});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '逐词拆解',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              '点击词语查看详细解析',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children: words.map((w) => _buildWordChip(context, w)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordChip(BuildContext context, WordBreakdown w) {
    return InkWell(
      onTap: () => _showWordDetail(context, w),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlphaCompat(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withAlphaCompat(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              w.surface,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (w.reading != w.surface)
              Text(
                w.reading,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showWordDetail(BuildContext context, WordBreakdown w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  // 词面
                  Center(
                    child: Text(
                      w.surface,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      w.reading,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 基本信息
                  _buildInfoTile(
                    Icons.translate,
                    '原形',
                    w.dictionaryForm,
                    AppColors.primary,
                  ),
                  _buildInfoTile(
                    Icons.category,
                    '词性',
                    w.partOfSpeech,
                    AppColors.primary,
                  ),
                  _buildInfoTile(
                    Icons.menu_book,
                    '含义',
                    w.meaning,
                    AppColors.success,
                  ),
                  if (w.note.isNotEmpty)
                    _buildInfoTile(
                      Icons.info_outline,
                      '备注',
                      w.note,
                      Colors.grey.shade600,
                    ),
                  // 活用过程
                  if (w.conjugation != null) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      '活用变化',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlphaCompat(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '类别：${w.conjugation!.typeName}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${w.conjugation!.fromForm} → ${w.conjugation!.toForm}',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '变化步骤：',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          ...w.conjugation!.steps.map((s) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Text('• $s'),
                              )),
                          const SizedBox(height: 12),
                          Text(
                            w.conjugation!.rule,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


