/// 考试主页面
///
/// 倒计时 + 题目显示 + 答题卡 + 导航 + 自动保存 + 自动交卷
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../pages/exam_result_page.dart';
import '../widgets/submit_dialog.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 考试页面
class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  bool _showAnswerSheet = false;
  bool _navigatingToResult = false;

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ExamSessionState>(
      converter: (store) => store.state.examSession,
      builder: (context, examSessionState) {
        final session = examSessionState.session;

        if (session == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: Text('考试会话不存在')),
          );
        }

        // 考试已提交 -> 跳成绩页
        if (session.status == ExamStatus.submitted && !_navigatingToResult) {
          _navigatingToResult = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ExamResultPage()),
            );
          });
        }

        final question = session.currentQuestion;
        final isPaused = session.status == ExamStatus.paused;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _confirmExit();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: _buildAppBar(session),
            body: Stack(
              children: [
                Column(
                  children: [
                    _buildProgressBar(session),
                    if (isPaused) _buildPausedBanner(),
                    Expanded(
                      child: question == null
                          ? const Center(child: Text('暂无题目'))
                          : _QuestionCard(
                              question: question,
                              index: session.currentIndex,
                              total: session.questions.length,
                            ),
                    ),
                    _buildBottomBar(session),
                  ],
                ),
                if (_showAnswerSheet)
                  _AnswerSheetOverlay(
                    session: session,
                    onClose: () => setState(() => _showAnswerSheet = false),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ExamSession session) {
    final remaining = session.remainingSeconds;
    final h = remaining ~/ 3600;
    final m = (remaining % 3600) ~/ 60;
    final s = remaining % 60;
    final timeStr = h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    final isUrgent = remaining <= 300 && remaining > 0;
    final isPaused = session.status == ExamStatus.paused;

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _confirmExit,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.paperName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '第 ${session.currentIndex + 1} / ${session.questions.length} 题',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isPaused
                ? AppColors.warning.withAlphaCompat(0.15)
                : isUrgent
                    ? AppColors.error.withAlphaCompat(0.15)
                    : AppColors.primary.withAlphaCompat(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPaused
                    ? Icons.pause_circle_filled
                    : isUrgent
                        ? Icons.timer_off_rounded
                        : Icons.timer_rounded,
                size: 16,
                color: isPaused
                    ? AppColors.warning
                    : isUrgent
                        ? AppColors.error
                        : AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                isPaused ? '已暂停' : timeStr,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'JetBrains Mono',
                  color: isPaused
                      ? AppColors.warning
                      : isUrgent
                          ? AppColors.error
                          : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ExamSession session) {
    final progress = session.questions.isEmpty
        ? 0.0
        : (session.currentIndex + 1) / session.questions.length;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: AppColors.borderLight,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
      minHeight: 3,
    );
  }

  Widget _buildPausedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.warning.withAlphaCompat(0.15),
      child: Row(
        children: [
          const Icon(Icons.pause_circle_filled,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              '考试已暂停，计时已停止',
              style: TextStyle(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => StoreProvider.of<AppState>(context)
                .dispatch(ExamSessionResumed()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                '继续',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ExamSession session) {
    final question = session.currentQuestion;
    final isMarked = question != null &&
        session.markedQuestions.contains(question.id);
    final isCustom = session.mode == ExamMode.custom;
    final isPaused = session.status == ExamStatus.paused;

    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlphaCompat(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 答题卡
          _ToolButton(
            icon: Icons.grid_view_rounded,
            label: '答题卡',
            onTap: () => setState(() => _showAnswerSheet = true),
            badge: '${session.answeredCount}/${session.questions.length}',
          ),
          const SizedBox(width: 8),
          // 标记
          _ToolButton(
            icon: isMarked ? Icons.bookmark : Icons.bookmark_border_rounded,
            label: isMarked ? '已标记' : '标记',
            iconColor: isMarked ? AppColors.warning : null,
            onTap: question == null
                ? null
                : () => StoreProvider.of<AppState>(context).dispatch(
                    ExamSessionQuestionMarked(question.id, !isMarked)),
          ),
          if (isCustom) ...[
            const SizedBox(width: 8),
            _ToolButton(
              icon: isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              label: isPaused ? '继续' : '暂停',
              onTap: () {
                final store = StoreProvider.of<AppState>(context);
                if (isPaused) {
                  store.dispatch(ExamSessionResumed());
                } else {
                  store.dispatch(ExamSessionPaused());
                }
              },
            ),
          ],
          const Spacer(),
          // 上一题
          _NavButton(
            icon: Icons.chevron_left_rounded,
            label: '上一题',
            enabled: session.currentIndex > 0,
            onTap: () {
              StoreProvider.of<AppState>(context)
                  .dispatch(ExamSessionQuestionChanged(session.currentIndex - 1));
            },
          ),
          const SizedBox(width: 6),
          // 下一题
          _NavButton(
            icon: Icons.chevron_right_rounded,
            label: session.currentIndex == session.questions.length - 1
                ? '最后'
                : '下一题',
            trailing: session.currentIndex != session.questions.length - 1,
            enabled: session.currentIndex < session.questions.length - 1,
            onTap: () {
              StoreProvider.of<AppState>(context)
                  .dispatch(ExamSessionQuestionChanged(session.currentIndex + 1));
            },
          ),
          const SizedBox(width: 10),
          // 交卷
          GestureDetector(
            onTap: () => _showSubmitDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.success, AppColors.successDark],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withAlphaCompat(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '交卷',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmitDialog() async {
    final session = StoreProvider.of<AppState>(context).state.examSession.session;
    if (session == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withAlphaCompat(0.4),
      builder: (_) => SubmitDialog(session: session),
    );
    if (confirmed == true) {
      StoreProvider.of<AppState>(context)
          .dispatch(ExamSessionSubmitted(DateTime.now()));
    }
  }

  Future<void> _confirmExit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('退出考试？'),
        content: const Text('考试进度会自动保存，下次可继续作答。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('继续考试')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('退出')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }
}

// ============================================================
// 题目卡片 - 根据 session 答案渲染
// ============================================================

class _QuestionCard extends StatelessWidget {
  final Question question;
  final int index;
  final int total;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ExamSessionState>(
      converter: (store) => store.state.examSession,
      builder: (context, examSessionState) {
        final session = examSessionState.session;
        final selected = session?.answers[question.id];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 题型标签
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlphaCompat(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.type.displayNameZh,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '第 ${index + 1} / $total 题',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (question.tags.isNotEmpty)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlphaCompat(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        question.tags.first,
                        style: const TextStyle(
                          color: AppColors.successDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 题干
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.content,
                      style: const TextStyle(
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                      ),
                    ),
                    if (question.contentReading != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        question.contentReading!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // 选项
              ...question.options.map((opt) {
                final isSelected = selected == opt.id;
                final label = String.fromCharCode(65 + opt.index);
                return GestureDetector(
                  onTap: () => StoreProvider.of<AppState>(context)
                      .dispatch(ExamSessionAnswerSelected(question.id, opt.id)),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlphaCompat(0.08)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// 底部工具按钮
// ============================================================

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final String? badge;

  const _ToolButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: iconColor ?? AppColors.textPrimary),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final bool trailing;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.trailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.borderLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing) ...[
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : AppColors.textDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
            ],
            Icon(icon,
                size: 18,
                color: enabled ? Colors.white : AppColors.textDisabled),
            if (!trailing) ...[
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? Colors.white : AppColors.textDisabled,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 答题卡浮层
// ============================================================

class _AnswerSheetOverlay extends StatelessWidget {
  final ExamSession session;
  final VoidCallback onClose;

  const _AnswerSheetOverlay({required this.session, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlphaCompat(0.5),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 标题栏
              Row(
                children: [
                  const Text(
                    '答题卡',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '已答 ${session.answeredCount} / ${session.questions.length}',
                    style: TextStyle(
                      color: Colors.white.withAlphaCompat(0.85),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlphaCompat(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 图例
              Row(
                children: [
                  _LegendDot(color: AppColors.primary, label: '当前'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.success, label: '已答'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.warning, label: '已标记'),
                  const SizedBox(width: 10),
                  _LegendDot(color: AppColors.textDisabled, label: '未答'),
                ],
              ),
              const SizedBox(height: 14),
              // 网格
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: session.questions.length,
                    itemBuilder: (ctx, i) {
                      final q = session.questions[i];
                      final answered = session.answers.containsKey(q.id);
                      final marked = session.markedQuestions.contains(q.id);
                      final current = i == session.currentIndex;

                      Color bg;
                      Color fg;
                      if (current) {
                        bg = AppColors.primary;
                        fg = Colors.white;
                      } else if (marked) {
                        bg = AppColors.warning;
                        fg = Colors.white;
                      } else if (answered) {
                        bg = AppColors.success;
                        fg = Colors.white;
                      } else {
                        bg = AppColors.surfaceVariant;
                        fg = AppColors.textSecondary;
                      }

                      return GestureDetector(
                        onTap: () {
                          StoreProvider.of<AppState>(context)
                              .dispatch(ExamSessionQuestionChanged(i));
                          onClose();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Center(
                                child: Text(
                                  '${i + 1}',
                                  style: TextStyle(
                                    color: fg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (marked && !current)
                                const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.flag_rounded,
                                      color: Colors.white, size: 10),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}
