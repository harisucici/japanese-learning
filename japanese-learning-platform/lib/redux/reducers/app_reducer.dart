/// 根 Reducer - 组合所有子 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import 'auth_reducer.dart';
import 'theme_reducer.dart';
import 'audio_reducer.dart';
import 'question_reducer.dart';
import 'review_reducer.dart';
import 'exam_record_reducer.dart';
import 'statistics_reducer.dart';
import 'wrong_book_reducer.dart';
import 'review_session_reducer.dart';
import 'quiz_session_reducer.dart';
import 'exam_session_reducer.dart';

/// 根 Reducer
/// 
/// 将 AppState 的各个子状态分别交给对应的 reducer 处理
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    auth: authReducer(state.auth, action),
    themeMode: themeModeReducer(state.themeMode, action),
    audioPlayer: audioPlayerReducer(state.audioPlayer, action),
    questions: questionsReducer(state.questions, action),
    review: reviewReducer(state.review, action),
    examRecord: examRecordReducer(state.examRecord, action),
    statistics: statisticsReducer(state.statistics, action),
    wrongBook: wrongBookReducer(state.wrongBook, action),
    reviewSession: reviewSessionReducer(state.reviewSession, action),
    quizSession: quizSessionReducer(state.quizSession, action),
    examSession: examSessionReducer(state.examSession, action),
    localStorageService: state.localStorageService,
    apiService: state.apiService,
  );
}
