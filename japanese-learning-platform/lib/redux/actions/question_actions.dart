/// 题目相关 Actions
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/question_repository.dart';

// ========== Action Types ==========

class SelectedLevelChanged {
  final JLPTLevel level;
  SelectedLevelChanged(this.level);
}

class SelectedTypeChanged {
  final QuestionType? type;
  SelectedTypeChanged(this.type);
}

class QuestionsLoading {
  QuestionsLoading();
}

class QuestionsLoaded {
  final List<Question> questions;
  QuestionsLoaded(this.questions);
}

class QuestionsLoadError {
  final String error;
  QuestionsLoadError(this.error);
}

class QuestionByIdLoaded {
  final Question question;
  QuestionByIdLoaded(this.question);
}

class ExplanationLoaded {
  final String questionId;
  final Explanation explanation;
  ExplanationLoaded(this.questionId, this.explanation);
}

class ExplanationsLoading {
  ExplanationsLoading();
}

// ========== Thunk Actions ==========

/// 加载指定等级的题目
ThunkAction<AppState> loadQuestionsByLevel(JLPTLevel level) {
  return (Store<AppState> store) async {
    store.dispatch(QuestionsLoading());
    try {
      final repo = QuestionRepository(
        store.state.localStorageService,
        store.state.apiService,
      );
      final questions = await repo.getQuestionsByLevel(level);
      store.dispatch(QuestionsLoaded(questions));
    } catch (e) {
      store.dispatch(QuestionsLoadError(e.toString()));
    }
  };
}

/// 根据 ID 加载题目
ThunkAction<AppState> loadQuestionById(String id) {
  return (Store<AppState> store) async {
    try {
      final repo = QuestionRepository(
        store.state.localStorageService,
        store.state.apiService,
      );
      final question = await repo.getQuestionById(id);
      if (question != null) {
        store.dispatch(QuestionByIdLoaded(question));
      }
    } catch (_) {}
  };
}

/// 加载题目解析
ThunkAction<AppState> loadExplanation(String questionId) {
  return (Store<AppState> store) async {
    try {
      final repo = QuestionRepository(
        store.state.localStorageService,
        store.state.apiService,
      );
      final explanation = await repo.getExplanationByQuestion(questionId);
      if (explanation != null) {
        store.dispatch(ExplanationLoaded(questionId, explanation));
      }
    } catch (_) {}
  };
}
