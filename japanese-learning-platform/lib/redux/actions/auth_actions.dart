/// 认证相关 Actions
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import '../app_state.dart';
import '../../shared/models/models.dart';

// ========== Action Types ==========

class AuthStatusChanged {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthStatusChanged({
    required this.status,
    this.user,
    this.errorMessage,
  });
}

class AuthUserUpdated {
  final User user;
  AuthUserUpdated(this.user);
}

// ========== Thunk Actions ==========

/// 恢复会话
ThunkAction<AppState> restoreSession() {
  return (Store<AppState> store) async {
    store.dispatch(AuthStatusChanged(status: AuthStatus.loading));
    try {
      final storage = store.state.localStorageService;
      final api = store.state.apiService;
      
      final userId = await storage.getCurrentUserId();
      if (userId == null) {
        store.dispatch(AuthStatusChanged(status: AuthStatus.signedOut));
        return;
      }
      final json = await storage.getUser(userId);
      if (json == null) {
        await storage.setCurrentUser('');
        store.dispatch(AuthStatusChanged(status: AuthStatus.signedOut));
        return;
      }
      final token = await storage.getAuthToken();
      await api.setAuthToken(token);
      
      store.dispatch(AuthStatusChanged(
        status: AuthStatus.signedIn,
        user: User.fromJson(json),
      ));
    } catch (e) {
      store.dispatch(AuthStatusChanged(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  };
}

/// 登录
ThunkAction<AppState> signIn({
  required String email,
  required String password,
}) {
  return (Store<AppState> store) async {
    store.dispatch(AuthStatusChanged(status: AuthStatus.loading));
    try {
      final storage = store.state.localStorageService;
      final api = store.state.apiService;
      
      final resp = await api.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      if (!resp.isSuccess) {
        store.dispatch(AuthStatusChanged(
          status: AuthStatus.error,
          errorMessage: resp.message,
        ));
        return;
      }
      final data = resp.data ?? {};
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      if (userJson != null) {
        final user = User.fromJson(userJson);
        await storage.saveUser(user.toJson());
        await storage.setCurrentUser(user.id);
        await storage.setAuthToken(token);
        await api.setAuthToken(token);
        store.dispatch(AuthStatusChanged(
          status: AuthStatus.signedIn,
          user: user,
        ));
      }
    } catch (e) {
      store.dispatch(AuthStatusChanged(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  };
}

/// 注册
ThunkAction<AppState> signUp({
  required String email,
  required String password,
  required String name,
  JLPTLevel targetLevel = JLPTLevel.n5,
}) {
  return (Store<AppState> store) async {
    store.dispatch(AuthStatusChanged(status: AuthStatus.loading));
    try {
      final storage = store.state.localStorageService;
      final api = store.state.apiService;
      
      final resp = await api.post(
        '/api/v1/auth/register',
        data: {
          'email': email,
          'password': password,
          'name': name,
          'targetLevel': targetLevel.name,
        },
      );
      if (!resp.isSuccess) {
        store.dispatch(AuthStatusChanged(
          status: AuthStatus.error,
          errorMessage: resp.message,
        ));
        return;
      }
      final data = resp.data ?? {};
      final token = data['token'] as String?;
      final userJson = data['user'] as Map<String, dynamic>?;

      User user;
      if (userJson != null) {
        user = User.fromJson(userJson);
      } else {
        user = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          email: email,
          name: name,
          targetLevel: targetLevel,
        );
      }
      await storage.saveUser(user.toJson());
      await storage.setCurrentUser(user.id);
      await storage.setAuthToken(token);
      await api.setAuthToken(token);
      store.dispatch(AuthStatusChanged(
        status: AuthStatus.signedIn,
        user: user,
      ));
    } catch (e) {
      store.dispatch(AuthStatusChanged(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  };
}

/// 登出
ThunkAction<AppState> signOut() {
  return (Store<AppState> store) async {
    try {
      final api = store.state.apiService;
      await api.post('/api/v1/auth/logout');
    } catch (_) {}
    try {
      final storage = store.state.localStorageService;
      final api = store.state.apiService;
      await api.setAuthToken(null);
      await storage.setCurrentUser('');
      await storage.setAuthToken(null);
    } catch (_) {}
    store.dispatch(AuthStatusChanged(status: AuthStatus.signedOut));
  };
}

/// 更新用户信息
ThunkAction<AppState> updateUser(User updated) {
  return (Store<AppState> store) async {
    final storage = store.state.localStorageService;
    final api = store.state.apiService;
    
    await storage.saveUser(updated.toJson());
    store.dispatch(AuthUserUpdated(updated));
    
    try {
      await api.put(
        '/api/v1/users/id/${updated.id}',
        data: updated.toJson(),
      );
    } catch (_) {}
  };
}
