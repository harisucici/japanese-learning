/// 复习会话页面
///
/// 进入复习模式后,逐题展示,提交答案,SM-2 更新下次复习时间
/// 支持原题重做 / 相似题练习两种模式
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../core/theme/app_colors.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/theme.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/content_card.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';
/// 复习会话页面
class ReviewSessionPage extends StatefulWidget {
  final List<ReviewItem> items;
  final ReviewMode mode;

  const ReviewSessionPage({
    super.key,
    required this.items,
    required this.mode,
  });

  @override
  State<ReviewSessionPage> createState() => _ReviewSessionPageState();
}

class _ReviewSessionPageState extends State<ReviewSessionPage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSession();
    });
  }

  Future<void> _startSession() async {
    if (!_initialized) {
      StoreProvider.of<AppState>(context).dispatch(
        startReviewSession(
          items: widget.items,
          mode: widget.mode,
        ),
      );
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ReviewSessionState>(
      converter: (store) => store.state.reviewSession,
      builder: (context, sessionState) {
        final session = sessionState.session;

        if (session == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 监听会话完成
        if (session.isFinished && _initialized) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showResultDialog(session);
          });
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _showExitDialog();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('复习 (${session.completed}/${session.total})'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _showExitDialog,
              ),
            ),
            body: session.isFinished
                ? _buildCompletedState(context, session)
                : _buildQuestionCard(context, session),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(BuildContext context, ReviewSession session) {
    final currentItem = session.currentItem;
    if (currentItem == null) return const SizedBox.shrink();

    final questionState = StoreProvider.of<AppState>(context).state.questions;
    final question = questionState.questionsById[currentItem.questionId];

    if (question == null) {
      // 加载题目
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StoreProvider.of<AppState>(context).dispatch(
          loadQuestionById(currentItem.questionId),
        );
      });
      return const Center(child: CircularProgressIndicator());
    }

    return _ReviewQuestionView(
      question: question,
      session: session,
      mode: widget.mode,
      onAnswer: (optionId, isCorrect) async {
        StoreProvider.of<AppState>(context).dispatch(
          submitReviewAnswer(
            questionId: question.id,
            isCorrect: isCorrect,
          ),
        );
      },
    );
  }

  Widget _buildCompletedState(BuildContext context, ReviewSession session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ContentCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.celebration,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '复习完成!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultStat(
                    label: '正确率',
                    value: '${(session.accuracy * 100).toInt()}%',
                  ),
                  _ResultStat(
                    label: '正确',
                    value: '${session.correctCount}',
                  ),
                  _ResultStat(
                    label: '总数',
                    value: '${session.total}',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showResultDialog(ReviewSession session) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('复习完成'),
        content: Text(
          '正确率: ${(session.accuracy * 100).toInt()}%\n'
          '正确: ${session.correctCount}/${session.total}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('返回'),
          ),
        ],
      ),
    );
  }

  void _skipCurrent(ReviewSession session) {
    StoreProvider.of<AppState>(context).dispatch(
      submitReviewAnswer(
        questionId: session.currentItem!.questionId,
        isCorrect: false,
      ),
    );
  }

  Future<void> _showExitDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出复习?'),
        content: const Text('当前进度将丢失,确定退出吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定退出'),
          ),
        ],
      ),
    );
    if (result == true && mounted) {
      StoreProvider.of<AppState>(context).dispatch(endReviewSession());
      Navigator.of(context).pop();
    }
  }
}

/// 复习题目视图
class _ReviewQuestionView extends StatefulWidget {
  final Question question;
  final ReviewSession session;
  final ReviewMode mode;
  final Future<void> Function(String optionId, bool isCorrect) onAnswer;

  const _ReviewQuestionView({
    required this.question,
    required this.session,
    required this.mode,
    required this.onAnswer,
  });

  @override
  State<_ReviewQuestionView> createState() => _ReviewQuestionViewState();
}

class _ReviewQuestionViewState extends State<_ReviewQuestionView> {
  String? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 进度条
          LinearProgressIndicator(
            value: widget.session.total > 0
                ? widget.session.completed / widget.session.total
                : 0,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 模式标签
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs2,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlphaCompat(0.1),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              widget.mode.displayName,
              style: TextStyle(
                fontSize: AppTypography.labelSmall,
                fontWeight: AppTypography.semiBold,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 题目内容
          ContentCard(
            child: Text(
              q.content,
              style: textTheme.bodyLarge?.copyWith(
                fontFamily: AppTypography.fontFamily,
                height: AppTypography.lineHeightRelaxed,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 选项
          ...q.options.map((option) {
            final isSelected = _selected == option.id;
            final isCorrect = option.id == q.answer;
            Color? borderColor;
            Color? bgColor;
            if (_submitted) {
              if (isCorrect) {
                borderColor = AppColors.success;
                bgColor = AppColors.success50;
              } else if (isSelected) {
                borderColor = AppColors.error;
                bgColor = AppColors.error.withAlphaCompat(0.05);
              }
            } else if (isSelected) {
              borderColor = colorScheme.primary;
              bgColor = colorScheme.primary.withAlphaCompat(0.05);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ContentCard(
                color: bgColor,
                borderColor: borderColor,
                onTap: _submitted
                    ? null
                    : () => setState(() {
                          _selected = option.id;
                        }),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline,
                          width: 1.5,
                        ),
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        option.content,
                        style: textTheme.bodyMedium?.copyWith(
                          fontFamily: AppTypography.fontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.lg),

          // 提交按钮
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitted || _selected == null
                  ? null
                  : () async {
                      final isCorrect = _selected == q.answer;
                      setState(() => _submitted = true);
                      await widget.onAnswer(_selected!, isCorrect);
                    },
              child: Text(_submitted ? '已提交' : '提交答案'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;

  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: AppTypography.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
