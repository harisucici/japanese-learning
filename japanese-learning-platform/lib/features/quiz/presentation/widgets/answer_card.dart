import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../redux/app_state.dart';

/// 答题卡片组件
class AnswerCard extends StatelessWidget {
  final QuizSession session;
  final void Function(int) onJumpTo;

  const AnswerCard({
    super.key,
    required this.session,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            '答题进度',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressInfo(),
          const SizedBox(height: 16),
          _buildQuestionGrid(context),
        ],
      ),
    );
  }

  Widget _buildProgressInfo() {
    final answeredCount = session.answers.length;
    final totalQuestions = session.questions.length;
    final progress = totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '已答 $answeredCount / $totalQuestions',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionGrid(BuildContext context) {
    final totalQuestions = session.questions.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: totalQuestions,
      itemBuilder: (context, index) {
        final isCurrent = index == session.currentIndex;
        final questionId = session.questions[index].id;
        final isAnswered = session.answers.containsKey(questionId);

        return GestureDetector(
          onTap: () => onJumpTo(index),
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.primary
                  : isAnswered
                      ? AppColors.success.withAlpha(0x14)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? AppColors.primary
                    : isAnswered
                        ? AppColors.success
                        : AppColors.border,
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? Colors.white
                      : isAnswered
                          ? AppColors.success
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
