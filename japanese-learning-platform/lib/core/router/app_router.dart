/// 应用路由配置
/// 
/// 使用 GoRouter 实现声明式路由
/// 核心路由结构：侧边栏/顶部导航（真题库/练习/复习/模拟考试/个人中心）+ 子路由
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/app_nav_bar.dart';
import '../../features/exam/presentation/pages/exam_config_page.dart';
import '../../features/practice/presentation/pages/practice_page.dart';
import '../../features/review/presentation/pages/review_page.dart';
import '../../features/exam/presentation/pages/mock_exam_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/quiz/presentation/pages/quiz_page.dart';
import '../../features/quiz/presentation/pages/quiz_answer_page.dart';
import '../../features/wrong_book/presentation/pages/wrong_book_page.dart';
import '../../features/statistics/presentation/pages/statistics_page.dart';
import '../../features/exam/presentation/pages/exam_page.dart';
import '../../features/exam/presentation/pages/exam_result_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/review/presentation/pages/review_session_page.dart';
import '../../shared/models/review_item.dart';
import '../../redux/app_state.dart';

/// 复习会话路由参数
class ReviewSessionRouteArgs {
  final List<ReviewItem> items;
  final ReviewMode mode;

  const ReviewSessionRouteArgs({
    required this.items,
    required this.mode,
  });
}

/// 应用路由
/// 
/// 统一管理所有路由路径和页面跳转逻辑
/// 
/// 路由结构：
/// ```
/// /              -> ShellRoute (底部导航)
///   /home        -> HomePage
///   /practice    -> PracticePage
///   /review      -> ReviewPage
///   /profile     -> ProfilePage
/// /quiz/:level   -> QuizPage（练习详情页，全屏）
/// ```
class AppRouter {
  AppRouter._();

  // ============================================================
  // 路由路径常量
  // ============================================================
  
  /// 根路径
  static const String root = '/';
  
  /// 首页路径
  static const String home = '/home';
  
  /// 练习路径
  static const String practice = '/practice';
  
  /// 复习路径
  static const String review = '/review';
  
  /// 个人中心路径
  static const String profile = '/profile';
  
  /// 练习详情页路径（带参数）
  static const String quizDetail = '/quiz/:level';

  /// 答题交互页路径（带参数）
  static const String quizAnswer = '/quiz/:level/answer';

  /// 登录页路径
  static const String login = '/login';

  /// 注册页路径
  static const String register = '/register';

  /// 复习会话页路径
  static const String reviewSession = '/review/session';

  // ============================================================
  // 导航键
  // ============================================================
  
  /// 根导航键
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  // ============================================================
  // GoRouter 配置
  // ============================================================
  
  /// 路由器实例
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: home,
    debugLogDiagnostics: false,
    
    // 路由表
    routes: [
      // Shell 路由 - 侧边栏/顶部导航容器（每个分支独立状态栈）
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppNavBar(navigationShell: navigationShell);
        },
        branches: [
          // 真题库
          StatefulShellBranch(routes: [
            GoRoute(
              path: home,
              name: 'home',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ExamConfigPage());
              },
            ),
          ]),
          // 练习
          StatefulShellBranch(routes: [
            GoRoute(
              path: practice,
              name: 'practice',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: PracticePage());
              },
            ),
          ]),
          // 复习
          StatefulShellBranch(routes: [
            GoRoute(
              path: review,
              name: 'review',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ReviewPage());
              },
            ),
          ]),
          // 模拟考试
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/mock-exam',
              name: 'mockExam',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: MockExamPage());
              },
            ),
          ]),
          // 个人中心
          StatefulShellBranch(routes: [
            GoRoute(
              path: profile,
              name: 'profile',
              pageBuilder: (context, state) {
                return const NoTransitionPage(child: ProfilePage());
              },
            ),
          ]),
        ],
      ),
      
      // 练习详情页（全屏，不在底部导航内）
      GoRoute(
        path: quizDetail,
        name: 'quiz',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final level = state.pathParameters['level'] ?? 'N5';
          return CustomTransitionPage(
            child: QuizPage(level: level),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // 从右侧滑入的过渡动画
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 答题交互页（全屏）
      GoRoute(
        path: quizAnswer,
        name: 'quizAnswer',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final level = state.pathParameters['level'] ?? 'N5';
          return CustomTransitionPage(
            child: QuizAnswerPage(level: level),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 错题本页面（全屏）
      GoRoute(
        path: '/wrong-book',
        name: 'wrongBook',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const WrongBookPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 学习统计页面（全屏）
      GoRoute(
        path: '/statistics',
        name: 'statistics',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const StatisticsPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 模拟考试配置页面
      GoRoute(
        path: '/exam/config',
        name: 'examConfig',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const ExamConfigPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 考试进行页面
      GoRoute(
        path: '/exam/take',
        name: 'exam',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const ExamPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 考试成绩页面
      GoRoute(
        path: '/exam/result',
        name: 'examResult',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const ExamResultPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),

      // 登录页面（淡入淡出过渡）
      GoRoute(
        path: login,
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const LoginPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),

      // 注册页面（淡入淡出过渡）
      GoRoute(
        path: register,
        name: 'register',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            child: const RegisterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),

      // 复习会话页面（滑动过渡）
      GoRoute(
        path: reviewSession,
        name: 'reviewSession',
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final args = extra is ReviewSessionRouteArgs
              ? extra
              : const ReviewSessionRouteArgs(items: [], mode: ReviewMode.originalOnly);
          return CustomTransitionPage(
            child: ReviewSessionPage(items: args.items, mode: args.mode),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
                )),
                child: child,
              );
            },
          );
        },
      ),
    ],
    
    // 错误处理
    errorBuilder: (context, state) {
      return const ErrorPage();
    },
    
    // 重定向逻辑
    redirect: (context, state) {
      // 根路径重定向到首页
      if (state.matchedLocation == root) {
        return home;
      }
      return null;
    },
  );

  // ============================================================
  // 导航辅助方法
  // ============================================================
  
  /// 导航到练习详情
  /// 
  /// [level] JLPT 等级（N5-N1）
  static void goToQuiz(BuildContext context, String level) {
    context.push('/quiz/$level');
  }

  /// 导航到答题交互页
  static void goToQuizAnswer(BuildContext context, String level) {
    context.push('/quiz/$level/answer');
  }

  /// 导航到错题本
  static void goToWrongBook(BuildContext context) {
    context.push('/wrong-book');
  }

  /// 导航到学习统计
  static void goToStatistics(BuildContext context) {
    context.push('/statistics');
  }

  /// 返回首页
  static void goHome(BuildContext context) {
    context.go(home);
  }

  /// 返回上一页
  static void goBack(BuildContext context) {
    context.pop();
  }
}

/// 错误页面
/// 
/// 路由匹配失败时显示
class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('页面未找到')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '请求的页面不存在',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '请检查链接是否正确',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => AppRouter.goHome(context),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}
