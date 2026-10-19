/// 模拟考试页面
///
/// 星野京都风格 × Material Design 3
/// 全幅沉浸式布局 + 极端留白 + 编辑式杂志排版
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_illustrations.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// 模拟考试页面
class MockExamPage extends StatefulWidget {
  const MockExamPage({super.key});

  @override
  State<MockExamPage> createState() => _MockExamPageState();
}

class _MockExamPageState extends State<MockExamPage> {
  String? _selectedLevel;

  @override
  Widget build(BuildContext context) {
    final allPapers = _generateMockPapers();
    final filteredPapers = _selectedLevel == null
        ? allPapers
        : allPapers.where((p) => p.level == _selectedLevel).toList();

    return AppScaffold(
      scrollable: true,
      backgroundColor: AppColors.washi,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全幅 Hero 区域 - 富士山
          HeroImageArea(
            height: 420,
            primaryColor: AppColors.primary,
            secondaryColor: AppColors.primaryDark,
            illustration: MtFujiIllustration(
              width: 300,
              height: 160,
              mountainColor: AppColors.primary,
            ),
            overlayText: '模擬試験',
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
                  '模拟考试',
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
                  '历年 JLPT 真题 · 完整模拟测试',
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

          // 等级筛选 - 简约文字链接风格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Row(
              children: [
                _buildFilterLink(
                  label: '全部',
                  isSelected: _selectedLevel == null,
                  onTap: () => setState(() => _selectedLevel = null),
                ),
                const SizedBox(width: 32),
                ...['N5', 'N4', 'N3', 'N2', 'N1'].map((level) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: _buildFilterLink(
                      label: level,
                      isSelected: _selectedLevel == level,
                      onTap: () => setState(() => _selectedLevel = level),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 60),

          // 试卷列表 - 编辑式/杂志目录风格
          if (filteredPapers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxxxl),
              child: Center(
                child: Text(
                  '暂无该等级的模拟考试',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: AppColors.sumiLighter,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
              child: Column(
                children: [
                  // 列表头 - 杂志目录风格
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.sumi,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            '年份',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.sumiLighter,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '等级',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.sumiLighter,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            '名称',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.sumiLighter,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: Text(
                            '题数 / 时长',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.sumiLighter,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            '难度',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.sumiLighter,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 列表项
                  ...filteredPapers.map((paper) => _buildPaperRow(paper)),
                ],
              ),
            ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildFilterLink({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.sumi : Colors.transparent,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
            color: isSelected ? AppColors.sumi : AppColors.sumiLighter,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildPaperRow(_MockPaperData paper) {
    return GestureDetector(
      onTap: () => _startMockExam(paper),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.washiBorder,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(
                '${paper.year}',
                style: TextStyle(
                  fontFamily: AppTypography.serifFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: AppColors.sumi,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: Text(
                paper.level,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.kincha,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(
              child: Text(
                paper.title,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.sumi,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                '${paper.questionCount}题 / ${paper.durationMinutes}分',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: AppColors.sumiLighter,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(
              width: 60,
              child: _buildDifficultyDots(paper.difficulty),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyDots(int difficulty) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < difficulty ? AppColors.shu : AppColors.washiBorder,
          ),
        );
      }),
    );
  }

  void _startMockExam(_MockPaperData paper) {
    context.push('/exam/config');
  }

  List<_MockPaperData> _generateMockPapers() {
    final papers = <_MockPaperData>[];
    final levels = ['N5', 'N4', 'N3', 'N2', 'N1'];
    final years = [2024, 2023, 2022, 2021, 2020, 2019];

    for (final level in levels) {
      for (int i = 0; i < years.length && i < 4; i++) {
        final year = years[i];
        papers.add(_MockPaperData(
          level: level,
          year: year,
          title: '${year}年度 第${i + 1}回',
          questionCount: _questionCountForLevel(level),
          durationMinutes: _durationForLevel(level),
          difficulty: _difficultyForYear(year),
        ));
      }
    }

    return papers;
  }

  int _questionCountForLevel(String level) {
    switch (level) {
      case 'N5':
        return 70;
      case 'N4':
        return 80;
      case 'N3':
        return 95;
      case 'N2':
        return 105;
      case 'N1':
        return 120;
      default:
        return 80;
    }
  }

  int _durationForLevel(String level) {
    switch (level) {
      case 'N5':
        return 105;
      case 'N4':
        return 125;
      case 'N3':
        return 140;
      case 'N2':
        return 155;
      case 'N1':
        return 170;
      default:
        return 120;
    }
  }

  int _difficultyForYear(int year) {
    if (year >= 2023) return 4;
    if (year >= 2021) return 3;
    return 2;
  }
}

class _MockPaperData {
  final String level;
  final int year;
  final String title;
  final int questionCount;
  final int durationMinutes;
  final int difficulty;

  const _MockPaperData({
    required this.level,
    required this.year,
    required this.title,
    required this.questionCount,
    required this.durationMinutes,
    required this.difficulty,
  });
}
