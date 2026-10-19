import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.4 句子结构可视化
/// 高亮主谓宾、助词作用、修饰关系
class SentenceStructureWidget extends StatelessWidget {
  final SentenceStructure structure;

  const SentenceStructureWidget({super.key, required this.structure});

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
            Text(
              '句子结构',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // 结构块高亮
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 16,
                children: structure.blocks.asMap().entries.map((e) {
                  final index = e.key;
                  final block = e.value;
                  final color = Colors.blue;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: color.withAlphaCompat(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: color, width: 1.5),
                        ),
                        child: Text(
                          block.text,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          block.roleLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            // 图例
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: <MapEntry<String, Color>>[].map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: e.value,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _roleLabel(e.key),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
            // 修饰关系
            if (structure.relations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '修饰 / 依存关系',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...structure.relations.map((r) => _buildRelationRow(r)),
            ],
            // 省略成分
            if (structure.omitted.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                '省略成分',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...structure.omitted.map((o) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• $o', style: const TextStyle(fontSize: 14)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  String _roleLabel(String key) {
    const map = {
      'subject': '主题',
      'predicate': '谓语',
      'object': '宾语',
      'complement': '补语',
      'modifier': '修饰语',
      'particle': '助词',
    };
    return map[key] ?? key;
  }

  Widget _buildRelationRow(Relation r) {
    final fromBlock = structure.blocks[r.from];
    final toBlock = structure.blocks[r.to];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tag(fromBlock.text, fromBlock.colorKey),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          ),
          _tag(toBlock.text, toBlock.colorKey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${r.kind}：${r.note}',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, String colorKey) {
    final color = Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlphaCompat(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
      ),
    );
  }
}

// Built-in List.asMap() is used - no extension needed
