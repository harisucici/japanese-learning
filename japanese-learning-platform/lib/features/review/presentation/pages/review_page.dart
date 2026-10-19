/// 复习页面
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

/// 复习页面
class ReviewPage extends StatelessWidget {
  const ReviewPage({super.key});

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
            height: 360,
            primaryColor: AppColors.sumire,
            illustration: SakuraBranchIllustration(
              width: 220,
              height: 140,
              color: const Color(0xFFE8A0BF),
            ),
            overlayText: '復習',
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
                  '复习',
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
                  '回顾过去的学习记录，巩固知识',
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

          // 复习统计 - 三列数据展示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Row(
              children: [
                _buildStatColumn('待复习', '12', AppColors.shu),
                Container(width: 0.5, height: 60, color: AppColors.washiBorder),
                Expanded(child: _buildStatColumn('连续天数', '7', AppColors.kincha)),
                Container(width: 0.5, height: 60, color: AppColors.washiBorder),
                Expanded(child: _buildStatColumn('总复习', '156', AppColors.primary)),
              ],
            ),
          ),

          const SizedBox(height: 100),

          // 待复习列表
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '待复习',
                  style: TextStyle(
                    fontFamily: AppTypography.serifFontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.sumiLighter,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 40),
                _buildReviewItem('N5 词汇', 5, AppColors.primary),
                _buildReviewItem('N5 语法', 3, AppColors.primary),
                _buildReviewItem('N4 词汇', 4, AppColors.shu),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: AppTypography.serifFontFamily,
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.sumiLighter,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, int count, Color color) {
    return GestureDetector(
      onTap: () {
        // TODO: 导航到复习详情
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
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
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
              '$count 题',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: AppColors.sumiLighter,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.sumiLighter.withOpacity(0.5),
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
