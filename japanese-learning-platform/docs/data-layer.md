# 数据模型层 - 账号系统与本地存储

## 概述

本模块实现了完整的账号系统、数据模型、本地存储服务（Hive）和网络服务接口（Dio），为日语 N5-N1 刷题平台提供底层数据支撑。

## 核心模型

### 1. User（用户）
```dart
User(
  id: String,              // UUID
  email: String,           // 登录邮箱
  name: String,            // 用户名
  currentLevel: JLPTLevel, // 当前等级 N5-N1
  targetLevel: JLPTLevel,  // 目标等级
  createdAt: DateTime,     // 注册时间
  avatarUrl: String?,      // 头像
  streakDays: int,         // 连续学习天数
  totalQuestions: int,     // 总刷题数
  accuracy: double,        // 正确率 0.0-1.0
)
```

### 2. Question（题目）
```dart
Question(
  id: String,                    // UUID
  level: JLPTLevel,              // 等级
  type: QuestionType,            // 七种题型
  content: String,               // 题干
  options: List<QuestionOption>, // 选项列表
  answer: String,                // 正确答案的 optionId（非 A/B/C/D）
  source: QuestionSource,        // 来源
  explanationId: String,         // 关联解析 ID
  tags: List<String>,            // 标签
  difficulty: double,            // 难度 0.0-1.0
)
```

### 3. Explanation（解析）
```dart
Explanation(
  id: String,                      // 解析 ID
  questionId: String,              // 关联题目 ID
  translation: String,             // 整体翻译
  wordAnalysis: List<WordInfo>,    // 逐词拆解
  sentenceStructure: String,       // 句子结构
  grammar: List<GrammarPoint>,     // 语法点对比
  optionAnalysis: List<OptionAnalysis>, // 选项分析
  extensions: List<ExtensionExercise>,  // 引申练习
)
```

### 4. ExamRecord（考试记录）
```dart
ExamRecord(
  id: String,
  userId: String,
  level: JLPTLevel,
  recordType: ExamRecordType,    // practice / exam / review
  questionIds: List<String>,     // 题目列表
  answers: List<AnswerRecord>,   // 每题作答
  score: int,                    // 得分
  totalQuestions: int,
  correctCount: int,
  durationMs: int,               // 用时（毫秒）
  completedAt: DateTime,
)
```

### 5. ReviewItem（复习项）
```dart
ReviewItem(
  id: String,
  userId: String,
  questionId: String,
  level: JLPTLevel,
  type: QuestionType,
  status: ReviewStatus,          // new / learning / reviewing / mastered
  reviewCount: int,              // 复习次数
  nextReviewAt: DateTime?,       // 下次复习时间（SM-2 算法）
  easeFactor: double,            // 难度系数
  intervalDays: int,             // 间隔天数
  isFavorite: bool,              // 是否收藏
  isWrongAnswer: bool,           // 是否答错
  wrongCount: int,               // 答错次数
  correctStreak: int,            // 连续答对
)
```

## 枚举定义

### JLPTLevel（等级）
- `n5`, `n4`, `n3`, `n2`, `n1`
- 提供 `displayName`（N5/N4/...）和 `numericValue`（用于排序）

### QuestionType（七种题型）
- `vocabulary`（文字・語彙）
- `kanji`（漢字）
- `grammar`（文法）
- `reading`（読解）
- `listening`（聴解）
- `fillInBlank`（文脈規定）
- `comprehensive`（総合）

### QuestionSource（来源）
- `official`（真题）
- `mock`（模拟题）
- `textbook`（教材题）
- `userGenerated`（用户生成）
- `aiGenerated`（AI 生成）
- `pastExam`（历年真题）
- `custom`（自定义）

## 本地存储服务（Hive）

**文件**: `lib/core/storage/local_storage_service.dart`

### 特性
- 基于 Hive 的键值存储
- 每个模型类型独立 Box
- JSON 序列化/反序列化
- 支持批量写入
- 提供用户、题目、解析、考试记录、复习项的专用方法

### 核心方法
```dart
// 初始化
Future<void> init()

// 通用读写
Future<void> put<T>(String boxName, String key, T value)
Future<Map<String, dynamic>?> get(String boxName, String key)
Future<void> delete(String boxName, String key)
Future<List<Map<String, dynamic>>> getAll(String boxName)

// 用户相关
Future<void> saveUser(Map<String, dynamic> userJson)
Future<Map<String, dynamic>?> getUser(String userId)
Future<void> setCurrentUser(String userId)
Future<String?> getCurrentUserId()
Future<void> setAuthToken(String? token)
Future<String?> getAuthToken()

// 题目相关
Future<void> saveQuestion(Map<String, dynamic> q)
Future<void> saveQuestions(List<Map<String, dynamic>> questions)
Future<Map<String, dynamic>?> getQuestion(String id)
Future<List<Map<String, dynamic>>> getQuestionsByLevel(String level)
Future<List<Map<String, dynamic>>> getQuestionsByType(String type)

// 解析相关
Future<void> saveExplanation(Map<String, dynamic> e)
Future<Map<String, dynamic>?> getExplanation(String id)
Future<Map<String, dynamic>?> getExplanationByQuestion(String questionId)

// 考试记录
Future<void> saveExamRecord(Map<String, dynamic> r)
Future<List<Map<String, dynamic>>> getExamRecordsByUser(String userId)

// 复习项
Future<void> saveReviewItem(Map<String, dynamic> r)
Future<List<Map<String, dynamic>>> getReviewItemsByUser(String userId)
Future<List<Map<String, dynamic>>> getDueReviewItems(String userId)
```

## 网络服务（Dio）

**文件**: 
- `lib/core/network/api_service.dart`（抽象接口）
- `lib/core/network/dio_api_service.dart`（Dio 实现）

### 特性
- 抽象接口设计，便于切换实现
- 自动 Token 注入
- 请求/响应拦截器
- 统一错误处理
- 超时配置（30s）

### API 端点常量
```dart
class ApiEndpoints {
  // 认证
  static const String login = '/api/v1/auth/login';
  static const String register = '/api/v1/auth/register';
  static const String logout = '/api/v1/auth/logout';
  static const String me = '/api/v1/auth/me';
  
  // 题目
  static const String questions = '/api/v1/questions';
  static const String questionById = '$questions/:id';
  static const String questionsByLevel = '$questions/level/:level';
  
  // 解析
  static const String explanations = '/api/v1/explanations';
  static const String explanationByQuestion = '$explanations/question/:id';
  
  // 记录
  static const String records = '/api/v1/records';
  
  // 复习
  static const String review = '/api/v1/review';
  static const String reviewItems = '$review/items';
  static const String reviewDue = '$review/due';
}
```

## Riverpod Providers

### 核心 Providers
```dart
// 本地存储（单例）
final localStorageServiceProvider

// 初始化服务（启动时调用）
final initServiceProvider

// 网络服务
final apiServiceProvider

// 账号状态
final authProvider
final currentUserProvider
final isSignedInProvider
```

### 题库 Providers
```dart
// 题目仓库
final questionRepositoryProvider

// 筛选器
final selectedLevelProvider
final selectedTypeProvider

// 数据加载
final questionsByLevelProvider        // FutureProvider
final questionByIdProvider            // FutureProvider.family
final explanationByQuestionProvider   // FutureProvider.family
```

### 复习 Providers
```dart
// 复习仓库
final reviewRepositoryProvider

// 复习列表
final reviewItemsProvider             // FutureProvider
final dueReviewItemsProvider          // FutureProvider
```

### 考试记录 Providers
```dart
// 考试记录仓库
final examRecordRepositoryProvider

// 历史记录
final myExamRecordsProvider           // FutureProvider
```

## 账号系统

**文件**: `lib/features/auth/auth_provider.dart`

### AuthNotifier
管理登录状态和用户信息，提供：

```dart
// 恢复会话（启动时）
Future<void> restoreSession()

// 登录（本地 + 云端）
Future<bool> signIn({required String email, required String password})

// 注册
Future<bool> signUp({
  required String email,
  required String password,
  required String name,
  JLPTLevel targetLevel = JLPTLevel.n5,
})

// 登出
Future<void> signOut()

// 更新用户信息
Future<void> updateUser(User updated)

// 更新等级
Future<void> updateLevel(JLPTLevel current, JLPTLevel target)
```

### AuthState
```dart
AuthState(
  status: AuthStatus,   // unknown / signedOut / signedIn / loading / error
  user: User?,
  errorMessage: String?,
)
```

## 使用示例

### 1. 初始化（main.dart）
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 初始化本地存储
    ref.watch(initServiceProvider);
    
    // 恢复会话
    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.unknown) {
      ref.read(authProvider.notifier).restoreSession();
    }
    
    return MaterialApp(home: AuthGate());
  }
}
```

### 2. 加载题目
```dart
// 在 Widget 中
final questionsAsync = ref.watch(questionsByLevelProvider);

questionsAsync.when(
  data: (questions) => ListView.builder(
    itemCount: questions.length,
    itemBuilder: (context, index) {
      final q = questions[index];
      return QuestionCard(question: q);
    },
  ),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

### 3. 保存考试记录
```dart
final repo = ref.read(examRecordRepositoryProvider);
final record = await repo.saveRecord(
  userId: user.id,
  level: JLPTLevel.n5,
  recordType: ExamRecordType.practice,
  questions: selectedQuestions,
  answers: {'q1': 'opt1', 'q2': 'opt2'},
  durationMs: 120000,
);
```

### 4. 添加复习项（错题收录）
```dart
final repo = ref.read(reviewRepositoryProvider);
await repo.addReviewItem(
  userId: user.id,
  questionId: question.id,
  level: question.level,
  type: question.type,
  isWrong: true,  // 错题
);
```

### 5. 间隔复习
```dart
// 获取到期复习项
final dueItems = ref.watch(dueReviewItemsProvider);

// 标记复习结果
final repo = ref.read(reviewRepositoryProvider);
await repo.markReviewed(itemId: item.id, correct: true);
```

## 设计决策

1. **答案用 optionId 引用**：避免 A/B/C/D 硬编码，支持动态选项顺序
2. **解析与题目分离**：便于独立加载、缓存、离线使用
3. **本地优先策略**：先读 Hive，无数据时从 API 拉取并缓存
4. **SM-2 算法简化**：用于间隔复习的时间计算
5. **Riverpod 状态管理**：响应式、可测试、依赖注入
6. **Dio 抽象接口**：便于切换 mock/测试实现

## 下一步

- [ ] 实现真实登录页面 UI
- [ ] 实现首页 UI
- [ ] 实现题目列表筛选界面
- [ ] 实现答题交互流程
- [ ] 实现解析详情页
- [ ] 实现错题本界面
- [ ] 对接真实后端 API
- [ ] 添加单元测试

## 文件清单

```
lib/
├── main.dart                                    # 应用入口
├── core/
│   ├── providers/
│   │   └── core_providers.dart                  # 核心 Providers
│   ├── storage/
│   │   └── local_storage_service.dart           # Hive 本地存储
│   └── network/
│       ├── api_service.dart                     # 网络接口
│       └── dio_api_service.dart                 # Dio 实现
├── features/
│   └── auth/
│       └── auth_provider.dart                   # 账号 Provider
└── shared/
    ├── models/
    │   ├── models.dart                          # 统一导出
    │   ├── enums.dart                           # 枚举定义
    │   ├── user.dart                            # User 模型
    │   ├── question.dart                        # Question 模型
    │   ├── explanation.dart                     # Explanation 模型
    │   ├── exam_record.dart                     # ExamRecord 模型
    │   └── review_item.dart                     # ReviewItem 模型
    └── providers/
        ├── providers.dart                       # 统一导出
        ├── question_provider.dart               # 题库 Providers
        ├── review_provider.dart                 # 复习 Providers
        └── exam_record_provider.dart            # 考试记录 Providers
```
