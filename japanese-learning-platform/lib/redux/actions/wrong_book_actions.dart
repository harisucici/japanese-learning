/// 错题本 Actions
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';

// ========== Action Types ==========

class WrongBookLevelFilterChanged {
  final JLPTLevel? level;
  WrongBookLevelFilterChanged(this.level);
}

class WrongBookTypeFilterChanged {
  final QuestionType? type;
  WrongBookTypeFilterChanged(this.type);
}

class WrongBookSortChanged {
  final WrongBookSort sort;
  WrongBookSortChanged(this.sort);
}

class WrongBookCleared {
  WrongBookCleared();
}

class WrongBookItemsFiltered {
  final List<ReviewItem> items;
  WrongBookItemsFiltered(this.items);
}
