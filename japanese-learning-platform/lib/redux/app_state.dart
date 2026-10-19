/// Redux AppState - 全局应用状态
///
/// 聚合所有功能模块的状态到单一 AppState
library;

import 'package:flutter/material.dart';

import '../shared/models/models.dart';
import '../core/audio/audio.dart';
import '../core/storage/local_storage_service.dart';
import '../core/network/api_service.dart';

// ========== Auth State ==========

/// 账号状态
enum AuthStatus {
  unknown,
  signedOut,
  signedIn,
  loading,
  error,
}

/// 认证子状态
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorMessage,
  });

  bool get isSignedIn => status == AuthStatus.signedIn && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

// ========== Audio Player State ==========

/// 播放器 UI 使用的聚合状态
class AudioPlayerState {
  final AudioPlaybackState playbackState;
  final Duration position;
  final Duration duration;
  final int currentIndex;
  final AudioItem? currentItem;
  final List<AudioItem> playlist;
  final double speed;
  final AudioLoopMode loopMode;
  final String? error;

  const AudioPlayerState({
    this.playbackState = AudioPlaybackState.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.currentIndex = -1,
    this.currentItem,
    this.playlist = const [],
    this.speed = 1.0,
    this.loopMode = AudioLoopMode.none,
    this.error,
  });

  bool get isPlaying => playbackState == AudioPlaybackState.playing;
  bool get isLoading => playbackState == AudioPlaybackState.loading;
  bool get isPaused => playbackState == AudioPlaybackState.paused;
  bool get isIdle => playbackState == AudioPlaybackState.idle;
  bool get hasError => playbackState == AudioPlaybackState.error;
  bool get isSlowSpeed => speed < 1.0 - 0.01;
  bool get isCompleted => playbackState == AudioPlaybackState.completed;

  double get progress {
    if (duration == Duration.zero) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }

  AudioPlayerState copyWith({
    AudioPlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    int? currentIndex,
    AudioItem? currentItem,
    bool clearCurrentItem = false,
    List<AudioItem>? playlist,
    double? speed,
    AudioLoopMode? loopMode,
    String? error,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentIndex: currentIndex ?? this.currentIndex,
      currentItem: clearCurrentItem ? null : (currentItem ?? this.currentItem),
      playlist: playlist ?? this.playlist,
      speed: speed ?? this.speed,
      loopMode: loopMode ?? this.loopMode,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== Questions State ==========

/// 题目子状态
class QuestionsState {
  final JLPTLevel selectedLevel;
  final QuestionType? selectedType;
  final List<Question> questions;
  final bool loading;
  final String? error;
  final Map<String, Question> questionsById;
  final Map<String, Explanation> explanationsById;
  final bool explanationsLoading;

  const QuestionsState({
    this.selectedLevel = JLPTLevel.n5,
    this.selectedType,
    this.questions = const [],
    this.loading = false,
    this.error,
    this.questionsById = const {},
    this.explanationsById = const {},
    this.explanationsLoading = false,
  });

  /// 根据筛选条件过滤后的题目
  List<Question> get filteredQuestions {
    if (selectedType == null) return questions;
    return questions.where((q) => q.type == selectedType).toList();
  }

  QuestionsState copyWith({
    JLPTLevel? selectedLevel,
    QuestionType? selectedType,
    bool clearSelectedType = false,
    List<Question>? questions,
    bool? loading,
    String? error,
    bool clearError = false,
    Map<String, Question>? questionsById,
    Map<String, Explanation>? explanationsById,
    bool? explanationsLoading,
  }) {
    return QuestionsState(
      selectedLevel: selectedLevel ?? this.selectedLevel,
      selectedType: clearSelectedType ? null : (selectedType ?? this.selectedType),
      questions: questions ?? this.questions,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      questionsById: questionsById ?? this.questionsById,
      explanationsById: explanationsById ?? this.explanationsById,
      explanationsLoading: explanationsLoading ?? this.explanationsLoading,
    );
  }
}

// ========== Review State ==========

/// 复习子状态
class ReviewState {
  final List<ReviewItem> reviewItems;
  final List<ReviewItem> dueItems;
  final bool loading;
  final String? error;

  const ReviewState({
    this.reviewItems = const [],
    this.dueItems = const [],
    this.loading = false,
    this.error,
  });

  ReviewState copyWith({
    List<ReviewItem>? reviewItems,
    List<ReviewItem>? dueItems,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ReviewState(
      reviewItems: reviewItems ?? this.reviewItems,
      dueItems: dueItems ?? this.dueItems,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== Exam Record State ==========

/// 考试记录子状态
class ExamRecordState {
  final List<ExamRecord> records;
  final bool loading;
  final String? error;

  const ExamRecordState({
    this.records = const [],
    this.loading = false,
    this.error,
  });

  ExamRecordState copyWith({
    List<ExamRecord>? records,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return ExamRecordState(
      records: records ?? this.records,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== Statistics State ==========

/// 各 JLPT 等级的学习进度
class LevelProgress {
  final JLPTLevel level;
  final int totalQuestions;
  final int correctCount;
  final int totalAttempts;

  const LevelProgress({
    required this.level,
    required this.totalQuestions,
    required this.correctCount,
    required this.totalAttempts,
  });

  double get accuracy =>
      totalAttempts == 0 ? 0.0 : correctCount / totalAttempts;
}

/// 各题型的掌握情况
class TypeMastery {
  final QuestionType type;
  final int totalQuestions;
  final int correctCount;
  final int masteredCount;

  const TypeMastery({
    required this.type,
    required this.totalQuestions,
    required this.correctCount,
    required this.masteredCount,
  });

  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;
}

/// 学习统计快照
class LearningStatistics {
  final int totalAnswers;
  final int totalCorrect;
  final int totalSessions;
  final int totalReviews;
  final int streakDays;
  final int totalDurationMs;
  final int wrongAnswerCount;
  final int dueReviewCount;
  final int favoriteCount;
  final List<LevelProgress> levelProgress;
  final List<TypeMastery> typeMastery;

  const LearningStatistics({
    required this.totalAnswers,
    required this.totalCorrect,
    required this.totalSessions,
    required this.totalReviews,
    required this.streakDays,
    required this.totalDurationMs,
    required this.wrongAnswerCount,
    required this.dueReviewCount,
    required this.favoriteCount,
    required this.levelProgress,
    required this.typeMastery,
  });

  double get overallAccuracy =>
      totalAnswers == 0 ? 0.0 : totalCorrect / totalAnswers;

  static const empty = LearningStatistics(
    totalAnswers: 0,
    totalCorrect: 0,
    totalSessions: 0,
    totalReviews: 0,
    streakDays: 0,
    totalDurationMs: 0,
    wrongAnswerCount: 0,
    dueReviewCount: 0,
    favoriteCount: 0,
    levelProgress: [],
    typeMastery: [],
  );
}

/// 统计子状态
class StatisticsState {
  final LearningStatistics? statistics;
  final bool loading;
  final String? error;

  const StatisticsState({
    this.statistics,
    this.loading = false,
    this.error,
  });

  StatisticsState copyWith({
    LearningStatistics? statistics,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return StatisticsState(
      statistics: statistics ?? this.statistics,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== Wrong Book State ==========

/// 错题本排序方式
enum WrongBookSort {
  wrongCountDesc,
  wrongCountAsc,
  recentFirst,
  byLevel;

  String get displayName {
    switch (this) {
      case WrongBookSort.wrongCountDesc:
        return '错误次数 ↓';
      case WrongBookSort.wrongCountAsc:
        return '错误次数 ↑';
      case WrongBookSort.recentFirst:
        return '最近错误';
      case WrongBookSort.byLevel:
        return '按等级';
    }
  }
}

/// 错题本子状态
class WrongBookState {
  final JLPTLevel? levelFilter;
  final QuestionType? typeFilter;
  final WrongBookSort sortBy;
  final List<ReviewItem> filteredItems;
  final bool loading;
  final String? error;

  const WrongBookState({
    this.levelFilter,
    this.typeFilter,
    this.sortBy = WrongBookSort.wrongCountDesc,
    this.filteredItems = const [],
    this.loading = false,
    this.error,
  });

  WrongBookState copyWith({
    JLPTLevel? levelFilter,
    QuestionType? typeFilter,
    bool clearLevel = false,
    bool clearType = false,
    WrongBookSort? sortBy,
    List<ReviewItem>? filteredItems,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return WrongBookState(
      levelFilter: clearLevel ? null : (levelFilter ?? this.levelFilter),
      typeFilter: clearType ? null : (typeFilter ?? this.typeFilter),
      sortBy: sortBy ?? this.sortBy,
      filteredItems: filteredItems ?? this.filteredItems,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ========== Review Session State ==========

/// 复习模式
enum ReviewMode {
  originalOnly,
  similarQuestions,
  mixed;

  String get displayName {
    switch (this) {
      case ReviewMode.originalOnly:
        return '原题重做';
      case ReviewMode.similarQuestions:
        return '相似题练习';
      case ReviewMode.mixed:
        return '混合模式';
    }
  }
}

/// 复习会话状态
class ReviewSession {
  final String id;
  final List<ReviewItem> items;
  final ReviewMode mode;
  final int currentIndex;
  final Map<String, bool> results;

  const ReviewSession({
    required this.id,
    required this.items,
    required this.mode,
    this.currentIndex = 0,
    this.results = const {},
  });

  int get total => items.length;
  int get completed => results.length;
  bool get isFinished => completed >= total;
  ReviewItem? get currentItem =>
      currentIndex < items.length ? items[currentIndex] : null;
  int get correctCount => results.values.where((c) => c).length;
  double get accuracy => total == 0 ? 0.0 : correctCount / total;

  ReviewSession copyWith({
    List<ReviewItem>? items,
    ReviewMode? mode,
    int? currentIndex,
    Map<String, bool>? results,
  }) {
    return ReviewSession(
      id: id,
      items: items ?? this.items,
      mode: mode ?? this.mode,
      currentIndex: currentIndex ?? this.currentIndex,
      results: results ?? this.results,
    );
  }
}

/// 复习会话子状态
class ReviewSessionState {
  final ReviewSession? session;

  const ReviewSessionState({this.session});

  ReviewSessionState copyWith({ReviewSession? session}) {
    return ReviewSessionState(session: session ?? this.session);
  }
}

// ========== Quiz Session State ==========

/// 答题状态
enum QuizStatus {
  inProgress,
  submitted,
}

/// 答题会话模型
class QuizSession {
  final String id;
  final JLPTLevel level;
  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final QuizStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, bool> submittedAnswers;

  const QuizSession({
    required this.id,
    required this.level,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.submittedAnswers,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  bool isCorrect(String questionId) {
    final question = questions.firstWhere((q) => q.id == questionId);
    final userAnswer = answers[questionId];
    if (userAnswer == null) return false;
    return question.isCorrect(userAnswer);
  }

  int get correctCount {
    int count = 0;
    for (final q in questions) {
      final userAnswer = answers[q.id];
      if (userAnswer != null && q.isCorrect(userAnswer)) {
        count++;
      }
    }
    return count;
  }

  double get accuracy =>
      questions.isEmpty ? 0 : correctCount / questions.length;

  int get durationInSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds;
  }

  QuizSession copyWith({
    int? currentIndex,
    Map<String, String>? answers,
    QuizStatus? status,
    DateTime? endTime,
    Map<String, bool>? submittedAnswers,
  }) {
    return QuizSession(
      id: id,
      level: level,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      submittedAnswers: submittedAnswers ?? this.submittedAnswers,
    );
  }
}

/// 答题会话子状态
class QuizSessionState {
  final QuizSession? session;

  const QuizSessionState({this.session});

  QuizSessionState copyWith({QuizSession? session}) {
    return QuizSessionState(session: session ?? this.session);
  }
}

// ========== Exam Session State ==========

/// 考试状态
enum ExamStatus {
  notStarted,
  inProgress,
  paused,
  submitted,
}

/// 考试模式
enum ExamMode {
  simulation,
  custom,
}

/// 考试会话模型
class ExamSession {
  final String id;
  final JLPTLevel level;
  final String paperName;
  final ExamMode mode;
  final List<Question> questions;
  final int currentIndex;
  final Map<String, String> answers;
  final Set<String> markedQuestions;
  final ExamStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int remainingSeconds;
  final int totalSeconds;
  final int pausedSeconds;

  const ExamSession({
    required this.id,
    required this.level,
    required this.paperName,
    required this.mode,
    required this.questions,
    required this.currentIndex,
    required this.answers,
    required this.markedQuestions,
    required this.status,
    required this.startTime,
    this.endTime,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.pausedSeconds = 0,
  });

  Question? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get answeredCount => answers.length;
  int get unansweredCount => questions.length - answers.length;

  int get correctCount {
    int count = 0;
    for (final q in questions) {
      final userAnswer = answers[q.id];
      if (userAnswer != null && q.isCorrect(userAnswer)) {
        count++;
      }
    }
    return count;
  }

  double get accuracy =>
      questions.isEmpty ? 0 : correctCount / questions.length;

  int get durationInSeconds {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inSeconds - pausedSeconds;
  }

  ExamSession copyWith({
    int? currentIndex,
    Map<String, String>? answers,
    Set<String>? markedQuestions,
    ExamStatus? status,
    DateTime? endTime,
    int? remainingSeconds,
    int? pausedSeconds,
  }) {
    return ExamSession(
      id: id,
      level: level,
      paperName: paperName,
      mode: mode,
      questions: questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answers: answers ?? this.answers,
      markedQuestions: markedQuestions ?? this.markedQuestions,
      status: status ?? this.status,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalSeconds: totalSeconds,
      pausedSeconds: pausedSeconds ?? this.pausedSeconds,
    );
  }
}

/// 考试会话子状态
class ExamSessionState {
  final ExamSession? session;

  const ExamSessionState({this.session});

  ExamSessionState copyWith({ExamSession? session}) {
    return ExamSessionState(session: session ?? this.session);
  }
}

// ========== Root AppState ==========

/// 全局应用状态
class AppState {
  final AuthState auth;
  final ThemeMode themeMode;
  final AudioPlayerState audioPlayer;
  final QuestionsState questions;
  final ReviewState review;
  final ExamRecordState examRecord;
  final StatisticsState statistics;
  final WrongBookState wrongBook;
  final ReviewSessionState reviewSession;
  final QuizSessionState quizSession;
  final ExamSessionState examSession;

  /// 服务引用（非状态，但需要在 thunk 中访问）
  final LocalStorageService localStorageService;
  final ApiService apiService;

  const AppState({
    this.auth = const AuthState(),
    this.themeMode = ThemeMode.system,
    this.audioPlayer = const AudioPlayerState(),
    this.questions = const QuestionsState(),
    this.review = const ReviewState(),
    this.examRecord = const ExamRecordState(),
    this.statistics = const StatisticsState(),
    this.wrongBook = const WrongBookState(),
    this.reviewSession = const ReviewSessionState(),
    this.quizSession = const QuizSessionState(),
    this.examSession = const ExamSessionState(),
    required this.localStorageService,
    required this.apiService,
  });

  AppState copyWith({
    AuthState? auth,
    ThemeMode? themeMode,
    AudioPlayerState? audioPlayer,
    QuestionsState? questions,
    ReviewState? review,
    ExamRecordState? examRecord,
    StatisticsState? statistics,
    WrongBookState? wrongBook,
    ReviewSessionState? reviewSession,
    QuizSessionState? quizSession,
    ExamSessionState? examSession,
  }) {
    return AppState(
      auth: auth ?? this.auth,
      themeMode: themeMode ?? this.themeMode,
      audioPlayer: audioPlayer ?? this.audioPlayer,
      questions: questions ?? this.questions,
      review: review ?? this.review,
      examRecord: examRecord ?? this.examRecord,
      statistics: statistics ?? this.statistics,
      wrongBook: wrongBook ?? this.wrongBook,
      reviewSession: reviewSession ?? this.reviewSession,
      quizSession: quizSession ?? this.quizSession,
      examSession: examSession ?? this.examSession,
      localStorageService: localStorageService,
      apiService: apiService,
    );
  }
}
