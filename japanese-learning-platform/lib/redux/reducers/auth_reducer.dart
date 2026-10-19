/// 认证 Reducer
library;

import 'package:redux/redux.dart';

import '../app_state.dart';
import '../actions/auth_actions.dart';

/// 认证状态 Reducer
Reducer<AuthState> authReducer = combineReducers<AuthState>([
  TypedReducer<AuthState, AuthStatusChanged>(_authStatusChanged),
  TypedReducer<AuthState, AuthUserUpdated>(_authUserUpdated),
]);

AuthState _authStatusChanged(AuthState state, AuthStatusChanged action) {
  return state.copyWith(
    status: action.status,
    user: action.user ?? state.user,
    errorMessage: action.errorMessage,
  );
}

AuthState _authUserUpdated(AuthState state, AuthUserUpdated action) {
  return state.copyWith(user: action.user);
}
