/// 考试记录 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/exam_record_actions.dart';

/// 考试记录状态 Reducer
Reducer<ExamRecordState> examRecordReducer = combineReducers<ExamRecordState>([
  TypedReducer<ExamRecordState, ExamRecordsLoading>(_loading),
  TypedReducer<ExamRecordState, ExamRecordsLoaded>(_loaded),
  TypedReducer<ExamRecordState, ExamRecordsLoadError>(_loadError),
  TypedReducer<ExamRecordState, ExamRecordSaved>(_recordSaved),
]);

ExamRecordState _loading(ExamRecordState state, ExamRecordsLoading action) {
  return state.copyWith(loading: true, clearError: true);
}

ExamRecordState _loaded(ExamRecordState state, ExamRecordsLoaded action) {
  return state.copyWith(records: action.records, loading: false);
}

ExamRecordState _loadError(ExamRecordState state, ExamRecordsLoadError action) {
  return state.copyWith(loading: false, error: action.error);
}

ExamRecordState _recordSaved(ExamRecordState state, ExamRecordSaved action) {
  final records = [...state.records, action.record];
  return state.copyWith(records: records);
}
