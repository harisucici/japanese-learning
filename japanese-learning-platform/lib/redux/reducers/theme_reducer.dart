/// 主题 Reducer
library;

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/theme_actions.dart';

/// 主题模式 Reducer
Reducer<ThemeMode> themeModeReducer = combineReducers<ThemeMode>([
  TypedReducer<ThemeMode, ThemeModeChanged>(_themeModeChanged),
]);

ThemeMode _themeModeChanged(ThemeMode state, ThemeModeChanged action) {
  return action.mode;
}
