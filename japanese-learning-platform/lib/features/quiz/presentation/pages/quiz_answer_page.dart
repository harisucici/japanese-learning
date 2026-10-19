/// 答题页面（核心答题交互）
///
/// 题目显示、选项交互、提交逻辑、进度保存
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/models/models.dart';
import '../widgets/answer_card.dart';
import '../widgets/option_tile.dart';
import '../widgets/quiz_nav_bar.dart';
import 'quiz_result_page.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 答题交互页面
class QuizAnswerPage extends StatefulWidget {
  final String level;

  const QuizAnswerPage({super.key, required this.level});

  @override
  State<QuizAnswerPage> createState() => _QuizAnswerPageState();
}

class _QuizAnswerPageState extends State<QuizAnswerPage> {
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuestions());
  }

  Future<void> _loadQuestions() async {
    final jlptLevel = JLPTLevel.fromString(widget.level);
    final store = StoreProvider.of<AppState>(context);
    
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await store.dispatch(loadQuestionsByLevel(jlptLevel));
      if (!mounted) return;
      final state = store.state.questions;
      if (state.error != null) throw StateError(state.error!);
      final questions = state.questions.where((q) => q.level == jlptLevel).toList();
      if (questions.isEmpty) {
        setState(() => _loadError = '该等级暂无可用题目');
        return;
      }
      await store.dispatch(startQuizSession(jlptLevel, questions));
    } catch (_) {
      if (mounted) setState(() => _loadError = '题目加载失败，请重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuizSessionState>(
      converter: (store) => store.state.quizSession,
      builder: (context, quizSessionState) {
        final session = quizSessionState.session;
        if (_loading) {
          return Scaffold(
            appBar: AppBar(title: const Text('正在加载题目')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (_loadError != null || session == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('练习')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError ?? '练习尚未开始'),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _loadQuestions, child: const Text('重新加载')),
                ],
              ),
            ),
          );
        }

        if (session.status == QuizStatus.submitted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const QuizResultPage(),
              ),
            );
          });
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _showExitDialog();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(session),
            body: Column(
              children: [
                Expanded(child: _buildQuestionContent(session)),
                _buildBottomBar(session),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(QuizSession session) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _showExitDialog,
      ),
      title: Text(
        '${session.currentIndex + 1} / ${session.questions.length}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          onPressed: () => _showAnswerCard(session),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: (session.currentIndex + 1) / session.questions.length,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 4,
        ),
      ),
    );
  }

  Widget _buildQuestionContent(QuizSession session) {
    final question = session.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final userAnswer = session.answers[question.id];
    final isSubmitted = session.submittedAnswers.containsKey(question.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuestionCard(question),
          const SizedBox(height: AppSpacing.xxxxl),
          ...question.options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OptionTile(
                option: option,
                isSelected: userAnswer == option.id,
                isCorrect:
                    isSubmitted ? question.isCorrect(option.id) : null,
                onTap: isSubmitted
                    ? null
                    : () {
                        StoreProvider.of<AppState>(context)
                            .dispatch(selectQuizAnswer(question.id, option.id));
                      },
              ),
            );
          }),
          if (isSubmitted) ...[
            const SizedBox(height: 16),
            _buildExplanation(question, userAnswer),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlphaCompat(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.type.displayName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withAlphaCompat(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  question.level.displayName,
                  style: const TextStyle(
                    color: AppColors.info,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            question.content,
            style: const TextStyle(
              fontSize: 17,
              color: AppColors.textPrimary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanation(Question question, String? userAnswer) {
    final isCorrect =
        userAnswer != null && question.isCorrect(userAnswer);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withAlphaCompat(0.05)
            : AppColors.error.withAlphaCompat(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withAlphaCompat(0.2)
              : AppColors.error.withAlphaCompat(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: isCorrect ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? '回答正确！' : '回答错误',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCorrect ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '正确答案: ${question.correctOption?.content ?? "N/A"}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(QuizSession session) {
    final question = session.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    final userAnswer = session.answers[question.id];
    final isSubmitted = session.submittedAnswers.containsKey(question.id);
    final isFirst = session.currentIndex == 0;
    final isLast = session.currentIndex == session.questions.length - 1;

    return QuizNavBar(
      isFirst: isFirst,
      isLast: isLast,
      isSubmitted: isSubmitted,
      hasAnswer: userAnswer != null,
      onPrevious: () {
        StoreProvider.of<AppState>(context).dispatch(previousQuizQuestion());
      },
      onNext: () {
        StoreProvider.of<AppState>(context).dispatch(nextQuizQuestion());
      },
      onSubmit: () {
        if (isLast) {
          _showSubmitAllDialog();
        } else {
          StoreProvider.of<AppState>(context).dispatch(submitCurrentQuizQuestion());
        }
      },
    );
  }

  void _showAnswerCard(QuizSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return AnswerCard(
            session: session,
            onJumpTo: (index) {
              StoreProvider.of<AppState>(context).dispatch(jumpToQuizQuestion(index));
              Navigator.of(context).pop();
            },
          );
        },
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出练习'),
        content: const Text('进度已自动保存，下次可继续答题。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续答题'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('确认退出'),
          ),
        ],
      ),
    );
  }

  void _showSubmitAllDialog() {
    final session = StoreProvider.of<AppState>(context).state.quizSession.session;
    if (session == null) return;
    final answered = session.answers.length;
    final total = session.questions.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('提交全部答案'),
        content: Text('已完成 $answered/$total 题，确认提交？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('继续答题'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              StoreProvider.of<AppState>(context).dispatch(submitAllQuiz());
            },
            child: const Text(
              '确认提交',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
