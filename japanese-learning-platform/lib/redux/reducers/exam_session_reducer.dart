/// 考试会话 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/exam_session_actions.dart';

/// 考试会话状态 Reducer
Reducer<ExamSessionState> examSessionReducer = combineReducers<ExamSessionState>([
  TypedReducer<ExamSessionState, ExamSessionStarted>(_started),
  TypedReducer<ExamSessionState, ExamSessionTimerTicked>(_timerTicked),
  TypedReducer<ExamSessionState, ExamSessionPaused>(_paused),
  TypedReducer<ExamSessionState, ExamSessionResumed>(_resumed),
  TypedReducer<ExamSessionState, ExamSessionAnswerSelected>(_answerSelected),
  TypedReducer<ExamSessionState, ExamSessionQuestionMarked>(_questionMarked),
  TypedReducer<ExamSessionState, ExamSessionQuestionChanged>(_questionChanged),
  TypedReducer<ExamSessionState, ExamSessionSubmitted>(_submitted),
  TypedReducer<ExamSessionState, ExamSessionRestored>(_restored),
]);

ExamSessionState _started(ExamSessionState state, ExamSessionStarted action) {
  return state.copyWith(session: action.session);
}

ExamSessionState _timerTicked(ExamSessionState state, ExamSessionTimerTicked action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(remainingSeconds: action.remainingSeconds);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _paused(ExamSessionState state, ExamSessionPaused action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(status: ExamStatus.paused);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _resumed(ExamSessionState state, ExamSessionResumed action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(status: ExamStatus.inProgress);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _answerSelected(ExamSessionState state, ExamSessionAnswerSelected action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedAnswers = Map<String, String>.from(session.answers);
  updatedAnswers[action.questionId] = action.optionId;
  
  final updatedSession = session.copyWith(answers: updatedAnswers);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _questionMarked(ExamSessionState state, ExamSessionQuestionMarked action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedMarks = Set<String>.from(session.markedQuestions);
  if (action.marked) {
    updatedMarks.add(action.questionId);
  } else {
    updatedMarks.remove(action.questionId);
  }
  
  final updatedSession = session.copyWith(markedQuestions: updatedMarks);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _questionChanged(ExamSessionState state, ExamSessionQuestionChanged action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(currentIndex: action.index);
  return state.copyWith(session: updatedSession);
}

ExamSessionState _submitted(ExamSessionState state, ExamSessionSubmitted action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(
    status: ExamStatus.submitted,
    endTime: action.endTime,
  );
  return state.copyWith(session: updatedSession);
}

ExamSessionState _restored(ExamSessionState state, ExamSessionRestored action) {
  return state.copyWith(session: action.session);
}
