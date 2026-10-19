/// 统计 Actions
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';
import '../repositories/statistics_repository.dart';

// ========== Action Types ==========

class StatisticsLoaded {
  final LearningStatistics statistics;
  StatisticsLoaded(this.statistics);
}

class StatisticsLoading {
  StatisticsLoading();
}

class StatisticsLoadError {
  final String error;
  StatisticsLoadError(this.error);
}

// ========== Thunk Actions ==========

ThunkAction<AppState> loadStatistics() {
  return (Store<AppState> store) async {
    final user = store.state.auth.user;
    if (user == null) {
      store.dispatch(StatisticsLoaded(LearningStatistics.empty));
      return;
    }
    store.dispatch(StatisticsLoading());
    try {
      final repo = StatisticsRepository();
      final stats = await repo.calculateStatistics(
        records: store.state.examRecord.records,
        reviewItems: store.state.review.reviewItems,
        dueItems: store.state.review.dueItems,
      );
      store.dispatch(StatisticsLoaded(stats));
    } catch (e) {
      store.dispatch(StatisticsLoadError(e.toString()));
    }
  };
}
