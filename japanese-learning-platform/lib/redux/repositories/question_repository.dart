/// 题目 Repository - 题库数据访问层
library;

import 'dart:convert';
import 'package:flutter/services.dart';

import '../../core/storage/local_storage_service.dart';
import '../../core/network/api_service.dart';
import '../../utils/asset_manager.dart';
import '../../shared/models/models.dart';

/// 题库 Repository
class QuestionRepository {
  final LocalStorageService _storage;
  final ApiService _api;

  QuestionRepository(this._storage, this._api);

  /// 按等级加载题目
  Future<List<Question>> getQuestionsByLevel(JLPTLevel level) async {
    final assetPath = AssetManager.getQuestionsDataPath(level.name);
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final list = (jsonData['questions'] as List?) ?? const [];
      if (list.isNotEmpty) {
        final questions = list
            .map((j) => Question.fromJson(j as Map<String, dynamic>))
            .toList();
        await _storage.saveQuestions(questions.map((q) => q.toJson()).toList());
        return questions;
      }
    } catch (_) {}

    final jsonList =
        await _storage.getQuestionsByLevel(level.name);
    if (jsonList.isNotEmpty) {
      return jsonList.map((j) => Question.fromJson(j)).toList();
    }
    
    try {
      final resp = await _api.get(
        ApiEndpoints.withParam(
            ApiEndpoints.questionsByLevel, 'level', level.name),
      );
      if (resp.isSuccess && resp.data != null) {
        final list = (resp.data!['questions'] as List?) ?? const [];
        final questions = list
            .map((j) => Question.fromJson(j as Map<String, dynamic>))
            .toList();
        await _storage.saveQuestions(questions.map((q) => q.toJson()).toList());
        return questions;
      }
    } catch (_) {}
    return const [];
  }

  /// 按类型加载题目
  Future<List<Question>> getQuestionsByType(
      JLPTLevel level, QuestionType type) async {
    final all = await getQuestionsByLevel(level);
    return all.where((q) => q.type == type).toList();
  }

  /// 根据 ID 加载题目
  Future<Question?> getQuestionById(String id) async {
    final json = await _storage.getQuestion(id);
    if (json != null) return Question.fromJson(json);
    try {
      final resp = await _api.get(
        ApiEndpoints.withParam(ApiEndpoints.questionById, 'id', id),
      );
      if (resp.isSuccess && resp.data != null) {
        final q = Question.fromJson(resp.data!);
        await _storage.saveQuestion(q.toJson());
        return q;
      }
    } catch (_) {}
    return null;
  }

  /// 加载题目解析
  Future<Explanation?> getExplanationByQuestion(String questionId) async {
    final q = await getQuestionById(questionId);
    if (q == null) return null;
    return getExplanation(q.explanationId);
  }

  /// 加载解析
  Future<Explanation?> getExplanation(String explanationId) async {
    final json = await _storage.getExplanation(explanationId);
    if (json != null) return Explanation.fromJson(json);
    try {
      final resp = await _api.get(
        ApiEndpoints.withParam(
            ApiEndpoints.explanationByQuestion, 'id', explanationId),
      );
      if (resp.isSuccess && resp.data != null) {
        final e = Explanation.fromJson(resp.data!);
        await _storage.saveExplanation(e.toJson());
        return e;
      }
    } catch (_) {}
    return null;
  }
}
