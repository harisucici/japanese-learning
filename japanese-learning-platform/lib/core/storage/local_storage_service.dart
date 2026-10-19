import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive 本地存储服务
///
/// 提供统一的键值存储接口。所有模型通过 toJson/fromJson 序列化，
/// 以 Map<String, dynamic> 形式写入 Hive。
///
/// 使用约定：
/// - 每个类型使用一个独立的 Box
/// - 键为模型 ID
/// - 值为 JSON Map
class LocalStorageService {
  static const String _userBox = 'users';
  static const String _questionBox = 'questions';
  static const String _explanationBox = 'explanations';
  static const String _examRecordBox = 'exam_records';
  static const String _reviewItemBox = 'review_items';
  static const String _settingsBox = 'settings';
  static const String _currentUserKey = 'current_user_id';
  static const String _authTokenKey = 'auth_token';

  bool _initialized = false;
  
  /// Cached box references to avoid repeated Hive.box() lookups
  final Map<String, Box<Map>> _boxes = {};

  /// 初始化 Hive（仅一次）
  Future<void> init() async {
    if (_initialized) return;
    // Hive.initFlutter() 已在 main.dart 中调用，这里只打开 boxes
    try {
      _boxes[_userBox] = await _openBox(_userBox);
      _boxes[_questionBox] = await _openBox(_questionBox);
      _boxes[_explanationBox] = await _openBox(_explanationBox);
      _boxes[_examRecordBox] = await _openBox(_examRecordBox);
      _boxes[_reviewItemBox] = await _openBox(_reviewItemBox);
      _boxes[_settingsBox] = await _openBox(_settingsBox);
      _initialized = true;
    } catch (e) {
      print('LocalStorageService.init() 错误: $e');
      rethrow;
    }
  }

  Future<Box<Map>> _openBox(String name) async {
    try {
      if (!Hive.isBoxOpen(name)) {
        return await Hive.openBox<Map>(name);
      }
      return Hive.box<Map>(name);
    } catch (e) {
      print('打开 Box "$name" 失败: $e');
      rethrow;
    }
  }
  
  /// Get cached box reference
  Box<Map> _getBox(String name) {
    final box = _boxes[name];
    if (box == null) {
      throw StateError('Box "$name" not initialized. Call init() first.');
    }
    return box;
  }

  // ====== 通用读写 ======

  /// 写入单个对象
  Future<void> put<T>(String boxName, String key, T value) async {
    final box = _getBox(boxName);
    if (value is Map) {
      await box.put(key, value);
    } else {
      throw ArgumentError('Only Map values supported in Hive service');
    }
  }

  /// 读取单个对象
  Future<Map<String, dynamic>?> get(String boxName, String key) async {
    final box = _getBox(boxName);
    final value = box.get(key);
    if (value == null) return null;
    return Map<String, dynamic>.from(value);
  }

  /// 删除
  Future<void> delete(String boxName, String key) async {
    final box = _getBox(boxName);
    await box.delete(key);
  }

  /// 读取全部
  Future<List<Map<String, dynamic>>> getAll(String boxName) async {
    final box = _getBox(boxName);
    return box.values
        .map((v) => Map<String, dynamic>.from(v))
        .toList(growable: false);
  }

  /// 清空指定 box
  Future<void> clearBox(String boxName) async {
    final box = _getBox(boxName);
    await box.clear();
  }

  // ====== 用户相关 ======

  Future<void> saveUser(Map<String, dynamic> userJson) async {
    await put(_userBox, userJson['id'] as String, userJson);
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    return get(_userBox, userId);
  }

  Future<void> setCurrentUser(String userId) async {
    final box = Hive.box<Map>(_settingsBox);
    await box.put(_currentUserKey, {'id': userId});
  }

  Future<String?> getCurrentUserId() async {
    final box = Hive.box<Map>(_settingsBox);
    final value = box.get(_currentUserKey);
    if (value == null) return null;
    return (value['id'] as String?);
  }

  Future<void> setAuthToken(String? token) async {
    final box = Hive.box<Map>(_settingsBox);
    if (token == null) {
      await box.delete(_authTokenKey);
    } else {
      await box.put(_authTokenKey, {'token': token});
    }
  }

  Future<String?> getAuthToken() async {
    final box = Hive.box<Map>(_settingsBox);
    final value = box.get(_authTokenKey);
    if (value == null) return null;
    return value['token'] as String?;
  }

  // ====== 题目相关 ======

  Future<void> saveQuestion(Map<String, dynamic> q) async {
    await put(_questionBox, q['id'] as String, q);
  }

  Future<void> saveQuestions(List<Map<String, dynamic>> questions) async {
    final box = Hive.box<Map>(_questionBox);
    final batch = <String, Map>{};
    for (final q in questions) {
      batch[q['id'] as String] = q;
    }
    await box.putAll(batch);
  }

  Future<Map<String, dynamic>?> getQuestion(String id) async {
    return get(_questionBox, id);
  }

  Future<List<Map<String, dynamic>>> getQuestionsByLevel(String level) async {
    final all = await getAll(_questionBox);
    return all.where((q) => q['level'] == level).toList();
  }

  Future<List<Map<String, dynamic>>> getQuestionsByType(String type) async {
    final all = await getAll(_questionBox);
    return all.where((q) => q['type'] == type).toList();
  }

  // ====== 解析相关 ======

  Future<void> saveExplanation(Map<String, dynamic> e) async {
    await put(_explanationBox, e['id'] as String, e);
  }

  Future<Map<String, dynamic>?> getExplanation(String id) async {
    return get(_explanationBox, id);
  }

  Future<Map<String, dynamic>?> getExplanationByQuestion(
      String questionId) async {
    final all = await getAll(_explanationBox);
    try {
      return all.firstWhere((e) => e['questionId'] == questionId);
    } catch (_) {
      return null;
    }
  }

  // ====== 考试记录 ======

  Future<void> saveExamRecord(Map<String, dynamic> r) async {
    await put(_examRecordBox, r['id'] as String, r);
  }

  Future<List<Map<String, dynamic>>> getExamRecordsByUser(String userId) async {
    final all = await getAll(_examRecordBox);
    return all.where((r) => r['userId'] == userId).toList()
      ..sort((a, b) {
        final ad = a['completedAt'] as String?;
        final bd = b['completedAt'] as String?;
        if (ad == null || bd == null) return 0;
        return bd.compareTo(ad);
      });
  }

  // ====== 复习项 ======

  Future<void> saveReviewItem(Map<String, dynamic> r) async {
    await put(_reviewItemBox, r['id'] as String, r);
  }

  Future<List<Map<String, dynamic>>> getReviewItemsByUser(String userId) async {
    final all = await getAll(_reviewItemBox);
    return all.where((r) => r['userId'] == userId).toList();
  }

  Future<Map<String, dynamic>?> getReviewItemByQuestion(
      String userId, String questionId) async {
    final items = await getReviewItemsByUser(userId);
    try {
      return items.firstWhere((r) => r['questionId'] == questionId);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getDueReviewItems(String userId) async {
    final items = await getReviewItemsByUser(userId);
    final now = DateTime.now().toIso8601String();
    return items.where((r) {
      final next = r['nextReviewAt'] as String?;
      return next == null || next.compareTo(now) <= 0;
    }).toList();
  }

  // ====== 序列化辅助 ======

  /// 编码为 JSON 字符串（便于跨 Box 调试或导出）
  String encodeJson(Map<String, dynamic> data) => jsonEncode(data);

  /// 解码 JSON 字符串
  Map<String, dynamic> decodeJson(String text) =>
      jsonDecode(text) as Map<String, dynamic>;

  /// 关闭所有 Box（用于测试或登出后清理）
  Future<void> close() async {
    final names = [
      _userBox,
      _questionBox,
      _explanationBox,
      _examRecordBox,
      _reviewItemBox,
      _settingsBox,
    ];
    for (final name in names) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box<Map>(name).close();
      }
    }
    _initialized = false;
  }

  /// 完全清空（登出场景）
  Future<void> clearAll() async {
    await clearBox(_userBox);
    await clearBox(_questionBox);
    await clearBox(_explanationBox);
    await clearBox(_examRecordBox);
    await clearBox(_reviewItemBox);
    await clearBox(_settingsBox);
  }
}
