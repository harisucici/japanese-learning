import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning_platform/database_learning/database_app.dart';
import 'package:japanese_learning_platform/database_learning/learning_client.dart';

// Replays responses captured from the real PostgreSQL-backed API. No runtime fixtures.
class ReplayClient extends LearningClient {
  final Map<String, dynamic> fixture;
  bool fail = false;
  bool correct = false;
  int answerCalls = 0;
  int nextCalls = 0;
  ReplayClient(this.fixture);
  @override
  Future<void> initialize() async {}
  @override
  Future<Map<String, dynamic>> novelLessons() async =>
      jsonDecode(File('test/fixtures/novel-index.json').readAsStringSync());
  @override
  Future<Map<String, dynamic>> novelLesson(String id) async =>
      jsonDecode(File('test/fixtures/novel-lesson.json').readAsStringSync());
  @override
  Future<Map<String, dynamic>> papers() async =>
      jsonDecode(File('test/fixtures/exam-papers.json').readAsStringSync())
          as Map<String, dynamic>;
  @override
  Future<Map<String, dynamic>> catalog() async {
    if (fail) throw Exception('连接失败');
    return fixture['catalog'];
  }

  @override
  Future<Map<String, dynamic>> session(String id) async {
    if (fail) throw Exception('连接失败');
    return fixture['initial'];
  }

  @override
  Future<Map<String, dynamic>> start(String level,
      {String? type, int? limit, String mode = 'practice'}) async {
    if (fail) throw Exception('连接失败');
    return fixture['initial'];
  }

  @override
  Future<Map<String, dynamic>> answer(
      String id, String question, String option) async {
    answerCalls++;
    return fixture[correct ? 'auto' : 'wrong'];
  }

  @override
  Future<Map<String, dynamic>> next(String id) async {
    nextCalls++;
    return fixture['advanced'];
  }
}

void main() {
  final fixture = jsonDecode(
          File('test/fixtures/database-learning.json').readAsStringSync())
      as Map<String, dynamic>;
  testWidgets(
      'database catalog renders actual counts and disables unavailable types',
      (tester) async {
    await tester.pumpWidget(DatabaseLearningApp(client: ReplayClient(fixture)));
    await tester.pumpAndSettle();
    expect(find.textContaining('已核验 162 道题'), findsOneWidget);
    expect(find.text('N5 · 35 题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('a correct answer immediately displays the next question',
      (tester) async {
    final client = ReplayClient(fixture)..correct = true;
    await tester.pumpWidget(MaterialApp(
        home: DatabaseSessionPage(
            api: client, id: fixture['initial']['id'] as String)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('D   あめ'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.textContaining('書いて'), findsOneWidget);
    expect(client.answerCalls, 1);
  });
  testWidgets(
      'a wrong answer shows explanation, stays locked and advances manually',
      (tester) async {
    final client = ReplayClient(fixture);
    await tester.pumpWidget(MaterialApp(
        home: DatabaseSessionPage(
            api: client, id: fixture['initial']['id'] as String)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A   ゆき'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('回答错误 · 本题已锁定'), 200);
    expect(find.text('正确答案：あめ'), findsOneWidget);
    expect(find.text('学习讲解'), findsOneWidget);
    await tester.ensureVisible(find.text('D   あめ'));
    await tester.tap(find.text('D   あめ'));
    await tester.pumpAndSettle();
    expect(client.answerCalls, 1);
    await tester.scrollUntilVisible(find.text('下一题'), 200);
    await tester.tap(find.text('下一题'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    expect(client.nextCalls, 1);
  });
  testWidgets(
      'backend failure displays retry instead of local sample questions',
      (tester) async {
    final client = ReplayClient(fixture)..fail = true;
    await tester.pumpWidget(MaterialApp(
        home: DatabaseSessionPage(
            api: client, id: fixture['initial']['id'] as String)));
    await tester.pumpAndSettle();
    expect(find.text('连接失败'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('あしたは'), findsNothing);
  });
  testWidgets('completion shows the score returned by the database',
      (tester) async {
    final client = ReplayClient({...fixture, 'initial': fixture['completed']});
    await tester.pumpWidget(MaterialApp(
        home: DatabaseSessionPage(
            api: client, id: fixture['completed']['id'] as String)));
    await tester.pumpAndSettle();
    expect(find.text('50 / 100 分'), findsOneWidget);
    expect(find.text('答对 1 / 2 题 · 答错 1 题'), findsOneWidget);
  });
  testWidgets(
      'exam page shows official timing, optional feedback and blocks incomplete papers',
      (tester) async {
    await tester.pumpWidget(DatabaseLearningApp(client: ReplayClient(fixture)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('完整真题模拟考试'));
    await tester.pumpAndSettle();
    expect(find.text('语言知识（文字、词汇）：20 分钟'), findsOneWidget);
    expect(find.text('语言知识（语法）・阅读：40 分钟'), findsOneWidget);
    expect(find.text('听力：30 分钟'), findsOneWidget);
    await tester.scrollUntilVisible(find.byType(CheckboxListTile), 200);
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isFalse);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue);
    await tester.scrollUntilVisible(find.text('材料待完整入库').first, 200);
    final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '材料待完整入库').first);
    expect(button.onPressed, isNull);
  });
  testWidgets('novel board uses database lessons and filters by category',
      (tester) async {
    await tester.pumpWidget(DatabaseLearningApp(client: ReplayClient(fixture)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('小说词汇 · 看故事做练习'));
    await tester.pumpAndSettle();
    expect(find.textContaining('28 篇 · 203 道素材练习'), findsOneWidget);
    await tester.tap(find.text('副词'));
    await tester.pumpAndSettle();
    expect(find.text('诡计多端的男同'), findsOneWidget);
    expect(find.text('校草的粉红小鸡'), findsNothing);
    await tester.ensureVisible(find.text('阅读与练习').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('阅读与练习').first);
    await tester.pumpAndSettle();
    expect(find.text('开始本篇练习'), findsOneWidget);
    expect(find.text('查看原 PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
