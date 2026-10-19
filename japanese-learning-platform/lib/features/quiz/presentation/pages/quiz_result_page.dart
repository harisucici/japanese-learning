import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../redux/app_state.dart';
import '../../../../shared/models/models.dart';

/// 答题结果页面
class QuizResultPage extends StatelessWidget {
  const QuizResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuizSessionState>(
      converter: (store) => store.state.quizSession,
      builder: (context, quizState) {
        final session = quizState.session;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('答题结果'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          body: session == null
              ? const Center(child: Text('没有答题记录'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScoreCard(session),
                      const SizedBox(height: 20),
                      _buildStatsCard(session),
                      const SizedBox(height: 20),
                      _buildWrongQuestions(session),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildScoreCard(QuizSession session) {
    final total = session.questions.length;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(0x3D),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            '答题完成',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${session.correctCount}/$total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '正确率 ${(session.accuracy * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: Colors.white.withAlpha(0xE6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(QuizSession session) {
    final wrongCount = session.questions.length - session.correctCount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '答题统计',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                label: '正确',
                value: session.correctCount.toString(),
                color: AppColors.success,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                icon: Icons.cancel,
                label: '错误',
                value: wrongCount.toString(),
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                icon: Icons.timer,
                label: '用时',
                value: _formatDuration(session.durationInSeconds),
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(0x14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWrongQuestions(QuizSession session) {
    // Use submittedAnswers to know which were wrong
    final wrongQuestionIds = session.submittedAnswers.entries
        .where((e) => !e.value)
        .map((e) => e.key)
        .toList();

    final wrongQuestions = wrongQuestionIds
        .map((qid) => session.questions.firstWhere((q) => q.id == qid))
        .toList();

    if (wrongQuestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(0x14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppColors.success,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              '太棒了！全部答对！',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '错题回顾',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...wrongQuestions.map((question) {
          final userAnswer = session.answers[question.id];
          return _buildQuestionCard(question, userAnswer);
        }),
      ],
    );
  }

  Widget _buildQuestionCard(Question question, String? userAnswer) {
    final correctOption = question.correctOption;
    final userOption = userAnswer != null
        ? question.options.firstWhere(
            (o) => o.id == userAnswer,
            orElse: () => question.options.first,
          )
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
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
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(0x14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.type.displayName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.cancel,
                color: AppColors.error,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          _buildAnswerRow(
            label: '你的答案',
            content: userOption?.content ?? '未作答',
            isCorrect: false,
          ),
          const SizedBox(height: 8),
          _buildAnswerRow(
            label: '正确答案',
            content: correctOption?.content ?? 'N/A',
            isCorrect: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerRow({
    required String label,
    required String content,
    required bool isCorrect,
  }) {
    final color = isCorrect ? AppColors.success : AppColors.error;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(0x14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}分${secs}秒';
    }
    return '${secs}秒';
  }
}
