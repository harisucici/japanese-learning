import 'package:dio/dio.dart';

import 'api_service.dart';

/// Dio 实现的网络服务
///
/// 预配置：
/// - JSON 解码
/// - 请求/响应拦截器（日志、token、错误处理）
/// - 超时 30s
/// - 重定向 5 次
class DioApiService implements ApiService {
  late final Dio _dio;
  final String _baseUrl;
  String? _authToken;

  DioApiService({
    String baseUrl = 'http://localhost:3000/api/v1',
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 30),
    Duration sendTimeout = const Duration(seconds: 30),
    List<Interceptor> interceptors = const [],
  }) : _baseUrl = baseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: sendTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(() => _authToken),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          // ignore: avoid_print
          // print(obj);  // 生产环境注释掉
        },
      ),
      ...interceptors,
    ]);
  }

  @override
  String get baseUrl => _baseUrl;

  @override
  Future<void> setAuthToken(String? token) async {
    _authToken = token;
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return _wrap(response);
    } on DioException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return _wrap(response);
    } on DioException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
      );
      return _wrap(response);
    } on DioException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        path,
        data: data,
      );
      return _wrap(response);
    } on DioException catch (e) {
      return _wrapError(e);
    }
  }

  @override
  void close() {
    _dio.close();
  }

  ApiResponse<Map<String, dynamic>> _wrap(Response<Map<String, dynamic>> res) {
    final data = res.data ?? <String, dynamic>{};
    // 约定：{ code: 0, message: 'ok', data: {...} }
    final code = (data['code'] as num?)?.toInt() ?? res.statusCode ?? 0;
    final message = data['message'] as String? ?? 'ok';
    final payload = data['data'];
    return ApiResponse<Map<String, dynamic>>(
      code: code,
      message: message,
      data: payload is Map<String, dynamic> ? payload : data,
    );
  }

  ApiResponse<Map<String, dynamic>> _wrapError(DioException e) {
    final status = e.response?.statusCode ?? 0;
    final message = _resolveMessage(e);
    return ApiResponse<Map<String, dynamic>>(
      code: status,
      message: message,
      data: e.response?.data is Map<String, dynamic>
          ? e.response!.data as Map<String, dynamic>
          : null,
    );
  }

  String _resolveMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时';
      case DioExceptionType.connectionError:
        return '无法连接服务器';
      case DioExceptionType.badResponse:
        return _httpStatusMessage(e.response?.statusCode ?? 0);
      case DioExceptionType.cancel:
        return '请求被取消';
      default:
        return e.message ?? '未知错误';
    }
  }

  String _httpStatusMessage(int status) {
    switch (status) {
      case 400:
        return '请求参数错误';
      case 401:
        return '未登录或 token 已过期';
      case 403:
        return '无权限访问';
      case 404:
        return '资源不存在';
      case 409:
        return '资源冲突';
      case 422:
        return '参数校验失败';
      case 429:
        return '请求过于频繁';
      case 500:
        return '服务器错误';
      default:
        return 'HTTP $status';
    }
  }
}

/// Token 拦截器
class _AuthInterceptor extends Interceptor {
  final String? Function() _getToken;

  _AuthInterceptor(this._getToken);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
