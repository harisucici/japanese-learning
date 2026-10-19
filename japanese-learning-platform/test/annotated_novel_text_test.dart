import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:japanese_learning_platform/database_learning/annotated_novel_text.dart';

const tokens = <Map<String, dynamic>>[
  {'text': '他昨晚'},
  {'word': '徹夜', 'reading': 'てつや', 'meaning': '熬夜', 'sourceText': '徹夜てつや熬夜'},
  {'text': '，今天想早点休息。'},
];
Widget reader({List<Map<String, dynamic>> data = tokens}) => MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Column(children: [
      const SizedBox(height: 120),
      Padding(
          padding: const EdgeInsets.all(24),
          child: AnnotatedNovelText(tokens: data)),
      TextButton(onPressed: () {}, child: const Text('阅读区之外')),
      const SizedBox(height: 1200),
    ]))));
void main() {
  testWidgets(
      'ruby is above the word and translation appears beside its upper right',
      (tester) async {
    await tester.pumpWidget(reader());
    await tester.pumpAndSettle();
    expect(tester.getRect(find.text('てつや')).bottom,
        lessThanOrEqualTo(tester.getRect(find.text('徹夜')).top));
    expect(find.text('熬夜'), findsNothing);
    final word = tester.getRect(find.text('徹夜'));
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    expect(find.text('熬夜'), findsOneWidget);
    final bubble =
        tester.getRect(find.byKey(const ValueKey('novel-word-meaning')));
    expect(
        bubble.height, lessThan(30)); // Short Chinese gloss stays on one line.
    expect(bubble.left, greaterThan(word.right));
    expect(bubble.bottom, lessThan(word.top));
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    expect(find.text('熬夜'), findsNothing);
  });
  testWidgets('outside taps and scrolling dismiss the word bubble',
      (tester) async {
    await tester.pumpWidget(reader());
    await tester.pumpAndSettle();
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('阅读区之外'));
    await tester.pumpAndSettle();
    expect(find.text('熬夜'), findsNothing);
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    await tester.drag(
        find.byWidgetPredicate((w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.vertical),
        const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(find.text('熬夜'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'bubble stays inside a narrow screen and disappears when reader is removed',
      (tester) async {
    tester.view.physicalSize = const Size(280, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(reader());
    await tester.pumpAndSettle();
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    final bubble =
        tester.getRect(find.byKey(const ValueKey('novel-word-meaning')));
    expect(bubble.right, lessThanOrEqualTo(280));
    expect(bubble.left, greaterThanOrEqualTo(0));
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: Text('另一页'))));
    await tester.pumpAndSettle();
    expect(find.text('熬夜'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('long translations remain one line and can scroll horizontally',
      (tester) async {
    final data = [
      tokens.first,
      {...tokens[1], 'meaning': '整夜不睡觉一直学习工作直到第二天早晨，这是一个较长的中文释义'},
      tokens.last
    ];
    await tester.pumpWidget(reader(data: data));
    await tester.pumpAndSettle();
    await tester.tap(find.text('徹夜'));
    await tester.pumpAndSettle();
    final text =
        tester.widget<Text>(find.byKey(const ValueKey('novel-word-meaning')));
    expect(text.maxLines, 1);
    expect(text.softWrap, isFalse);
    expect(
        tester.getSize(find.byKey(const ValueKey('novel-word-meaning'))).height,
        lessThan(30));
    final scroll = find.byWidgetPredicate((w) =>
        w is SingleChildScrollView && w.scrollDirection == Axis.horizontal);
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('novel-word-meaning')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
