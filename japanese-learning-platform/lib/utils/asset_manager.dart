import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 资源管理工具类
///
/// 提供获取资源路径、加载资源文件的方法，统一处理资源加载错误。
class AssetManager {
  /// 获取等级图标路径
  static String getLevelIconPath(String level) {
    final normalizedLevel = level.toLowerCase();
    return 'assets/images/level_$normalizedLevel.png';
  }

  /// 获取应用 logo 路径
  static String getLogoPath() {
    return 'assets/images/logo.png';
  }

  /// 获取音频文件路径
  static String getAudioPath(String filename) {
    return 'assets/audio/$filename';
  }

  /// 获取题目数据文件路径
  static String getQuestionsDataPath(String level) {
    final normalizedLevel = level.toLowerCase();
    return 'assets/data/questions_$normalizedLevel.json';
  }

  /// 获取解析数据文件路径
  static String getExplanationsDataPath() {
    return 'assets/data/explanations.json';
  }

  /// 加载 JSON 文件
  ///
  /// [path] 资源路径
  /// 返回解析后的 JSON 对象
  /// 如果加载失败返回 null
  static Future<Map<String, dynamic>?> loadJson(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[$AssetManager] 加载 JSON 失败: $path');
      debugPrint('[$AssetManager] 错误: $e');
      return null;
    }
  }

  /// 加载 JSON 数组文件
  ///
  /// [path] 资源路径
  /// 返回解析后的 JSON 列表
  /// 如果加载失败返回空列表
  static Future<List<dynamic>> loadJsonList(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final data = json.decode(jsonString);
      if (data is Map<String, dynamic>) {
        return data['questions'] as List<dynamic>? ?? [];
      }
      return data as List<dynamic>;
    } catch (e) {
      debugPrint('[$AssetManager] 加载 JSON 列表失败: $path');
      debugPrint('[$AssetManager] 错误: $e');
      return [];
    }
  }

  /// 检查资源是否存在
  ///
  /// [path] 资源路径
  /// 返回 true 表示资源存在
  static Future<bool> resourceExists(String path) async {
    try {
      await rootBundle.loadString(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 加载字节数据（用于图片、音频等）
  ///
  /// [path] 资源路径
  /// 返回字节数据
  /// 如果加载失败返回 null
  static Future<ByteData?> loadBytes(String path) async {
    try {
      return await rootBundle.load(path);
    } catch (e) {
      debugPrint('[$AssetManager] 加载字节数据失败: $path');
      debugPrint('[$AssetManager] 错误: $e');
      return null;
    }
  }
}
