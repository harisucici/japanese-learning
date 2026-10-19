/// 练习页面
///
/// 星野京都风格 × Material Design 3
/// 全幅沉浸式布局 + 极端留白 + 轻盈字体
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_illustrations.dart';
import '../../../../shared/widgets/app_scaffold.dart';

/// 练习类型
enum PracticeType {
  vocabulary('词汇', '語彙', Icons.translate_rounded),
  grammar('语法', '文法', Icons.rule_rounded),
  reading('阅读', '読解', Icons.menu_book_rounded),
  listening('听力', '聴解', Icons.headphones_rounded);

  final String name;
  final String japaneseName;
  final IconData icon;

  const PracticeType(this.name, this.japaneseName, this.icon);
}

/// 练习页面
class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: AppColors.washi,
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 全幅 Hero 区域
          HeroImageArea(
            height: 380,
            primaryColor: AppColors.primary,
            illustration: SakuraBranchIllustration(
              width: 240,
              height: 160,
              color: const Color(0xFFFFB7C5),
            ),
            overlayText: '学習の道',
          ),

          // 标题区域
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
                  '练习',
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
                  '选择题型，开始专项训练',
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

          // 题型分类 - 编辑式布局
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '题型',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                ...PracticeType.values.map((type) => _buildPracticeTypeItem(type)),
              ],
            ),
          ),

          const SizedBox(height: 80),

          // 推荐练习
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '推荐练习',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                _buildRecommendedPractice(context, 0),
                _buildRecommendedPractice(context, 1),
                _buildRecommendedPractice(context, 2),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPracticeTypeItem(PracticeType type) {
    return GestureDetector(
      onTap: () {
        // TODO: 导航到对应练习页面
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 0),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Icon(
                type.icon,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.name,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.sumi,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    type.japaneseName,
                    style: TextStyle(
                      fontFamily: AppTypography.serifFontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.sumiLighter,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.sumiLighter.withOpacity(0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedPractice(BuildContext context, int index) {
    final titles = ['N3 词汇精选', 'N2 语法突破', 'N4 阅读理解'];
    final counts = [50, 30, 25];
    final colors = [AppColors.primary, AppColors.shu, AppColors.kincha];

    return GestureDetector(
      onTap: () {
        // TODO: 导航到练习详情
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
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
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors[index],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                titles[index],
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.sumi,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              '${counts[index]} 题',
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
    );
  }
}
