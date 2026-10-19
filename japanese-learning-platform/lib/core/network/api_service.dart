import 'package:dio/dio.dart' show DioException;

/// API 响应包装
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  const ApiResponse({required this.code, required this.message, this.data});

  bool get isSuccess => code == 0 || code == 200;
}

/// 请求选项（分页、筛选等）
class PaginationOptions {
  final Map<String, dynamic>? queryParameters;
  final Map<String, String>? headers;
  final int? page;
  final int? pageSize;

  const PaginationOptions({
    this.queryParameters,
    this.headers,
    this.page,
    this.pageSize,
  });

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{...?queryParameters};
    if (page != null) q['page'] = page;
    if (pageSize != null) q['pageSize'] = pageSize;
    return q;
  }
}

/// 网络服务抽象接口（Dio 实现见 api_service.dart）
///
/// 设计为抽象类，便于后续切换底层实现（Dio -> mock/其他）。
abstract class ApiService {
  /// 基础 URL
  String get baseUrl;

  /// 认证 Token 设置
  Future<void> setAuthToken(String? token);

  /// GET
  Future<ApiResponse<Map<String, dynamic>>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  });

  /// POST
  Future<ApiResponse<Map<String, dynamic>>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  /// PUT
  Future<ApiResponse<Map<String, dynamic>>> put(
    String path, {
    dynamic data,
  });

  /// DELETE
  Future<ApiResponse<Map<String, dynamic>>> delete(
    String path, {
    dynamic data,
  });

  /// 释放资源
  void close();
}

/// 预定义的 API 路径常量
class ApiEndpoints {
  static const String auth = '/api/v1/auth';
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String me = '$auth/me';
  static const String profile = '$auth/profile';

  static const String questions = '/api/v1/questions';
  static const String questionById = '$questions/:id';
  static const String questionsByLevel = '$questions/level/:level';

  static const String explanations = '/api/v1/explanations';
  static const String explanationByQuestion = '$explanations/question/:id';

  static const String records = '/api/v1/records';
  static const String recordById = '$records/:id';

  static const String review = '/api/v1/review';
  static const String reviewItems = '$review/items';
  static const String reviewDue = '$review/due';

  static const String stats = '/api/v1/stats';
  static const String userStats = '$stats/me';

  /// 路径参数替换
  static String withParam(String path, String key, String value) {
    return path.replaceAll(':$key', value);
  }
}
