/// 考试会话 Actions
library;

import 'dart:async';
import 'dart:convert';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/question_repository.dart';

// ========== Action Types ==========

class ExamSessionStarted {
  final ExamSession session;
  ExamSessionStarted(this.session);
}

class ExamSessionTimerTicked {
  final int remainingSeconds;
  ExamSessionTimerTicked(this.remainingSeconds);
}

class ExamSessionPaused {
  ExamSessionPaused();
}

class ExamSessionResumed {
  ExamSessionResumed();
}

class ExamSessionAnswerSelected {
  final String questionId;
  final String optionId;
  ExamSessionAnswerSelected(this.questionId, this.optionId);
}

class ExamSessionQuestionMarked {
  final String questionId;
  final bool marked;
  ExamSessionQuestionMarked(this.questionId, this.marked);
}

class ExamSessionQuestionChanged {
  final int index;
  ExamSessionQuestionChanged(this.index);
}

class ExamSessionSubmitted {
  final DateTime endTime;
  ExamSessionSubmitted(this.endTime);
}

class ExamSessionRestored {
  final ExamSession session;
  ExamSessionRestored(this.session);
}

// ========== Thunk Actions ==========

ThunkAction<AppState> startExamSession({
  required JLPTLevel level,
  required String paperName,
  required ExamMode mode,
  required List<Question> questions,
  required int totalSeconds,
}) {
  return (Store<AppState> store) async {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

    final session = ExamSession(
      id: sessionId,
      level: level,
      paperName: paperName,
      mode: mode,
      questions: questions,
      currentIndex: 0,
      answers: {},
      markedQuestions: {},
      status: ExamStatus.inProgress,
      startTime: DateTime.now(),
      remainingSeconds: totalSeconds,
      totalSeconds: totalSeconds,
    );

    store.dispatch(ExamSessionStarted(session));
    await _saveSession(session);
  };
}

ThunkAction<AppState> selectExamAnswer(String questionId, String optionId) {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null || session.status != ExamStatus.inProgress) return;

    store.dispatch(ExamSessionAnswerSelected(questionId, optionId));
    
    final updated = session.copyWith(
      answers: {...session.answers, questionId: optionId},
    );
    await _saveSession(updated);
  };
}

ThunkAction<AppState> toggleExamMark(String questionId) {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null) return;

    final newMarks = Set<String>.from(session.markedQuestions);
    final marked = !newMarks.contains(questionId);
    if (marked) {
      newMarks.add(questionId);
    } else {
      newMarks.remove(questionId);
    }

    store.dispatch(ExamSessionQuestionMarked(questionId, marked));
    
    final updated = session.copyWith(markedQuestions: newMarks);
    await _saveSession(updated);
  };
}

ThunkAction<AppState> nextExamQuestion() {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null) return;
    if (session.currentIndex < session.questions.length - 1) {
      store.dispatch(ExamSessionQuestionChanged(session.currentIndex + 1));
      final updated = session.copyWith(currentIndex: session.currentIndex + 1);
      await _saveSession(updated);
    }
  };
}

ThunkAction<AppState> previousExamQuestion() {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null) return;
    if (session.currentIndex > 0) {
      store.dispatch(ExamSessionQuestionChanged(session.currentIndex - 1));
      final updated = session.copyWith(currentIndex: session.currentIndex - 1);
      await _saveSession(updated);
    }
  };
}

ThunkAction<AppState> jumpToExamQuestion(int index) {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null) return;
    if (index >= 0 && index < session.questions.length) {
      store.dispatch(ExamSessionQuestionChanged(index));
      final updated = session.copyWith(currentIndex: index);
      await _saveSession(updated);
    }
  };
}

ThunkAction<AppState> submitExam({bool autoSubmit = false}) {
  return (Store<AppState> store) async {
    final session = store.state.examSession.session;
    if (session == null) return;

    final endTime = DateTime.now();
    store.dispatch(ExamSessionSubmitted(endTime));
    
    final updated = session.copyWith(
      status: ExamStatus.submitted,
      endTime: endTime,
    );
    await _saveSession(updated);
  };
}

Future<void> _saveSession(ExamSession session) async {
  final prefs = await SharedPreferences.getInstance();
  final sessionJson = {
    'id': session.id,
    'level': session.level.name,
    'paperName': session.paperName,
    'mode': session.mode.name,
    'questionIds': session.questions.map((q) => q.id).toList(),
    'currentIndex': session.currentIndex,
    'answers': session.answers,
    'markedQuestions': session.markedQuestions.toList(),
    'status': session.status.name,
    'startTime': session.startTime.toIso8601String(),
    'endTime': session.endTime?.toIso8601String(),
    'remainingSeconds': session.remainingSeconds,
    'totalSeconds': session.totalSeconds,
    'pausedSeconds': session.pausedSeconds,
  };

  await prefs.setString('exam_session_${session.id}', jsonEncode(sessionJson));
  await prefs.setString('current_exam_session', session.id);
}
