/// 统计 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/statistics_actions.dart';

/// 统计状态 Reducer
Reducer<StatisticsState> statisticsReducer = combineReducers<StatisticsState>([
  TypedReducer<StatisticsState, StatisticsLoading>(_loading),
  TypedReducer<StatisticsState, StatisticsLoaded>(_loaded),
  TypedReducer<StatisticsState, StatisticsLoadError>(_loadError),
]);

StatisticsState _loading(StatisticsState state, StatisticsLoading action) {
  return state.copyWith(loading: true, clearError: true);
}

StatisticsState _loaded(StatisticsState state, StatisticsLoaded action) {
  return state.copyWith(statistics: action.statistics, loading: false);
}

StatisticsState _loadError(StatisticsState state, StatisticsLoadError action) {
  return state.copyWith(loading: false, error: action.error);
}
