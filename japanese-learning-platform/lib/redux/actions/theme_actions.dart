/// 主题相关 Actions
library;

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_state.dart';
import '../../core/constants/app_constants.dart';

// ========== Action Types ==========

class ThemeModeChanged {
  final ThemeMode mode;
  ThemeModeChanged(this.mode);
}

// ========== Thunk Actions ==========

/// 设置主题模式
ThunkAction<AppState> setThemeMode(ThemeMode mode) {
  return (Store<AppState> store) async {
    store.dispatch(ThemeModeChanged(mode));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, mode.index);
  };
}

/// 切换主题模式
ThunkAction<AppState> toggleThemeMode() {
  return (Store<AppState> store) async {
    final current = store.state.themeMode;
    ThemeMode next;
    switch (current) {
      case ThemeMode.system:
        next = ThemeMode.light;
        break;
      case ThemeMode.light:
        next = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        next = ThemeMode.system;
        break;
    }
    store.dispatch(ThemeModeChanged(next));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyThemeMode, next.index);
  };
}
