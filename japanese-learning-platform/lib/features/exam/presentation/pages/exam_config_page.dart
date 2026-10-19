/// 考试配置页面
///
/// 选择等级、试卷、考试模式（仿真/自定义），然后开始考试
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../pages/exam_page.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 各等级对应的考试时长（秒）
const Map<JLPTLevel, int> kExamDurations = {
  JLPTLevel.n5: 105 * 60, // 105 分钟
  JLPTLevel.n4: 125 * 60, // 125 分钟
  JLPTLevel.n3: 140 * 60, // 140 分钟
  JLPTLevel.n2: 155 * 60, // 155 分钟
  JLPTLevel.n1: 170 * 60, // 170 分钟
};

/// 模拟试卷列表（演示用）
class MockPaper {
  final String id;
  final String name;
  final JLPTLevel level;
  final int questionCount;
  final String description;

  const MockPaper({
    required this.id,
    required this.name,
    required this.level,
    required this.questionCount,
    required this.description,
  });
}

/// 各等级可用试卷
List<MockPaper> getMockPapers(JLPTLevel level) {
  return [
    MockPaper(
      id: '${level.name}_mock_1',
      name: '${level.displayName} 模拟试卷一',
      level: level,
      questionCount: 30,
      description: '综合练习：词汇、语法、阅读',
    ),
    MockPaper(
      id: '${level.name}_mock_2',
      name: '${level.displayName} 模拟试卷二',
      level: level,
      questionCount: 25,
      description: '专项突破：语法、阅读',
    ),
    MockPaper(
      id: '${level.name}_quick',
      name: '${level.displayName} 快速测验',
      level: level,
      questionCount: 15,
      description: '快速测验：15 题精选',
    ),
  ];
}

/// 考试配置页面
class ExamConfigPage extends StatefulWidget {
  const ExamConfigPage({super.key});

  @override
  State<ExamConfigPage> createState() => _ExamConfigPageState();
}

class _ExamConfigPageState extends State<ExamConfigPage> {
  JLPTLevel _selectedLevel = JLPTLevel.n5;
  MockPaper? _selectedPaper;
  ExamMode _selectedMode = ExamMode.simulation;

  @override
  Widget build(BuildContext context) {
    final papers = getMockPapers(_selectedLevel);
    // 默认选中第一个
    if (_selectedPaper == null || _selectedPaper!.level != _selectedLevel) {
      _selectedPaper = papers.first;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('模拟考试'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildLevelSelector(),
            const SizedBox(height: 24),
            _buildPaperSelector(papers),
            const SizedBox(height: 24),
            _buildModeSelector(),
            const SizedBox(height: 32),
            _buildStartButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlphaCompat(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.school_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            '模拟考试',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '选择等级和试卷，开始一场完整的模拟考试',
            style: TextStyle(
              color: Colors.white.withAlphaCompat(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelSelector() {
    return _ConfigSection(
      title: '选择等级',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: JLPTLevel.values.map((level) {
          final isSelected = level == _selectedLevel;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedLevel = level;
              _selectedPaper = null;
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: Text(
                level.displayName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaperSelector(List<MockPaper> papers) {
    return _ConfigSection(
      title: '选择试卷',
      child: Column(
        children: papers.map((paper) {
          final isSelected = paper.id == _selectedPaper?.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedPaper = paper),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withAlphaCompat(0.05)
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.primary.withAlphaCompat(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.description_rounded,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paper.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${paper.questionCount} 题 · ${paper.description}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 22,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildModeSelector() {
    return _ConfigSection(
      title: '考试模式',
      child: Row(
        children: [
          Expanded(
            child: _ModeCard(
              icon: Icons.timer_rounded,
              title: '仿真模式',
              subtitle: '严格计时，不可暂停',
              isSelected: _selectedMode == ExamMode.simulation,
              onTap: () => setState(() => _selectedMode = ExamMode.simulation),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ModeCard(
              icon: Icons.tune_rounded,
              title: '自定义模式',
              subtitle: '可暂停，更灵活',
              isSelected: _selectedMode == ExamMode.custom,
              onTap: () => setState(() => _selectedMode = ExamMode.custom),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    final paper = _selectedPaper;
    final duration = kExamDurations[_selectedLevel]!;
    final minutes = duration ~/ 60;

    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: () => _startExam(paper!, duration),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlphaCompat(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                '开始考试',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($minutes 分钟)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withAlphaCompat(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startExam(MockPaper paper, int durationSeconds) async {
    final store = StoreProvider.of<AppState>(context);
    
    // 加载该等级题目
    await store.dispatch(loadQuestionsByLevel(_selectedLevel));
    
    if (!mounted) return;
    
    final questionsState = store.state.questions;
    final examQuestions = questionsState.error == null
        ? questionsState.questions.where((q) => q.level == _selectedLevel).toList()
        : <Question>[];
    
    if (examQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂无可用题目，请先导入题库'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // 取前 N 题（与试卷匹配）
    final takeCount = paper.questionCount.clamp(1, examQuestions.length);
    final selectedQuestions = examQuestions.take(takeCount).toList();

    // 启动考试会话
    store.dispatch(startExamSession(
      level: _selectedLevel,
      paperName: paper.name,
      mode: _selectedMode,
      questions: selectedQuestions,
      totalSeconds: durationSeconds,
    ));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const ExamPage(),
      ),
    );
  }
}

/// 配置区块
class _ConfigSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ConfigSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// 模式选择卡片
class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlphaCompat(0.05)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
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
