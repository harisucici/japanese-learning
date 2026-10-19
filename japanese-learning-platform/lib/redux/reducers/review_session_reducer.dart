/// 复习会话 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/review_session_actions.dart';

/// 复习会话状态 Reducer
Reducer<ReviewSessionState> reviewSessionReducer = combineReducers<ReviewSessionState>([
  TypedReducer<ReviewSessionState, ReviewSessionStarted>(_started),
  TypedReducer<ReviewSessionState, ReviewSessionAnswered>(_answered),
  TypedReducer<ReviewSessionState, ReviewSessionEnded>(_ended),
]);

ReviewSessionState _started(ReviewSessionState state, ReviewSessionStarted action) {
  return state.copyWith(session: action.session);
}

ReviewSessionState _answered(ReviewSessionState state, ReviewSessionAnswered action) {
  final session = state.session;
  if (session == null) return state;
  
  final updatedResults = Map<String, bool>.from(session.results);
  updatedResults[action.questionId] = action.isCorrect;
  
  final updatedSession = session.copyWith(
    results: updatedResults,
    currentIndex: action.nextIndex,
  );
  return state.copyWith(session: updatedSession);
}

ReviewSessionState _ended(ReviewSessionState state, ReviewSessionEnded action) {
  return const ReviewSessionState();
}
