import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:japanese_learning_platform/core/network/api_service.dart';
import 'package:japanese_learning_platform/core/storage/local_storage_service.dart';
import 'package:japanese_learning_platform/features/quiz/presentation/pages/quiz_answer_page.dart';
import 'package:japanese_learning_platform/redux/redux.dart';

class TestStorage extends LocalStorageService {
  final Completer<void>? gate;
  final bool failRead;
  TestStorage({this.gate, this.failRead = false});
  @override
  Future<void> saveQuestions(List<Map<String, dynamic>> questions) async {
    if (gate != null) await gate!.future;
  }
  @override
  Future<List<Map<String, dynamic>>> getQuestionsByLevel(String level) async {
    if (failRead) throw StateError('Storage unavailable');
    return [];
  }
}
class OfflineApi implements ApiService {
  @override
  Future<ApiResponse<Map<String, dynamic>>> get(String path,
      {Map<String, dynamic>? queryParameters}) async =>
      const ApiResponse(code: 503, message: 'offline');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final entry in {'n1':25, 'n2':32, 'n3':35, 'n4':35, 'n5':35}.entries) {
    testWidgets('${entry.key} starts after loading takes more than 100ms', (tester) async {
      final assetPath = 'assets/data/questions_${entry.key}.json';
      rootBundle.evict(assetPath);
      final fixture = jsonDecode(File(assetPath).readAsStringSync()) as Map<String, dynamic>;
      for (final q in fixture['questions'] as List) {
        (q as Map).remove('provenance');
        q.remove('tags');
      }
      final bytes = ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(fixture))));
      tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
        final name = utf8.decode(message!.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
        return name == assetPath ? bytes : null;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
        rootBundle.evict(assetPath);
      });
      final gate = Completer<void>();
      final store = createStore(storageService: TestStorage(gate: gate), apiService: OfflineApi());
      await tester.pumpWidget(StoreProvider<AppState>(store: store,
          child: MaterialApp(home: QuizAnswerPage(level: entry.key))));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('1 / ${entry.value}'), findsOneWidget);
      expect(store.state.quizSession.session!.questions.length, entry.value);
      expect(store.state.quizSession.session!.questions.every((q) => q.level.name == entry.key), isTrue);
      expect(find.textContaining('选择【】部分的正确读音。'), findsOneWidget);
    });
  }
  testWidgets('empty question bank shows a message and can retry', (tester) async {
    const assetPath = 'assets/data/questions_n5.json';
    rootBundle.evict(assetPath);
    var empty = true;
    final fixture = jsonDecode(File(assetPath).readAsStringSync()) as Map<String, dynamic>;
    final question = Map<String, dynamic>.from((fixture['questions'] as List).first as Map)
      ..remove('provenance')..remove('tags');
    tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
      final payload = empty ? {'questions': []} : {'questions': [question]};
      return ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(payload))));
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.evict(assetPath);
    });
    final store = createStore(storageService: TestStorage(), apiService: OfflineApi());
    await tester.pumpWidget(StoreProvider<AppState>(store: store,
        child: const MaterialApp(home: QuizAnswerPage(level: 'n5'))));
    await tester.pumpAndSettle();
    expect(find.text('该等级暂无可用题目'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    empty = false;
    rootBundle.evict(assetPath);
    await tester.tap(find.text('重新加载'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
  });
  testWidgets('load failure stops the spinner and offers retry', (tester) async {
    const assetPath = 'assets/data/questions_n5.json';
    rootBundle.evict(assetPath);
    tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null);
      rootBundle.evict(assetPath);
    });
    final store = createStore(storageService: TestStorage(failRead: true), apiService: OfflineApi());
    await tester.pumpWidget(StoreProvider<AppState>(store: store,
        child: const MaterialApp(home: QuizAnswerPage(level: 'n5'))));
    await tester.pumpAndSettle();
    expect(find.text('题目加载失败，请重试'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

}
