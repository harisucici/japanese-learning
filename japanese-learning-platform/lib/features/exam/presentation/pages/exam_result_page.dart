/// 考试成绩分析页面
///
/// 显示总分、正确率、用时、各题型得分、等级评估、错题列表、建议复习内容
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 考试成绩页面
class ExamResultPage extends StatelessWidget {
  const ExamResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ExamSessionState>(
      converter: (store) => store.state.examSession,
      builder: (context, examSessionState) {
        final session = examSessionState.session;

        if (session == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: const Center(child: Text('考试数据不存在')),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            title: const Text(
              '考试成绩',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildScoreHeader(context, session),
                const SizedBox(height: 20),
                _buildStatsRow(context, session),
                const SizedBox(height: 20),
                _buildTypeBreakdown(context, session),
                const SizedBox(height: 20),
                _buildGradeEvaluation(context, session),
                const SizedBox(height: 20),
                _buildWrongAnswersList(context, session),
                const SizedBox(height: 20),
                _buildReviewSuggestions(context, session),
                const SizedBox(height: 24),
                _buildActionButtons(context, session),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreHeader(BuildContext context, ExamSession session) {
    final score = session.accuracy * 100;
    final passed = score >= _getPassLine(session.level);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: passed
              ? [AppColors.success, AppColors.successDark]
              : [AppColors.error, const Color(0xFFB91C1C)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (passed ? AppColors.success : AppColors.error)
                .withAlphaCompat(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // 分数圆圈
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withAlphaCompat(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    '总分',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 通过/未通过徽章
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlphaCompat(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  passed ? '合格' : '未合格',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, ExamSession session) {
    final total = session.questions.length;
    final correct = session.correctCount;
    final accuracy = session.accuracy;
    final durationSec = session.durationInSeconds;
    final minutes = durationSec ~/ 60;
    final seconds = durationSec % 60;

    return Row(
      children: [
        _StatCard(
          icon: Icons.check_circle_outline,
          label: '正确数',
          value: '$correct / $total',
          color: AppColors.success,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.percent_outlined,
          label: '正确率',
          value: '${(accuracy * 100).toStringAsFixed(1)}%',
          color: AppColors.primary,
        ),
        const SizedBox(width: 10),
        _StatCard(
          icon: Icons.timer_outlined,
          label: '用时',
          value: '$minutes:$seconds',
          color: AppColors.info,
        ),
      ],
    );
  }

  Widget _buildTypeBreakdown(BuildContext context, ExamSession session) {
    // Group questions by type
    final typeMap = <QuestionType, List<Question>>{};
    for (final q in session.questions) {
      typeMap.putIfAbsent(q.type, () => []).add(q);
    }

    final typeStats = <_TypeStat>[];
    for (final entry in typeMap.entries) {
      final type = entry.key;
      final questions = entry.value;
      int correct = 0;
      for (final q in questions) {
        final userAns = session.answers[q.id];
        if (userAns != null && q.isCorrect(userAns)) {
          correct++;
        }
      }
      typeStats.add(_TypeStat(
        type: type,
        total: questions.length,
        correct: correct,
      ));
    }

    // Sort by accuracy descending
    typeStats.sort((a, b) => (b.correct / b.total).compareTo(a.correct / a.total));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '各题型得分',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...typeStats.map((stat) {
            final accuracy = stat.total > 0 ? stat.correct / stat.total : 0.0;
            final percentage = (accuracy * 100).toStringAsFixed(0);
            final color = accuracy >= 0.8
                ? AppColors.success
                : accuracy >= 0.6
                    ? AppColors.primary
                    : accuracy >= 0.4
                        ? AppColors.warning
                        : AppColors.error;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        stat.type.displayNameZh,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${stat.correct}/${stat.total} ($percentage%)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: accuracy,
                      backgroundColor: AppColors.borderLight,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGradeEvaluation(BuildContext context, ExamSession session) {
    final score = session.accuracy * 100;
    final passLine = _getPassLine(session.level);
    final gap = (score - passLine).abs();

    String message;
    IconData icon;
    Color color;

    if (score >= 90) {
      message = '优秀！继续保持';
      icon = Icons.emoji_events;
      color = AppColors.success;
    } else if (score >= passLine) {
      message = '合格，还有提升空间';
      icon = Icons.check_circle;
      color = AppColors.success;
    } else if (gap <= 10) {
      message = '接近合格线，加油！';
      icon = Icons.trending_up;
      color = AppColors.warning;
    } else {
      message = '需要更多练习';
      icon = Icons.school;
      color = AppColors.error;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlphaCompat(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlphaCompat(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withAlphaCompat(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '合格线：$passLine 分，你的得分：${score.toStringAsFixed(1)} 分',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWrongAnswersList(
    BuildContext context,
    ExamSession session,
  ) {
    final wrongQuestions = <Question>[];
    for (final q in session.questions) {
      final userAns = session.answers[q.id];
      if (userAns == null || !q.isCorrect(userAns)) {
        wrongQuestions.add(q);
      }
    }

    if (wrongQuestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.success.withAlphaCompat(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.success.withAlphaCompat(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.celebration, color: AppColors.success, size: 24),
            SizedBox(width: 10),
            Text(
              '全部正确，无错题！',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '错题列表',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlphaCompat(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${wrongQuestions.length} 题',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...wrongQuestions.map((q) {
            final userAns = session.answers[q.id];
            final correctOption = q.correctOption;
            final userOption = userAns != null ? q.getOptionById(userAns) : null;

            return GestureDetector(
              onTap: () {
                final levelName = session.level.name.toLowerCase();
                final uri = Uri(
                  path: '/quiz/$levelName/answer',
                  queryParameters: {'questionId': q.id},
                );
                context.push(uri.toString());
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlphaCompat(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            q.type.displayNameZh,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      q.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (userOption != null)
                      Row(
                        children: [
                          const Icon(Icons.close,
                              color: AppColors.error, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '你的答案：${userOption.content}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (userOption == null)
                      const Row(
                        children: [
                          Icon(Icons.remove_circle_outline,
                              color: AppColors.textHint, size: 14),
                          SizedBox(width: 4),
                          Text(
                            '未作答',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textHint,
                            ),
                          ),
                        ],
                      ),
                    if (correctOption != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check,
                              color: AppColors.success, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '正确答案：${correctOption.content}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReviewSuggestions(BuildContext context, ExamSession session) {
    // Analyze weak areas
    final typeMap = <QuestionType, List<Question>>{};
    for (final q in session.questions) {
      typeMap.putIfAbsent(q.type, () => []).add(q);
    }

    final weakTypes = <String>[];
    for (final entry in typeMap.entries) {
      final type = entry.key;
      final questions = entry.value;
      int correct = 0;
      for (final q in questions) {
        final userAns = session.answers[q.id];
        if (userAns != null && q.isCorrect(userAns)) {
          correct++;
        }
      }
      final accuracy = questions.isNotEmpty ? correct / questions.length : 0.0;
      if (accuracy < 0.6) {
        weakTypes.add(type.displayNameZh);
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '建议复习内容',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (weakTypes.isEmpty)
            const Text(
              '表现均衡，继续保持！可以挑战更高难度或复习错题。',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '以下题型需要加强：',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: weakTypes
                      .map((t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withAlphaCompat(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.warning.withAlphaCompat(0.3)),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ExamSession session,
  ) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Text(
                  '返回首页',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlphaCompat(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  '再来一次',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getPassLine(JLPTLevel level) {
    switch (level) {
      case JLPTLevel.n5:
        return 80;
      case JLPTLevel.n4:
        return 90;
      case JLPTLevel.n3:
        return 95;
      case JLPTLevel.n2:
        return 90;
      case JLPTLevel.n1:
        return 100;
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeStat {
  final QuestionType type;
  final int total;
  final int correct;

  _TypeStat({
    required this.type,
    required this.total,
    required this.correct,
  });
}
