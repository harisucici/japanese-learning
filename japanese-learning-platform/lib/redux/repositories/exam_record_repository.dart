/// 考试记录 Repository
library;

import 'package:uuid/uuid.dart';

import '../../core/storage/local_storage_service.dart';
import '../../shared/models/models.dart';

/// 考试记录 Repository
class ExamRecordRepository {
  final LocalStorageService _storage;
  static const _uuid = Uuid();

  ExamRecordRepository(this._storage);

  /// 保存一次考试/练习记录
  Future<ExamRecord> saveRecord({
    required String userId,
    required JLPTLevel level,
    required ExamRecordType recordType,
    required List<Question> questions,
    required Map<String, String> answers,
    required int durationMs,
    String? setId,
    String? note,
  }) async {
    int correct = 0;
    final answerRecords = <AnswerRecord>[];
    for (final q in questions) {
      final userAns = answers[q.id];
      if (userAns == null) continue;
      final isCorrect = userAns == q.answer;
      if (isCorrect) correct++;
      answerRecords.add(AnswerRecord(
        questionId: q.id,
        userAnswer: userAns,
        isCorrect: isCorrect,
      ));
    }

    final record = ExamRecord(
      id: _uuid.v4(),
      userId: userId,
      level: level,
      recordType: recordType,
      questionIds: questions.map((q) => q.id).toList(),
      answers: answerRecords,
      score: (correct * 100) ~/ questions.length,
      totalQuestions: questions.length,
      correctCount: correct,
      durationMs: durationMs,
      setId: setId,
      note: note,
    );
    await _storage.saveExamRecord(record.toJson());
    return record;
  }

  /// 获取用户历史记录
  Future<List<ExamRecord>> getRecords(String userId) async {
    final list = await _storage.getExamRecordsByUser(userId);
    return list.map((j) => ExamRecord.fromJson(j)).toList();
  }

  /// 根据等级筛选
  Future<List<ExamRecord>> getRecordsByLevel(
      String userId, JLPTLevel level) async {
    final all = await getRecords(userId);
    return all.where((r) => r.level == level).toList();
  }
}
