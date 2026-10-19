/// 答题会话 Actions
library;

import 'dart:convert';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';

// ========== Action Types ==========

class QuizSessionStarted {
  final QuizSession session;
  QuizSessionStarted(this.session);
}

class QuizSessionAnswerSelected {
  final String questionId;
  final String optionId;
  QuizSessionAnswerSelected(this.questionId, this.optionId);
}

class QuizSessionQuestionChanged {
  final int index;
  QuizSessionQuestionChanged(this.index);
}

class QuizSessionCurrentSubmitted {
  final String questionId;
  final bool isCorrect;
  QuizSessionCurrentSubmitted(this.questionId, this.isCorrect);
}

class QuizSessionAllSubmitted {
  final DateTime endTime;
  final Map<String, bool> submittedAnswers;
  QuizSessionAllSubmitted(this.endTime, this.submittedAnswers);
}

class QuizSessionRestored {
  final QuizSession session;
  QuizSessionRestored(this.session);
}

// ========== Thunk Actions ==========

ThunkAction<AppState> startQuizSession(JLPTLevel level, List<Question> questions) {
  return (Store<AppState> store) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final session = QuizSession(
      id: sessionId,
      level: level,
      questions: questions,
      currentIndex: 0,
      answers: {},
      status: QuizStatus.inProgress,
      startTime: DateTime.now(),
      submittedAnswers: {},
    );

    store.dispatch(QuizSessionStarted(session));
    await _saveSession(prefs, session);
  };
}

ThunkAction<AppState> selectQuizAnswer(String questionId, String optionId) {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null || session.status == QuizStatus.submitted) return;

    store.dispatch(QuizSessionAnswerSelected(questionId, optionId));
    
    final prefs = await SharedPreferences.getInstance();
    final updated = session.copyWith(
      answers: {...session.answers, questionId: optionId},
    );
    await _saveSession(prefs, updated);
  };
}

ThunkAction<AppState> nextQuizQuestion() {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null) return;
    if (session.currentIndex < session.questions.length - 1) {
      store.dispatch(QuizSessionQuestionChanged(session.currentIndex + 1));
      final prefs = await SharedPreferences.getInstance();
      final updated = session.copyWith(currentIndex: session.currentIndex + 1);
      await _saveSession(prefs, updated);
    }
  };
}

ThunkAction<AppState> previousQuizQuestion() {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null) return;
    if (session.currentIndex > 0) {
      store.dispatch(QuizSessionQuestionChanged(session.currentIndex - 1));
      final prefs = await SharedPreferences.getInstance();
      final updated = session.copyWith(currentIndex: session.currentIndex - 1);
      await _saveSession(prefs, updated);
    }
  };
}

ThunkAction<AppState> jumpToQuizQuestion(int index) {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null) return;
    if (index >= 0 && index < session.questions.length) {
      store.dispatch(QuizSessionQuestionChanged(index));
      final prefs = await SharedPreferences.getInstance();
      final updated = session.copyWith(currentIndex: index);
      await _saveSession(prefs, updated);
    }
  };
}

ThunkAction<AppState> submitCurrentQuizQuestion() {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null) return;
    final question = session.currentQuestion;
    if (question == null) return;

    final userAnswer = session.answers[question.id];
    if (userAnswer == null) return;

    final isCorrect = question.isCorrect(userAnswer);
    store.dispatch(QuizSessionCurrentSubmitted(question.id, isCorrect));
    
    final prefs = await SharedPreferences.getInstance();
    final updated = session.copyWith(
      submittedAnswers: {...session.submittedAnswers, question.id: isCorrect},
    );
    await _saveSession(prefs, updated);
  };
}

ThunkAction<AppState> submitAllQuiz() {
  return (Store<AppState> store) async {
    final session = store.state.quizSession.session;
    if (session == null) return;

    final submittedAnswers = <String, bool>{};
    for (final q in session.questions) {
      final userAnswer = session.answers[q.id];
      if (userAnswer != null) {
        submittedAnswers[q.id] = q.isCorrect(userAnswer);
      }
    }

    final endTime = DateTime.now();
    store.dispatch(QuizSessionAllSubmitted(endTime, submittedAnswers));
    
    final prefs = await SharedPreferences.getInstance();
    final updated = session.copyWith(
      status: QuizStatus.submitted,
      endTime: endTime,
      submittedAnswers: submittedAnswers,
    );
    await _saveSession(prefs, updated);
  };
}

Future<void> _saveSession(SharedPreferences prefs, QuizSession session) async {
  final sessionJson = {
    'id': session.id,
    'level': session.level.name,
    'questionIds': session.questions.map((q) => q.id).toList(),
    'currentIndex': session.currentIndex,
    'answers': session.answers,
    'status': session.status.name,
    'startTime': session.startTime.toIso8601String(),
    'endTime': session.endTime?.toIso8601String(),
    'submittedAnswers': session.submittedAnswers,
  };

  await prefs.setString('quiz_session_${session.id}', jsonEncode(sessionJson));
  await prefs.setString('current_quiz_session', session.id);
}
