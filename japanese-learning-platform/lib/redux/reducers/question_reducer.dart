/// 题目 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/question_actions.dart';
import '../../shared/models/question.dart';
import '../../shared/models/explanation.dart';

/// 题目状态 Reducer
Reducer<QuestionsState> questionsReducer = combineReducers<QuestionsState>([
  TypedReducer<QuestionsState, SelectedLevelChanged>(_selectedLevelChanged),
  TypedReducer<QuestionsState, SelectedTypeChanged>(_selectedTypeChanged),
  TypedReducer<QuestionsState, QuestionsLoading>(_loading),
  TypedReducer<QuestionsState, QuestionsLoaded>(_loaded),
  TypedReducer<QuestionsState, QuestionsLoadError>(_loadError),
  TypedReducer<QuestionsState, QuestionByIdLoaded>(_questionByIdLoaded),
  TypedReducer<QuestionsState, ExplanationLoaded>(_explanationLoaded),
]);

QuestionsState _selectedLevelChanged(QuestionsState state, SelectedLevelChanged action) {
  return state.copyWith(selectedLevel: action.level);
}

QuestionsState _selectedTypeChanged(QuestionsState state, SelectedTypeChanged action) {
  return state.copyWith(
    selectedType: action.type,
    clearSelectedType: action.type == null,
  );
}

QuestionsState _loading(QuestionsState state, QuestionsLoading action) {
  return state.copyWith(loading: true, clearError: true);
}

QuestionsState _loaded(QuestionsState state, QuestionsLoaded action) {
  final questionsById = Map<String, Question>.from(state.questionsById);
  for (final q in action.questions) {
    questionsById[q.id] = q;
  }
  return state.copyWith(
    questions: action.questions,
    loading: false,
    questionsById: questionsById,
  );
}

QuestionsState _loadError(QuestionsState state, QuestionsLoadError action) {
  return state.copyWith(loading: false, error: action.error);
}

QuestionsState _questionByIdLoaded(QuestionsState state, QuestionByIdLoaded action) {
  final questionsById = Map<String, Question>.from(state.questionsById);
  questionsById[action.question.id] = action.question;
  return state.copyWith(questionsById: questionsById);
}

QuestionsState _explanationLoaded(QuestionsState state, ExplanationLoaded action) {
  final explanationsById = Map<String, Explanation>.from(state.explanationsById);
  explanationsById[action.questionId] = action.explanation;
  return state.copyWith(explanationsById: explanationsById);
}
