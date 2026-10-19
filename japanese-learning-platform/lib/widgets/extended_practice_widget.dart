import 'package:flutter/material.dart';
import '../models/analysis_data.dart';
import '../core/theme/app_colors.dart';
import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 6.7 引申练习（三级）
/// 本题必懂 / 容易混淆 / 进阶拓展 + 迁移练习
class ExtendedPracticeWidget extends StatefulWidget {
  final ExtendedPractice practice;

  const ExtendedPracticeWidget({super.key, required this.practice});

  @override
  State<ExtendedPracticeWidget> createState() => _ExtendedPracticeWidgetState();
}

class _ExtendedPracticeWidgetState extends State<ExtendedPracticeWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              '引申与迁移',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: '本题必懂'),
              Tab(text: '容易混淆'),
              Tab(text: '进阶拓展'),
              Tab(text: '迁移练习'),
            ],
          ),
          const Divider(),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _mustKnowTab(),
                _confusingTab(),
                _advancedTab(),
                _exercisesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mustKnowTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: widget.practice.mustKnow.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withAlphaCompat(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.success.withAlphaCompat(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(item.explanation, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _confusingTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: widget.practice.confusingPairs.map((pair) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // 对比头
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlphaCompat(0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            pair.a,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pair.aDesc,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.compare_arrows, color: AppColors.warning),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlphaCompat(0.08),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(10),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            pair.b,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pair.bDesc,
                            style: const TextStyle(fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.key,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        const Text(
                          '关键差异',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(pair.difference,
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _exampleChip(pair.exampleA, AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _exampleChip(pair.exampleB, AppColors.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _exampleChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlphaCompat(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlphaCompat(0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _advancedTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: widget.practice.advanced.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlphaCompat(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.primary.withAlphaCompat(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: AppColors.primary, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _levelBadge(item.level),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.content, style: const TextStyle(fontSize: 14)),
            ],
          ),
        );
      }).toList(),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlphaCompat(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(
          color: c,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _exercisesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.practice.exercises.length,
      itemBuilder: (ctx, i) {
        final ex = widget.practice.exercises[i];
        return _TransferExerciseCard(exercise: ex, index: i);
      },
    );
  }
}

class _TransferExerciseCard extends StatefulWidget {
  final TransferExercise exercise;
  final int index;
  const _TransferExerciseCard({required this.exercise, required this.index});

  @override
  State<_TransferExerciseCard> createState() => _TransferExerciseCardState();
}

class _TransferExerciseCardState extends State<_TransferExerciseCard> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final correct = ex.answerIndex;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '迁移练习 ${widget.index + 1}',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(ex.question, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ...ex.choices.asMap().entries.map((e) {
            final i = e.key;
            final c = e.value;
            final isSelected = _selected == i;
            final isCorrect = i == correct;
            Color? color;
            if (_selected != null) {
              if (isCorrect) color = AppColors.success;
              else if (isSelected) color = AppColors.warning;
            }
            return InkWell(
              onTap: _selected == null
                  ? () => setState(() => _selected = i)
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: color?.withAlphaCompat(0.08) ?? Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: color ?? Colors.grey.shade300,
                    width: isSelected || isCorrect && _selected != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${String.fromCharCode(65 + i)}. ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(child: Text(c)),
                    if (_selected != null && isCorrect)
                      Icon(Icons.check, color: AppColors.success, size: 18),
                    if (_selected != null && isSelected && !isCorrect)
                      Icon(Icons.close, color: AppColors.warning, size: 18),
                  ],
                ),
              ),
            );
          }),
          if (_selected != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withAlphaCompat(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ex.explanation,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Built-in List.asMap() is used - no extension needed
