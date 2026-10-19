/// 考试配置页面（真题库）
///
/// 星野京都风格 × Material Design 3
/// 全幅沉浸式布局 + 极端留白 + 轻盈字体
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../../../../redux/redux.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_illustrations.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/app_scaffold.dart';
import '../pages/exam_page.dart';

import 'package:japanese_learning_platform/utils/color_extensions.dart';

/// 各等级对应的考试时长（秒）
const Map<JLPTLevel, int> kExamDurations = {
  JLPTLevel.n5: 105 * 60,
  JLPTLevel.n4: 125 * 60,
  JLPTLevel.n3: 140 * 60,
  JLPTLevel.n2: 155 * 60,
  JLPTLevel.n1: 170 * 60,
};

/// 模拟试卷列表
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
    if (_selectedPaper == null || _selectedPaper!.level != _selectedLevel) {
      _selectedPaper = papers.first;
    }

    return AppScaffold(
      backgroundColor: AppColors.washi,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全幅 Hero 区域
          HeroImageArea(
            height: 400,
            primaryColor: AppColors.primary,
            illustration: KyotoToriiIllustration(
              width: 280,
              height: 200,
              color: AppColors.shu,
            ),
            overlayText: '学問の道',
          ),

          // 标题区域 - 极端留白
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xxxxl,
              80,
              AppSpacing.xxxxl,
              60,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '真题库',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: AppColors.sumi,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '选择等级和试卷，开始一场完整的模拟考试',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: AppColors.sumiLighter,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // 等级选择 - 不对称布局
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '等级',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: JLPTLevel.values.map((level) {
                    final isSelected = level == _selectedLevel;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xxxl),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedLevel = level;
                          _selectedPaper = null;
                        }),
                        child: Column(
                          children: [
                            FamilyCrestLevelIcon(
                              level: level.displayName,
                              size: 56,
                              color: AppColors.kincha,
                              isSelected: isSelected,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              level.displayName,
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: isSelected ? AppColors.sumi : AppColors.sumiLighter,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 80),

          // 试卷选择 - 编辑式列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '试卷',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                ...papers.map((paper) => _buildPaperItem(context, paper)),
              ],
            ),
          ),

          const SizedBox(height: 80),

          // 考试模式
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '模式',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
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
                    const SizedBox(width: AppSpacing.xxl),
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
              ],
            ),
          ),

          const SizedBox(height: 80),

          // 开始按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () => _startExam(_selectedPaper!, kExamDurations[_selectedLevel]!),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: AppColors.shu,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        '开始考试',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '(${kExamDurations[_selectedLevel]! ~/ 60} 分钟)',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPaperItem(BuildContext context, MockPaper paper) {
    final isSelected = paper.id == _selectedPaper?.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaper = paper),
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : AppColors.washiBorder,
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paper.name,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.sumi,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${paper.questionCount} 题 · ${paper.description}',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.sumiLighter,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_outline,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startExam(MockPaper paper, int durationSeconds) async {
    final store = StoreProvider.of<AppState>(context);
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
          backgroundColor: AppColors.shu,
        ),
      );
      return;
    }

    final takeCount = paper.questionCount.clamp(1, examQuestions.length);
    final selectedQuestions = examQuestions.take(takeCount).toList();

    store.dispatch(startExamSession(
      level: _selectedLevel,
      paperName: paper.name,
      mode: _selectedMode,
      questions: selectedQuestions,
      totalSeconds: durationSeconds,
    ));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ExamPage()),
    );
  }
}

/// 模式选择卡片 - 极简风格
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.washiBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.sumiLighter,
              size: 20,
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.sumi,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w300,
                color: AppColors.sumiLighter,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
