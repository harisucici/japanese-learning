import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/api_config.dart' as config;

/// All learner content, attempts and scores come from the backend database.
class LearningClient {
  final Dio http;
  SharedPreferences? _prefs;
  LearningClient({Dio? transport})
      : http = transport ??
            Dio(BaseOptions(
              baseUrl:
                  '${config.baseUrl.replaceFirst(RegExp(r'/$'), '')}/learning/',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 15),
            ));

  Future<Map<String, dynamic>> request(String path, {Object? body}) async {
    try {
      final response = body == null
          ? await http.get(path)
          : await http.post(path, data: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw Exception(data is Map && data['error'] is String
          ? data['error']
          : '无法连接服务，请检查后端后重试');
    }
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final token = _prefs!.getString('database_learning_token');
    if (token != null) {
      http.options.headers['Authorization'] = 'Bearer $token';
      try {
        await http.get('dashboard');
        return;
      } on DioException catch (e) {
        if (e.response?.statusCode != 401 && e.response?.statusCode != 404) {
          rethrow;
        }
      }
    }
    final guest = await request('guest', body: {});
    await _acceptToken(guest['token'] as String);
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await http
          .post('../auth/login', data: {'email': email, 'password': password});
      await _acceptToken((response.data as Map)['token'] as String);
    } on DioException {
      throw Exception('登录失败，请检查邮箱和密码');
    }
  }

  Future<void> _acceptToken(String token) async {
    http.options.headers['Authorization'] = 'Bearer $token';
    await _prefs!.setString('database_learning_token', token);
  }

  Future<Map<String, dynamic>> catalog() => request('catalog');
  Future<Map<String, dynamic>> dashboard() => request('dashboard');
  Future<Map<String, dynamic>> mistakes() => request('mistakes');
  Future<Map<String, dynamic>> session(String id) => request('sessions/$id');
  Future<Map<String, dynamic>> start(String level,
          {String? type, int? limit, String mode = 'practice'}) =>
      request('sessions', body: {
        'level': level,
        if (type != null) 'type': type,
        if (limit != null) 'limit': limit,
        'mode': mode
      });
  Future<Map<String, dynamic>> answer(
          String id, String question, String option) =>
      request('sessions/$id/answers',
          body: {'questionId': question, 'optionId': option});
  Future<Map<String, dynamic>> next(String id) =>
      request('sessions/$id/next', body: {});
  Future<Map<String, dynamic>> papers() => request('exam-papers');
  Future<Map<String, dynamic>> startExam(
          String level, String paperId, bool feedback) =>
      request('sessions', body: {
        'level': level,
        'mode': 'exam',
        'paperId': paperId,
        'instantFeedback': feedback
      });
  Future<Map<String, dynamic>> section(String id, String action) =>
      request('sessions/$id/section', body: {'action': action});
  Future<Map<String, dynamic>> novelLessons() => request('novel-lessons');
  Future<Map<String, dynamic>> novelLesson(String id) =>
      request('novel-lessons/$id');
  Future<Map<String, dynamic>> funPapers() => request('fun-papers');
  Future<Map<String, dynamic>> materials() => request('materials');
  Future<Map<String, dynamic>> material(String id) => request('materials/$id');
  Future<Map<String, dynamic>> startFun(String id) => request('sessions',
      body: {'level': 'n5', 'mode': 'fun', 'collectionId': id});
}
