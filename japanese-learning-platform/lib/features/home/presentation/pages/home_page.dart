/// 题库首页 - 等级选择、试卷列表、筛选器
///
/// 响应式布局：
/// - Mobile（< 768px）：单列垂直布局，大触控区域，简化导航
/// - Web（>= 768px）：多列网格布局，紧凑信息展示，侧边栏导航
///
/// 深青色配色方案：
/// - 主色：#268785
/// - 背景：深青色
/// - 文字：白色
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/layout/responsive_layout.dart';
import '../../../../core/widgets/animations.dart';
import '../../../../shared/models/models.dart';
import '../../../../redux/redux.dart';
import '../widgets/level_selector.dart';
import '../widgets/category_filter.dart';
import '../widgets/exam_card.dart';

/// 题库首页
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  JLPTLevel _selectedLevel = JLPTLevel.n5;
  QuestionType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = StoreProvider.of<AppState>(context, listen: false);
      store.dispatch(loadQuestionsByLevel(_selectedLevel));
    });
  }

  void _onLevelSelected(JLPTLevel level) {
    setState(() => _selectedLevel = level);
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(SelectedLevelChanged(level));
    store.dispatch(loadQuestionsByLevel(level));
  }

  void _onTypeSelected(QuestionType? type) {
    setState(() => _selectedType = type);
    final store = StoreProvider.of<AppState>(context, listen: false);
    store.dispatch(SelectedTypeChanged(type));
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, QuestionsState>(
      converter: (store) => store.state.questions,
      builder: (context, questionsState) {
        final questions = questionsState.filteredQuestions;
        final isLoading = questionsState.loading;
        final error = questionsState.error;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWeb = Breakpoints.isWeb(width);

                // 根据屏幕宽度选择不同的布局
                if (isWeb) {
                  return _buildWebLayout(
                    width: width,
                    questions: questions,
                    isLoading: isLoading,
                    error: error,
                  );
                } else {
                  return _buildMobileLayout(
                    width: width,
                    questions: questions,
                    isLoading: isLoading,
                    error: error,
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  /// ============================================================
  /// Web 布局 (>= 768px)
  /// 侧边栏 + 主内容区，多列网格
  /// ============================================================
  Widget _buildWebLayout({
    required double width,
    required List<Question> questions,
    required bool isLoading,
    required String? error,
  }) {
    // Web 布局：侧边栏 (280px) + 主内容区
    final sidebarWidth = 280.0;
    final contentWidth = width - sidebarWidth;

    // 根据内容宽度决定列数
    int crossAxisCount;
    if (contentWidth > 1200) {
      crossAxisCount = 3;
    } else if (contentWidth > 800) {
      crossAxisCount = 2;
    } else {
      crossAxisCount = 2;
    }

    return Row(
      children: [
        // 侧边栏
        SizedBox(
          width: sidebarWidth,
          child: _buildWebSidebar(),
        ),
        // 主内容区
        Expanded(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 顶部标题
              SliverToBoxAdapter(child: _buildWebHeader()),
              // 等级选择
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                sliver: SliverToBoxAdapter(
                  child: LevelSelector(
                    selected: _selectedLevel,
                    onSelected: _onLevelSelected,
                  ),
                ),
              ),
              // 分类筛选
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                sliver: SliverToBoxAdapter(
                  child: CategoryFilter(
                    selected: _selectedType,
                    onSelected: _onTypeSelected,
                  ),
                ),
              ),
              // 试卷/题目列表标题
              SliverToBoxAdapter(child: _buildSectionTitle(questions)),
              // 内容区
              if (isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  ),
                )
              else if (error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      '加载失败: $error',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: AppSpacing.lg,
                      crossAxisSpacing: AppSpacing.lg,
                      childAspectRatio: _calculateAspectRatio(
                        contentWidth,
                        crossAxisCount,
                      ),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => StaggeredCardAnimation(
                        index: index,
                        totalItems: questions.length,
                        child: ExamCard(
                          question: questions[index],
                          onTap: () => _onExamTap(questions[index]),
                        ),
                      ),
                      childCount: questions.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xxxxl),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Web 侧边栏
  Widget _buildWebSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo 区域
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: AppColors.textOnPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Text(
                      '日语学习',
                      style: TextStyle(
                        fontFamily: AppTypography.fontFamily,
                        fontSize: AppTypography.headlineMedium,
                        fontWeight: AppTypography.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'JLPT 题库练习平台',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppTypography.bodySmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.divider),
          // 导航菜单
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              children: [
                _buildSidebarItem(
                  icon: Icons.home_rounded,
                  label: '题库首页',
                  isSelected: true,
                ),
                _buildSidebarItem(
                  icon: Icons.menu_book_rounded,
                  label: '单词本',
                  isSelected: false,
                ),
                _buildSidebarItem(
                  icon: Icons.bar_chart_rounded,
                  label: '学习统计',
                  isSelected: false,
                ),
                _buildSidebarItem(
                  icon: Icons.settings_rounded,
                  label: '设置',
                  isSelected: false,
                ),
              ],
            ),
          ),
          // 底部用户信息
          const Divider(color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary50,
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '学习者',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppTypography.bodyMedium,
                          fontWeight: AppTypography.medium,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'N5 等级',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: AppTypography.bodySmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 侧边栏导航项
  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: isSelected ? AppColors.primary50 : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.lg),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppTypography.bodyMedium,
                    fontWeight: isSelected
                        ? AppTypography.semiBold
                        : AppTypography.medium,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Web 布局顶部标题
  Widget _buildWebHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.xxl,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '题库练习',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppTypography.displayMedium,
                    fontWeight: AppTypography.bold,
                    color: AppColors.textPrimary,
                    height: AppTypography.lineHeightTight,
                    letterSpacing: AppTypography.letterSpacingTight,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '选择等级，开始刷题',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: AppTypography.bodyMedium,
                    color: AppColors.textSecondary,
                    letterSpacing: AppTypography.letterSpacingWide,
                    height: AppTypography.lineHeightNormal,
                  ),
                ),
              ],
            ),
          ),
          // 搜索按钮
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // 通知按钮
          SizedBox(
            width: 44,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.notifications_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================
  /// Mobile 布局 (< 768px)
  /// 单列垂直布局，大触控区域，简化导航
  /// ============================================================
  Widget _buildMobileLayout({
    required double width,
    required List<Question> questions,
    required bool isLoading,
    required String? error,
  }) {
    // Mobile 布局：单列
    const crossAxisCount = 1;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // 顶部标题 - 简化版
        SliverToBoxAdapter(child: _buildMobileHeader()),
        // 等级选择 - 更大触控区域
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: LevelSelector(
              selected: _selectedLevel,
              onSelected: _onLevelSelected,
            ),
          ),
        ),
        // 分类筛选 - 更大触控区域
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: CategoryFilter(
              selected: _selectedType,
              onSelected: _onTypeSelected,
            ),
          ),
        ),
        // 试卷/题目列表标题
        SliverToBoxAdapter(child: _buildSectionTitle(questions)),
        // 内容区
        if (isLoading)
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryLight,
              ),
            ),
          )
        else if (error != null)
          SliverFillRemaining(
            child: Center(
              child: Text(
                '加载失败: $error',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: AppSpacing.lg,
                crossAxisSpacing: AppSpacing.lg,
                childAspectRatio: 2.5, // Mobile 卡片更宽
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => StaggeredCardAnimation(
                  index: index,
                  totalItems: questions.length,
                  child: ExamCard(
                    question: questions[index],
                    onTap: () => _onExamTap(questions[index]),
                  ),
                ),
                childCount: questions.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: AppSpacing.xxxxl),
        ),
      ],
    );
  }

  /// Mobile 布局顶部标题
  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏：Logo + 操作按钮
          Row(
            children: [
              // Logo
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppColors.textOnPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                '日语学习',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppTypography.titleLarge,
                  fontWeight: AppTypography.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              // 搜索按钮
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                  onPressed: () {},
                ),
              ),
              // 菜单按钮
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          // 主标题
          Text(
            '题库练习',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.headlineLarge,
              fontWeight: AppTypography.bold,
              color: AppColors.textPrimary,
              height: AppTypography.lineHeightTight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '选择等级，开始刷题',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: AppTypography.bodySmall,
              color: AppColors.textSecondary,
              letterSpacing: AppTypography.letterSpacingWide,
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================
  /// 通用组件
  /// ============================================================

  double _calculateAspectRatio(double width, int crossAxisCount) {
    final availableWidth = width - AppSpacing.xxl * 2;
    final cardWidth =
        (availableWidth - (crossAxisCount - 1) * AppSpacing.lg) / crossAxisCount;
    return cardWidth / 180;
  }

  /// 构建区块标题
  Widget _buildSectionTitle(List<Question> questions) {
    final count = questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.xxxl,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '可用试卷',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppTypography.headlineMedium,
                  fontWeight: AppTypography.semiBold,
                  color: AppColors.textPrimary,
                  letterSpacing: AppTypography.letterSpacingTight,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '($count)',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: AppTypography.bodySmall,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(height: 1, color: AppColors.border),
        ],
      ),
    );
  }

  void _onExamTap(Question question) {
    context.push('/quiz/${_selectedLevel.name}');
  }
}
