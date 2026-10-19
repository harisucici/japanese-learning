/// 题库首页 - 等级选择、试卷列表、筛选器
///
/// 响应式布局：
/// - 移动端（<600px）：单列布局
/// - 平板（600-1024px）：双列布局
/// - 桌面（>1024px）：多列布局
library;

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/layout/responsive_layout.dart';
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
    // Load questions when page initializes
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
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final layoutType = Breakpoints.getLayoutType(width);

                // 根据布局类型确定列数
                int crossAxisCount;
                switch (layoutType) {
                  case LayoutType.mobile:
                    crossAxisCount = 1;
                    break;
                  case LayoutType.tablet:
                    crossAxisCount = 2;
                    break;
                  case LayoutType.desktop:
                    crossAxisCount = width > 1400 ? 3 : 2;
                    break;
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 顶部标题
                    SliverToBoxAdapter(child: _buildHeader()),
                    // 等级选择 - 使用 Padding 约束宽度避免 overflow
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      sliver: SliverToBoxAdapter(
                        child: LevelSelector(
                          selected: _selectedLevel,
                          onSelected: _onLevelSelected,
                        ),
                      ),
                    ),
                    // 分类筛选
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      sliver: SliverToBoxAdapter(
                        child: CategoryFilter(
                          selected: _selectedType,
                          onSelected: _onTypeSelected,
                        ),
                      ),
                    ),
                    // 试卷/题目列表 - 响应式网格
                    SliverToBoxAdapter(child: _buildSectionTitle(questions)),
                    if (isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (error != null)
                      SliverFillRemaining(
                        child: Center(child: Text('加载失败: $error')),
                      )
                    else
                      SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: _calculateAspectRatio(width, crossAxisCount),
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => ExamCard(
                            question: questions[index],
                            onTap: () => _onExamTap(questions[index]),
                          ),
                          childCount: questions.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// 计算卡片宽高比
  double _calculateAspectRatio(double width, int crossAxisCount) {
    // 基础宽度减去 padding
    final availableWidth = width - 40; // 左右各 20px padding
    final cardWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
    // 卡片高度根据内容动态调整，但保持合理的宽高比
    return cardWidth / 180; // 假设卡片高度约 180px
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '题库练习',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '选择等级，开始刷题',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.search_rounded, color: AppColors.textPrimary, size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(List<Question> questions) {
    final count = questions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Text(
            '可用试卷',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _onExamTap(Question question) {
    // 点击进入该等级的答题页
    context.push('/quiz/${_selectedLevel.name}');
  }
}
