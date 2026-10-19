/// Redux Store 配置
library;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'app_state.dart';
import 'reducers/app_reducer.dart';
import '../core/storage/local_storage_service.dart';
import '../core/network/api_service.dart';
import '../core/network/dio_api_service.dart';

/// 创建 Redux Store
/// 
/// [storageService] 本地存储服务（已初始化）
/// [apiService] API 服务（可选，默认创建 DioApiService）
Store<AppState> createStore({
  required LocalStorageService storageService,
  ApiService? apiService,
}) {
  final api = apiService ?? DioApiService(baseUrl: 'http://localhost:3000/api/v1');
  
  final initialState = AppState(
    localStorageService: storageService,
    apiService: api,
  );

  return Store<AppState>(
    appReducer,
    initialState: initialState,
    middleware: [thunkMiddleware],
  );
}
