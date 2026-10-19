/// 答题会话 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/quiz_session_actions.dart';

/// 答题会话状态 Reducer
Reducer<QuizSessionState> quizSessionReducer = combineReducers<QuizSessionState>([
  TypedReducer<QuizSessionState, QuizSessionStarted>(_started),
  TypedReducer<QuizSessionState, QuizSessionAnswerSelected>(_answerSelected),
  TypedReducer<QuizSessionState, QuizSessionQuestionChanged>(_questionChanged),
  TypedReducer<QuizSessionState, QuizSessionCurrentSubmitted>(_currentSubmitted),
  TypedReducer<QuizSessionState, QuizSessionAllSubmitted>(_allSubmitted),
  TypedReducer<QuizSessionState, QuizSessionRestored>(_restored),
]);

QuizSessionState _started(QuizSessionState state, QuizSessionStarted action) {
  return state.copyWith(session: action.session);
}

QuizSessionState _answerSelected(QuizSessionState state, QuizSessionAnswerSelected action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedAnswers = Map<String, String>.from(session.answers);
  updatedAnswers[action.questionId] = action.optionId;
  
  final updatedSession = session.copyWith(answers: updatedAnswers);
  return state.copyWith(session: updatedSession);
}

QuizSessionState _questionChanged(QuizSessionState state, QuizSessionQuestionChanged action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(currentIndex: action.index);
  return state.copyWith(session: updatedSession);
}

QuizSessionState _currentSubmitted(QuizSessionState state, QuizSessionCurrentSubmitted action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSubmitted = Map<String, bool>.from(session.submittedAnswers);
  updatedSubmitted[action.questionId] = action.isCorrect;
  
  final updatedSession = session.copyWith(submittedAnswers: updatedSubmitted);
  return state.copyWith(session: updatedSession);
}

QuizSessionState _allSubmitted(QuizSessionState state, QuizSessionAllSubmitted action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedSession = session.copyWith(
    status: QuizStatus.submitted,
    endTime: action.endTime,
    submittedAnswers: action.submittedAnswers,
  );
  return state.copyWith(session: updatedSession);
}

QuizSessionState _restored(QuizSessionState state, QuizSessionRestored action) {
  return state.copyWith(session: action.session);
}
