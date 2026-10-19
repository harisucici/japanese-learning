/// 考试记录 Actions
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/exam_record_repository.dart';

// ========== Action Types ==========

class ExamRecordsLoaded {
  final List<ExamRecord> records;
  ExamRecordsLoaded(this.records);
}

class ExamRecordsLoading {
  ExamRecordsLoading();
}

class ExamRecordsLoadError {
  final String error;
  ExamRecordsLoadError(this.error);
}

class ExamRecordSaved {
  final ExamRecord record;
  ExamRecordSaved(this.record);
}

// ========== Thunk Actions ==========

ThunkAction<AppState> loadExamRecords() {
  return (Store<AppState> store) async {
    final user = store.state.auth.user;
    if (user == null) {
      store.dispatch(ExamRecordsLoaded(const []));
      return;
    }
    store.dispatch(ExamRecordsLoading());
    try {
      final repo = ExamRecordRepository(store.state.localStorageService);
      final records = await repo.getRecords(user.id);
      store.dispatch(ExamRecordsLoaded(records));
    } catch (e) {
      store.dispatch(ExamRecordsLoadError(e.toString()));
    }
  };
}

ThunkAction<AppState> saveExamRecord({
  required JLPTLevel level,
  required ExamRecordType recordType,
  required List<Question> questions,
  required Map<String, String> answers,
  required int durationMs,
  String? setId,
  String? note,
}) {
  return (Store<AppState> store) async {
    final user = store.state.auth.user;
    if (user == null) return;
    try {
      final repo = ExamRecordRepository(store.state.localStorageService);
      final record = await repo.saveRecord(
        userId: user.id,
        level: level,
        recordType: recordType,
        questions: questions,
        answers: answers,
        durationMs: durationMs,
        setId: setId,
        note: note,
      );
      store.dispatch(ExamRecordSaved(record));
      store.dispatch(loadExamRecords());
    } catch (_) {}
  };
}
