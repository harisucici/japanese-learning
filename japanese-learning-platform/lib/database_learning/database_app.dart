import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import 'learning_client.dart';
import 'annotated_novel_text.dart';

const _types = <String, String>{
  'kanji': '汉字读音',
  'vocabulary': '词汇',
  'grammar': '语法',
  'reading': '阅读',
  'listening': '听力',
  'fillInBlank': '填空',
  'comprehensive': '综合'
};
String _error(Object e) => e.toString().replaceFirst('Exception: ', '');
String _date(dynamic value) {
  final d = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return d == null
      ? ''
      : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

List<Map<String, dynamic>> _maps(dynamic values) => (values as List? ?? [])
    .map((x) => Map<String, dynamic>.from(x as Map))
    .toList();

class DatabaseLearningApp extends StatefulWidget {
  final LearningClient? client;
  const DatabaseLearningApp({super.key, this.client});
  @override
  State<DatabaseLearningApp> createState() => _DatabaseLearningAppState();
}

class _DatabaseLearningAppState extends State<DatabaseLearningApp> {
  late final LearningClient api = widget.client ?? LearningClient();
  late Future<void> ready = api.initialize();
  late final GoRouter router = GoRouter(initialLocation: '/home', routes: [
    ShellRoute(
        builder: (context, state, child) =>
            _Shell(location: state.uri.path, child: child),
        routes: [
          for (final path in ['/home', '/practice', '/exam/config'])
            GoRoute(path: path, builder: (c, s) => _CatalogPage(api: api)),
          GoRoute(
              path: '/novel', builder: (c, s) => _NovelLessonsPage(api: api)),
          GoRoute(
              path: '/novel/:id',
              builder: (c, s) =>
                  _NovelLessonPage(api: api, id: s.pathParameters['id']!)),
          GoRoute(path: '/fun', builder: (c, s) => _FunPapersPage(api: api)),
          GoRoute(
              path: '/materials', builder: (c, s) => _MaterialsPage(api: api)),
          GoRoute(
              path: '/materials/:id',
              builder: (c, s) =>
                  _MaterialPage(api: api, id: s.pathParameters['id']!)),
          GoRoute(path: '/exams', builder: (c, s) => _ExamPapersPage(api: api)),
          GoRoute(path: '/history', builder: (c, s) => _HistoryPage(api: api)),
          GoRoute(
              path: '/statistics', builder: (c, s) => _HistoryPage(api: api)),
          GoRoute(path: '/review', builder: (c, s) => _MistakesPage(api: api)),
          GoRoute(
              path: '/wrong-book', builder: (c, s) => _MistakesPage(api: api)),
          GoRoute(path: '/profile', builder: (c, s) => _ProfilePage(api: api)),
        ]),
    GoRoute(
        path: '/sessions/:id',
        builder: (c, s) =>
            DatabaseSessionPage(api: api, id: s.pathParameters['id']!)),
    GoRoute(
        path: '/quiz/:level/answer',
        builder: (c, s) =>
            DatabaseSessionPage(api: api, level: s.pathParameters['level']!)),
    GoRoute(
        path: '/quiz/:level',
        builder: (c, s) => _Shell(
            location: '/home',
            child: _CatalogPage(
                api: api, initialLevel: s.pathParameters['level']!))),
  ]);
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, constraints) {
        // Responsive theme switching:
        // - Mobile (< 768px): dark teal theme
        // - Web/Desktop (>= 768px): white light theme
        final isMobile = constraints.maxWidth < 768;
        final themeData = isMobile ? AppTheme.dark : AppTheme.light;

        return MaterialApp.router(
          title: '日本語学習',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          darkTheme: AppTheme.dark,
          themeMode: isMobile ? ThemeMode.dark : ThemeMode.light,
          routerConfig: router,
          builder: (context, child) => FutureBuilder<void>(
              future: ready,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return Scaffold(
                      body: _Message(
                          text: '服务连接失败：${_error(snapshot.error!)}',
                          retry: () => setState(() => ready = api.initialize())));
                }
                return child ?? const SizedBox.shrink();
              }),
        );
      },
    );
}

class _Shell extends StatelessWidget {
  final String location;
  final Widget child;
  const _Shell({required this.location, required this.child});
  @override
  Widget build(BuildContext context) {
    final index = location == '/history' || location == '/statistics'
        ? 1
        : location == '/review' || location == '/wrong-book'
            ? 2
            : location == '/profile'
                ? 3
                : 0;
    return Scaffold(
        body: SafeArea(child: child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) =>
              context.go(['/home', '/history', '/review', '/profile'][i]),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.library_books_outlined), label: '真题库'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: '记录与统计'),
            NavigationDestination(
                icon: Icon(Icons.fact_check_outlined), label: '错题讲解'),
            NavigationDestination(
                icon: Icon(Icons.person_outline), label: '我的'),
          ],
        ));
  }
}

class _Message extends StatelessWidget {
  final String text;
  final VoidCallback? retry;
  const _Message({required this.text, this.retry});
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text, textAlign: TextAlign.center),
            if (retry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: retry, child: const Text('重试'))
            ],
          ])));
}

class _Body extends StatelessWidget {
  final List<Widget> children;
  const _Body({required this.children});
  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              children: children)));
}

Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(subtitle,
          style: const TextStyle(color: Colors.blueGrey, height: 1.6))
    ]));
Widget _card(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(padding: const EdgeInsets.all(20), child: child));

class _CatalogPage extends StatefulWidget {
  final LearningClient api;
  final String initialLevel;
  const _CatalogPage({required this.api, this.initialLevel = 'n5'});
  @override
  State<_CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<_CatalogPage> {
  late String level = widget.initialLevel.toLowerCase();
  late Future<Map<String, dynamic>> data = widget.api.catalog();
  bool starting = false;
  Future<void> start({String? type}) async {
    if (starting) return;
    setState(() => starting = true);
    try {
      final session = await widget.api.start(level, type: type);
      if (mounted) context.go('/sessions/${session['id']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.catalog()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final groups = _maps(s.data!['groups']);
        int count(String l, [String? t]) => groups
            .where((g) => g['level'] == l && (t == null || g['type'] == t))
            .fold<int>(0, (a, g) => a + (g['count'] as int));
        final total = count(level);
        return _Body(children: [
          FilledButton.icon(
              onPressed: () => context.go('/novel'),
              icon: const Icon(Icons.auto_stories_outlined),
              label: const Text('小说词汇 · 看故事做练习')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () => context.go('/fun'),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('趣味闯关 · 素材改编练习')),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () => context.go('/materials'),
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('素材阅读馆 · 原文与音视频')),
          const SizedBox(height: 24),
          _heading('官方真题库', '已核验 ${s.data!['total']} 道题 · 题目、题数与来源均从数据库读取'),
          OutlinedButton.icon(
              onPressed: () => context.go('/exams'),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('完整真题模拟考试')),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in ['n5', 'n4', 'n3', 'n2', 'n1'])
              ChoiceChip(
                  label: Text('${l.toUpperCase()} · ${count(l)} 题'),
                  selected: level == l,
                  onSelected: (_) => setState(() => level = l))
          ]),
          const SizedBox(height: 24),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${level.toUpperCase()} 官方真题练习',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('共 $total 题，满分 100 分。每题以首次作答计分。'),
            const SizedBox(height: 8),
            const Text('答对自动进入下一题；答错查看答案与讲解后手动继续，已答题不可改选。',
                style: TextStyle(height: 1.6)),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: total == 0 || starting ? null : () => start(),
                icon: const Icon(Icons.play_arrow),
                label: Text(starting ? '正在创建练习…' : '开始全部 $total 题')),
          ])),
          const Text('按题型练习',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (final t in _types.entries)
            _card(Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t.value,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                        count(level, t.key) > 0
                            ? '${count(level, t.key)} 道已核验真题'
                            : '暂无已核验题目',
                        style: const TextStyle(color: Colors.blueGrey))
                  ])),
              OutlinedButton(
                  onPressed: count(level, t.key) == 0 || starting
                      ? null
                      : () => start(type: t.key),
                  child: const Text('开始练习'))
            ])),
          const SizedBox(height: 8),
          const Text('来源：日本语能力测试官方问题集第二集（2018 年出版）。出版年份不代表具体考试年份。当前题库用于本机个人学习。',
              style: TextStyle(color: Colors.blueGrey, height: 1.6)),
        ]);
      });
}

class DatabaseSessionPage extends StatefulWidget {
  final LearningClient api;
  final String? id;
  final String? level;
  const DatabaseSessionPage(
      {super.key, required this.api, this.id, this.level});
  @override
  State<DatabaseSessionPage> createState() => _DatabaseSessionPageState();
}

class _DatabaseSessionPageState extends State<DatabaseSessionPage> {
  Map<String, dynamic>? session;
  String? error;
  bool busy = false;
  Timer? _timer;
  bool _syncing = false;
  int _offset = 0;
  void _accept(Map<String, dynamic> s) {
    final now = DateTime.tryParse(s['serverNow']?.toString() ?? '');
    _offset = now == null
        ? 0
        : now.millisecondsSinceEpoch - DateTime.now().millisecondsSinceEpoch;
    setState(() => session = s);
    if (s['examConfig'] != null && _timer == null) _startClock();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final c = session?['examConfig'] as Map?;
      if (!mounted || c == null || session?['completedAt'] != null) return;
      setState(() {});
      if (!_syncing &&
          !busy &&
          c['deadline'] != null &&
          (timer.tick % 10 == 0 ||
              DateTime.parse(c['deadline']).millisecondsSinceEpoch <=
                  DateTime.now().millisecondsSinceEpoch + _offset)) {
        _syncing = true;
        await _resync();
        _syncing = false;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> section(String action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final s = await widget.api.section(session!['id'], action);
      if (mounted) _accept(s);
    } catch (e) {
      if (mounted) setState(() => error = _error(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => error = null);
    try {
      final s = widget.id != null
          ? await widget.api.session(widget.id!)
          : await widget.api.start(widget.level!.toLowerCase());
      if (mounted) {
        _accept(s);
        if (widget.id == null) context.go('/sessions/${s['id']}');
      }
    } catch (e) {
      if (mounted) setState(() => error = _error(e));
    }
  }

  Future<void> choose(String q, String o) async {
    if (busy || session!['awaitingNext'] == true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = await widget.api.answer(session!['id'] as String, q, o);
      if (mounted) _accept(s);
    } catch (e) {
      if (mounted) {
        setState(() => error = _error(e));
        await _resync();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _confirmSection(BuildContext context) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('提交本科目？'),
                content: const Text('提交后不能返回，未作答的题目按错误计分。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('继续考试')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        section('submit');
                      },
                      child: const Text('确认交卷'))
                ]));
  }

  Future<void> _resync() async {
    try {
      final s = await widget.api.session(session!['id']);
      if (mounted) _accept(s);
    } catch (_) {}
  }

  Future<void> next() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final s = await widget.api.next(session!['id'] as String);
      if (mounted) _accept(s);
    } catch (e) {
      if (mounted) {
        setState(() => error = _error(e));
        await _resync();
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = session;
    if (s == null) {
      return Scaffold(
          appBar: AppBar(
              title: const Text('正在加载练习'),
              leading: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back))),
          body: error == null
              ? const Center(child: CircularProgressIndicator())
              : _Message(text: error!, retry: load));
    }
    if (s['completedAt'] != null) return _CompletedPage(session: s);
    final exam = s['examConfig'] as Map?;
    if (exam?['waitingSection'] == true) {
      final next =
          (exam!['sections'] as List)[(exam['sectionIndex'] as int) + 1] as Map;
      return Scaffold(
          appBar: AppBar(title: const Text('本科目已结束')),
          body: _Body(children: [
            _heading('本科目已交卷', '已交卷科目无法返回，未答题按错误计分。'),
            Text('下一科：${next['title']} · ${next['minutes']} 分钟'),
            const SizedBox(height: 20),
            if (error != null) Text(error!),
            FilledButton(
                onPressed: busy ? null : () => section('start'),
                child: const Text('开始下一科')),
          ]));
    }
    final qs = _maps(s['questions']);
    final index = s['currentIndex'] as int;
    final q = qs[index];
    final answers = _maps(s['answers']);
    final current =
        answers.where((a) => a['questionId'] == q['id']).firstOrNull;
    final options = _maps(q['options']);
    final awaiting = s['awaitingNext'] == true;
    final p = q['provenance'] as Map?;
    return Scaffold(
      appBar: AppBar(
          leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back)),
          title: Text('${index + 1} / ${qs.length}'),
          actions: [
            TextButton(
                onPressed: () => _showAnswered(context, qs, answers),
                child: Text('已答 ${answers.length} 题'))
          ]),
      body: _Body(children: [
        if (exam != null) ...[
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                (exam['sections'] as List)[exam['sectionIndex']]['title']
                    .toString(),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('剩余时间：${_remaining(exam['deadline'], _offset)}',
                style: const TextStyle(fontSize: 24, color: Colors.blue)),
            Text(exam['instantFeedback'] == true
                ? '错题立即讲解已开启；查看讲解仍计时。'
                : '严格计时；交卷后统一查看答案和讲解。'),
            TextButton(
                onPressed: busy ? null : () => _confirmSection(context),
                child: const Text('提前提交本科目')),
          ])),
        ],
        if (exam != null &&
            ((exam['sections'] as List)[exam['sectionIndex']]['audioUrl'] ??
                    q['audioUrl']) !=
                null)
          _ExamAudio(
              key: ValueKey((exam['sections'] as List)[exam['sectionIndex']]
                      ['audioUrl'] ??
                  q['audioUrl']),
              url: ((exam['sections'] as List)[exam['sectionIndex']]
                          ['audioUrl'] ??
                      q['audioUrl'])
                  .toString(),
              startedAt: DateTime.parse(exam['sectionStartedAt']),
              offset: _offset),
        LinearProgressIndicator(value: answers.length / qs.length),
        const SizedBox(height: 20),
        if (error != null)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: const TextStyle(color: Colors.red))),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
              '${q['level'] == 'ungraded' ? '素材练习' : q['level'].toString().toUpperCase()} · ${_types[q['type']] ?? q['type']}',
              style: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (q['contentImageUrl'] != null)
            Image.network(q['contentImageUrl'],
                errorBuilder: (_, __, ___) => const Text('题目原图加载失败，请检查源文件')),
          if (p?['kind'] == 'user_material') ...[
            ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: p?['collection'] != 'novel',
                title: Text('原文线索：${p!['title']}'),
                children: [
                  SelectableText(p['passage']?.toString() ?? '',
                      style: const TextStyle(fontSize: 17, height: 1.9))
                ]),
            const SizedBox(height: 12),
          ],
          Text(q['content'] as String,
              style: const TextStyle(fontSize: 20, height: 1.8)),
          if (p != null) ...[
            const SizedBox(height: 16),
            Text(
                p['kind'] == 'user_material'
                    ? '素材改编 · ${p['filename']} 第 ${p['pdfPage']} 页 · 非官方真题'
                    : '官方问题集 ${p['publicationYear']} · PDF 第 ${p['pdfPage']} 页 · 第 ${p['number']} 题',
                style: const TextStyle(fontSize: 12, color: Colors.blueGrey))
          ],
        ])),
        for (var i = 0; i < options.length; i++)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(20),
                    side: BorderSide(
                        color: current != null &&
                                options[i]['id'] == current['correctOptionId']
                            ? Colors.green
                            : current != null &&
                                    options[i]['id'] ==
                                        current['selectedOptionId']
                                ? Colors.red
                                : const Color(0xffdce2ec)),
                    backgroundColor: current != null &&
                            options[i]['id'] == current['correctOptionId']
                        ? const Color(0xffeaf7ef)
                        : current != null &&
                                options[i]['id'] == current['selectedOptionId']
                            ? const Color(0xffffefef)
                            : Colors.white),
                onPressed: busy || current != null
                    ? null
                    : () =>
                        choose(q['id'] as String, options[i]['id'] as String),
                child: Text(
                    '${String.fromCharCode(65 + i)}   ${options[i]['content']}',
                    style: const TextStyle(
                        fontSize: 17, height: 1.5, color: Color(0xff25314a))),
              )),
        if (busy)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator())),
        if (awaiting && current != null) ...[
          _AnswerExplanation(question: q, attempt: current),
          FilledButton.icon(
              onPressed: busy ? null : next,
              icon: const Icon(Icons.arrow_forward),
              label: Text(index + 1 == qs.length ? '查看总分' : '下一题')),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

void _showAnswered(BuildContext context, List<Map<String, dynamic>> qs,
    List<Map<String, dynamic>> answers) {
  showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: _Body(children: [
            _heading('已答记录', '首次答案已锁定，仅可回看。'),
            for (final a in answers)
              _AnswerExplanation(
                  question: qs.firstWhere((q) => q['id'] == a['questionId']),
                  attempt: a)
          ])));
}

class _AnswerExplanation extends StatelessWidget {
  final Map<String, dynamic> question, attempt;
  const _AnswerExplanation({required this.question, required this.attempt});
  @override
  Widget build(BuildContext context) {
    if (!attempt.containsKey('isCorrect')) {
      return _card(const Text('已作答，答案已锁定。交卷后统一查看标准答案与讲解。'));
    }
    final es = attempt['explanation'] as Map?;
    final opts = _maps(question['options']);
    final correct =
        opts.where((o) => o['id'] == attempt['correctOptionId']).firstOrNull;
    final selected =
        opts.where((o) => o['id'] == attempt['selectedOptionId']).firstOrNull;
    final right = attempt['isCorrect'] == true;
    return _card(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(right ? '回答正确' : '回答错误 · 本题已锁定',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: right ? Colors.green : Colors.red)),
      const SizedBox(height: 12),
      Text('你的答案：${selected?['content'] ?? '—'}'),
      const SizedBox(height: 8),
      Text('正确答案：${correct?['content'] ?? '—'}',
          style: const TextStyle(
              color: Colors.green, fontWeight: FontWeight.w600)),
      const Divider(height: 32),
      const Text('学习讲解', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
          es?['sentenceStructure']?.toString().isNotEmpty == true
              ? es!['sentenceStructure'].toString()
              : '该题暂未收录讲解',
          style: const TextStyle(fontSize: 16, height: 1.8)),
      if (es?['note'] != null) ...[
        const SizedBox(height: 12),
        Text(es!['note'].toString(),
            style: const TextStyle(
                color: Colors.blueGrey, fontSize: 12, height: 1.6))
      ],
    ]));
  }
}

class _CompletedPage extends StatelessWidget {
  final Map<String, dynamic> session;
  const _CompletedPage({required this.session});
  @override
  Widget build(BuildContext context) {
    final qs = _maps(session['questions']);
    final answers = _maps(session['answers']);
    final wrong = answers.where((a) => a['isCorrect'] == false).toList();
    return Scaffold(
        appBar: AppBar(
            title: const Text('练习结果'),
            leading: IconButton(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back))),
        body: _Body(children: [
          _heading('练习已完成', '总分根据首次作答由后端计算，结果已保存到数据库。'),
          _card(Column(children: [
            Text('${session['score']} / 100 分',
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.blue)),
            const SizedBox(height: 12),
            Text(
                '答对 ${session['correctCount']} / ${session['totalQuestions']} 题 · 答错 ${wrong.length} 题${qs.length > answers.length ? ' · 未答 ${qs.length - answers.length} 题' : ''}'),
            const SizedBox(height: 8),
            const Text('计分方式：答对题数 ÷ 总题数 × 100，四舍五入。')
          ])),
          if (session['mode'] == 'exam')
            const Text('此分数为原始正确率换算的练习分，不是 JLPT 官方量尺成绩。'),
          FilledButton(
              onPressed: () => context.go('/history'),
              child: const Text('查看学习记录')),
          const SizedBox(height: 24),
          Text(wrong.isEmpty ? '本次全部答对' : '本次错题回顾',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final a in wrong) ...[
            Text(qs.firstWhere((q) => q['id'] == a['questionId'])['content'],
                style: const TextStyle(height: 1.6)),
            const SizedBox(height: 8),
            _AnswerExplanation(
                question: qs.firstWhere((q) => q['id'] == a['questionId']),
                attempt: a)
          ],
        ]));
  }
}

class _HistoryPage extends StatefulWidget {
  final LearningClient api;
  const _HistoryPage({required this.api});
  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  late Future<Map<String, dynamic>> data = widget.api.dashboard();
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.dashboard()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data!;
        final sessions = _maps(d['sessions']);
        return _Body(children: [
          _heading('记录与统计', '根据数据库中实际保存的首次作答统计。'),
          _card(Wrap(spacing: 32, runSpacing: 16, children: [
            _stat('已答题数', '${d['totalAnswered']}'),
            _stat(
                '正确率',
                d['accuracy'] == null
                    ? '暂无记录'
                    : '${((d['accuracy'] as num) * 100).toStringAsFixed(1)}%'),
            _stat('完成练习', '${d['completedSessions']}'),
            _stat('答错次数', '${d['wrongCount']}')
          ])),
          if (sessions.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Text('还没有练习记录。完成一次练习后，这里会显示真实成绩。')),
          for (final x in sessions)
            _card(ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    '${x['mode'] == 'fun' ? (x['activityTitle'] ?? '素材练习') : x['level'].toString().toUpperCase()} · ${x['completedAt'] == null ? '进行中' : '已完成'}'),
                subtitle: Text(
                    '${_date(x['createdAt'])}\n已答 ${x['answeredCount']} / ${x['totalQuestions']} 题',
                    style: const TextStyle(height: 1.8)),
                trailing: Text(
                    x['completedAt'] == null ? '继续' : '${x['score']} 分',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w600)),
                onTap: () => context.go('/sessions/${x['id']}'))),
        ]);
      });
}

Widget _stat(String label, String value) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.w700, color: Colors.blue)),
      Text(label, style: const TextStyle(color: Colors.blueGrey))
    ]);

class _MistakesPage extends StatefulWidget {
  final LearningClient api;
  const _MistakesPage({required this.api});
  @override
  State<_MistakesPage> createState() => _MistakesPageState();
}

class _MistakesPageState extends State<_MistakesPage> {
  late Future<Map<String, dynamic>> data = widget.api.mistakes();
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.mistakes()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final items = _maps(s.data!['items']);
        return _Body(children: [
          _heading('错题讲解', '${items.length} 次真实错答 · 首次答案不可修改，此处仅供回看。'),
          if (items.isEmpty)
            const Padding(
                padding: EdgeInsets.all(24), child: Text('目前没有错题记录。')),
          for (final a in items) ...[
            Text(
                '${_date(a['answeredAt'])} · ${a['question']['level'] == 'ungraded' ? '素材练习' : a['question']['level'].toString().toUpperCase()}',
                style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 8),
            Text(a['question']['content'],
                style: const TextStyle(fontSize: 17, height: 1.8)),
            const SizedBox(height: 12),
            _AnswerExplanation(
                question: Map<String, dynamic>.from(a['question']),
                attempt: {...a, 'correctOptionId': a['question']['answer']}),
          ],
        ]);
      });
}

class _ProfilePage extends StatefulWidget {
  final LearningClient api;
  const _ProfilePage({required this.api});
  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  late Future<Map<String, dynamic>> data = widget.api.dashboard();
  Future<void> login() async {
    final email = TextEditingController();
    final password = TextEditingController();
    final credentials = await showDialog<List<String>>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('登录已有账号'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: email,
                      decoration: const InputDecoration(labelText: '邮箱')),
                  TextField(
                      controller: password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: '密码'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, [email.text, password.text]),
                      child: const Text('登录'))
                ]));
    // Controllers are owned by the dialog until its dismissal animation completes.
    if (credentials == null) return;
    try {
      await widget.api.login(credentials[0], credentials[1]);
      if (mounted) setState(() => data = widget.api.dashboard());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.dashboard()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final d = s.data!;
        final user = d['user'] as Map;
        return _Body(children: [
          _heading('我的学习', user['name'].toString()),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('账号 ID：${user['id']}'),
            const SizedBox(height: 8),
            Text('创建时间：${_date(user['createdAt'])}'),
            const SizedBox(height: 16),
            Text(
                '已答 ${d['totalAnswered']} 题 · 完成 ${d['completedSessions']} 次练习'),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: login, child: const Text('登录已有账号'))
          ])),
          const Text('所有题目、讲解、作答记录和成绩均读取后端数据库。服务不可用时会显示错误，不会替换为模拟数据。',
              style: TextStyle(height: 1.8, color: Colors.blueGrey)),
        ]);
      });
}

String _remaining(dynamic deadline, int offset) {
  if (deadline == null) return '—';
  final seconds = ((DateTime.parse(deadline.toString()).millisecondsSinceEpoch -
              DateTime.now().millisecondsSinceEpoch -
              offset) /
          1000)
      .ceil()
      .clamp(0, 100000);
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}

class _ExamPapersPage extends StatefulWidget {
  final LearningClient api;
  const _ExamPapersPage({required this.api});
  @override
  State<_ExamPapersPage> createState() => _ExamPapersPageState();
}

class _ExamPapersPageState extends State<_ExamPapersPage> {
  late Future<Map<String, dynamic>> data = widget.api.papers();
  String level = 'n5';
  bool feedback = false;
  bool busy = false;
  Future<void> start(Map<String, dynamic> p) async {
    setState(() => busy = true);
    try {
      final s = await widget.api.startExam(level, p['id'], feedback);
      if (mounted) context.go('/sessions/${s['id']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.papers()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final papers =
            _maps(s.data!['papers']).where((p) => p['level'] == level).toList();
        final rules = _maps((s.data!['rules'] as Map)[level]);
        return _Body(children: [
          _heading('完整真题模拟考试', '只开放已核验完整试卷。科目计时由后端保存，刷新不会重置。'),
          Wrap(spacing: 8, children: [
            for (final l in ['n5', 'n4', 'n3', 'n2', 'n1'])
              ChoiceChip(
                  label: Text(l.toUpperCase()),
                  selected: level == l,
                  onSelected: (_) => setState(() => level = l))
          ]),
          const SizedBox(height: 20),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('现行 JLPT 官方科目时长',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            for (final r in rules)
              Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${r['title']}：${r['minutes']} 分钟')),
            const SizedBox(height: 12),
            const Text('有考试年月的历年卷使用对应时期规则；科目之间不结转剩余时间。',
                style: TextStyle(color: Colors.blueGrey))
          ])),
          CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('答错后立即显示答案和讲解'),
              subtitle: const Text('默认关闭，交卷后统一查看。开启后查看讲解仍计入本科目时间，首次答案不可修改。'),
              value: feedback,
              onChanged: (value) => setState(() => feedback = value ?? false)),
          const SizedBox(height: 20),
          if (!papers.any((p) => p['ready'] == true))
            _card(const Text(
                '当前没有通过完整性校验的整卷。JLPT 官方公开的是历次真题选编，不是逐年原卷。缺少语法、阅读、听力或标准答案的资料不能开始整卷考试。',
                style: TextStyle(height: 1.8))),
          for (final p in papers)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p['verificationNote'], style: const TextStyle(height: 1.6)),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed:
                      p['ready'] == true && !busy ? () => start(p) : null,
                  child: Text(p['ready'] == true ? '开始整卷考试' : '材料待完整入库'))
            ])),
          TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('返回真题练习')),
        ]);
      });
}

class _ExamAudio extends StatefulWidget {
  final String url;
  final DateTime startedAt;
  final int offset;
  const _ExamAudio(
      {super.key,
      required this.url,
      required this.startedAt,
      required this.offset});
  @override
  State<_ExamAudio> createState() => _ExamAudioState();
}

class _ExamAudioState extends State<_ExamAudio> {
  final player = AudioPlayer();
  String? error;
  bool ended = false;
  @override
  void initState() {
    super.initState();
    play();
  }

  Future<void> play() async {
    try {
      await player.setUrl(widget.url);
      final ms = (DateTime.now().millisecondsSinceEpoch +
              widget.offset -
              widget.startedAt.millisecondsSinceEpoch)
          .clamp(0, 10000000);
      await player.seek(Duration(milliseconds: ms));
      if (mounted) setState(() => error = null);
      await player.play();
      ended = true;
    } catch (_) {
      if (mounted) setState(() => error = '浏览器需要点击后才能播放，或音频暂不可用。计时仍在继续。');
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _card(StreamBuilder<PlayerState>(
      stream: player.playerStateStream,
      builder: (context, s) =>
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('听力原卷音频', style: TextStyle(fontWeight: FontWeight.w700)),
            Text(s.data?.playing == true ? '播放中 · 不提供暂停或倒带' : '音频尚未播放或已结束'),
            if (error != null) ...[
              Text(error!),
              TextButton(
                  onPressed: ended ? null : play,
                  child: const Text('开始听力（从当前考试时间恢复）'))
            ],
          ])));
}

class _FunPapersPage extends StatefulWidget {
  final LearningClient api;
  const _FunPapersPage({required this.api});
  @override
  State<_FunPapersPage> createState() => _FunPapersPageState();
}

class _FunPapersPageState extends State<_FunPapersPage> {
  late Future<Map<String, dynamic>> data = widget.api.funPapers();
  String? starting;
  String? theme;
  Future<void> start(String id) async {
    if (starting != null) return;
    setState(() => starting = id);
    try {
      final s = await widget.api.startFun(id);
      if (mounted) context.go('/sessions/${s['id']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    } finally {
      if (mounted) setState(() => starting = null);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.funPapers()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final all = _maps(s.data!['papers']);
        final papers =
            all.where((p) => theme == null || p['theme'] == theme).toList();
        final themes = all.map((p) => p['theme'] as String).toSet();
        return _Body(children: [
          _heading('趣味闯关',
              '${all.length} 个题组 · ${all.fold<int>(0, (sum, p) => sum + (p['questionCount'] as int))} 道素材改编题。原文取自你提供的短文，不是 JLPT 真题，也不作等级认证。'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: const Text('全部主题'),
                selected: theme == null,
                onSelected: (_) => setState(() => theme = null)),
            for (final t in themes)
              ChoiceChip(
                  label: Text(t),
                  selected: theme == t,
                  onSelected: (_) => setState(() => theme = t))
          ]),
          const SizedBox(height: 20),
          for (final p in papers)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['theme'],
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(p['title'],
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(p['description'], style: const TextStyle(height: 1.7)),
              const SizedBox(height: 12),
              Text('${p['questionCount']} 题 · 答对自动下一题 · 错题看讲解后继续'),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 8, children: [
                FilledButton(
                    onPressed: starting != null || p['ready'] != true
                        ? null
                        : () => start(p['id']),
                    child: Text(starting == p['id'] ? '正在准备…' : '开始闯关')),
                OutlinedButton(
                    onPressed: () => context
                        .go('/materials/${(p['materialIds'] as List).first}'),
                    child: const Text('先读原文'))
              ]),
            ])),
          OutlinedButton(
              onPressed: () => context.go('/materials'),
              child: const Text('浏览全部学习素材')),
        ]);
      });
}

class _MaterialsPage extends StatefulWidget {
  final LearningClient api;
  const _MaterialsPage({required this.api});
  @override
  State<_MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<_MaterialsPage> {
  late Future<Map<String, dynamic>> data = widget.api.materials();
  String? collection;
  String query = '';
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.materials()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final all = _maps(s.data!['items']);
        final collections = all.map((m) => m['collection'] as String).toSet();
        final items = all
            .where((m) =>
                (collection == null || m['collection'] == collection) &&
                (query.isEmpty ||
                    m['title'].toString().contains(query) ||
                    m['filename'].toString().contains(query)))
            .toList();
        return _Body(children: [
          _heading('素材阅读馆',
              '${s.data!['total']} 份原始 PDF · ${s.data!['audioCount']} 份配套音频 · ${s.data!['videoCount']} 份视频。素材仅用于本机个人学习。'),
          TextField(
              decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search), hintText: '搜索标题或原文件名'),
              onChanged: (v) => setState(() => query = v)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: const Text('全部素材'),
                selected: collection == null,
                onSelected: (_) => setState(() => collection = null)),
            for (final c in collections)
              ChoiceChip(
                  label: Text(c),
                  selected: collection == c,
                  onSelected: (_) => setState(() => collection = c))
          ]),
          const SizedBox(height: 20),
          Text('当前显示 ${items.length} 份'),
          const SizedBox(height: 12),
          for (final m in items)
            _card(ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(m['audioUrl'] != null
                    ? Icons.headphones
                    : Icons.menu_book_outlined),
                title: Text(m['title']),
                subtitle: Text(
                    '${m['filename']} · ${m['pages']} 页\n${m['textStatus'] == 'text_extracted' ? '已提取原文' : m['textStatus'] == 'scan_only' ? '扫描原件' : '词汇注释待核对'}${m['audioUrl'] != null ? ' · 有音频' : ''}${m['videoUrl'] != null ? ' · 有视频' : ''}'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/materials/${m['id']}'))),
        ]);
      });
}

class _MaterialPage extends StatefulWidget {
  final LearningClient api;
  final String id;
  const _MaterialPage({required this.api, required this.id});
  @override
  State<_MaterialPage> createState() => _MaterialPageState();
}

class _MaterialPageState extends State<_MaterialPage> {
  late Future<Map<String, dynamic>> data = widget.api.material(widget.id);
  Future<void> open(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) throw Exception('文件无法打开');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () =>
                  setState(() => data = widget.api.material(widget.id)));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final m = s.data!;
        final meta = m['metadata'] as Map;
        return _Body(children: [
          TextButton.icon(
              onPressed: () => context.go('/materials'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回素材库')),
          _heading(m['title'], '${m['filename']} · ${m['pages']} 页 · 用户提供素材'),
          if (m['textStatus'] == 'novel_lessons') ...[
            FilledButton.icon(
                onPressed: () => context.go('/novel'),
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('进入小说词汇 · 分章阅读与练习')),
            const SizedBox(height: 12),
          ],
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: () => open(m['fileUrl']),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('查看原 PDF')),
            if (m['videoUrl'] != null)
              OutlinedButton.icon(
                  onPressed: () => open(m['videoUrl']),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('播放配套视频'))
          ]),
          const SizedBox(height: 20),
          if (m['audioUrl'] != null) _StudyAudio(url: m['audioUrl']),
          if (m['japanese']?.toString().isNotEmpty == true)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('日语原文',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SelectableText(m['japanese'],
                  style: const TextStyle(fontSize: 20, height: 2))
            ])),
          if (m['translation']?.toString().isNotEmpty == true)
            _card(ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text('展开中文译文（原材料）'),
                children: [
                  SelectableText(m['translation'],
                      style: const TextStyle(fontSize: 16, height: 1.8))
                ])),
          if (m['textStatus'] == 'scan_only')
            _card(const Text(
                '这份材料是扫描 PDF，目前保留原件供阅读，未把未经核对的识别结果用于出题。可点击上方“查看原 PDF”。',
                style: TextStyle(height: 1.8))),
          if (meta['note'] != null)
            _card(Text(meta['note'], style: const TextStyle(height: 1.8))),
          if (meta['attribution'] != null) Text('原作者：${meta['attribution']}'),
          const SizedBox(height: 16),
          Text('原文件校验值：${m['sha256']}',
              style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
        ]);
      });
}

class _StudyAudio extends StatefulWidget {
  final String url;
  const _StudyAudio({required this.url});
  @override
  State<_StudyAudio> createState() => _StudyAudioState();
}

class _StudyAudioState extends State<_StudyAudio> {
  final player = AudioPlayer();
  String? error;
  bool ready = false;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        error = null;
        ready = false;
      });
    }
    try {
      await player.setUrl(widget.url);
      if (mounted) setState(() => ready = true);
    } catch (_) {
      if (mounted) setState(() => error = '音频加载失败，请重试');
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('配套音频',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        if (error != null) TextButton(onPressed: load, child: Text(error!)),
        StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, s) => Wrap(spacing: 12, children: [
                  FilledButton.icon(
                      onPressed: !ready
                          ? null
                          : () {
                              if (player.playing) {
                                player.pause();
                              } else {
                                player.play();
                              }
                            },
                      icon: Icon(s.data?.playing == true
                          ? Icons.pause
                          : Icons.play_arrow),
                      label: Text(!ready
                          ? '加载中…'
                          : s.data?.playing == true
                              ? '暂停'
                              : '播放')),
                  OutlinedButton(
                      onPressed: !ready
                          ? null
                          : () {
                              player.seek(Duration.zero);
                              player.play();
                            },
                      child: const Text('重新听'))
                ])),
        StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, s) {
              final max = (player.duration?.inMilliseconds ?? 0).toDouble();
              final value =
                  (s.data?.inMilliseconds ?? 0).toDouble().clamp(0.0, max);
              return Slider(
                  value: value,
                  max: max > 0 ? max : 1,
                  onChanged: !ready
                      ? null
                      : (v) => player.seek(Duration(milliseconds: v.toInt())));
            }),
      ]));
}

class _NovelLessonsPage extends StatefulWidget {
  final LearningClient api;
  const _NovelLessonsPage({required this.api});
  @override
  State<_NovelLessonsPage> createState() => _NovelLessonsPageState();
}

class _NovelLessonsPageState extends State<_NovelLessonsPage> {
  late Future<Map<String, dynamic>> data = widget.api.novelLessons();
  String? category;
  String query = '';
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () => setState(() => data = widget.api.novelLessons()));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final all = _maps(s.data!['lessons']);
        final lessons = all
            .where((l) =>
                (category == null || l['category'] == category) &&
                l['title'].toString().contains(query))
            .toList();
        final categories = all.map((l) => l['category'] as String).toSet();
        return _Body(children: [
          _heading('小说词汇',
              '看故事，再把词语记住。${all.length} 篇 · ${all.fold<int>(0, (n, l) => n + (l['questionCount'] as int))} 道素材练习'),
          Text(
              '来源：${s.data!['sourceTitle'] ?? '用户提供资料'} · ${s.data!['sourcePages']} 页\n原作者：${s.data!['attribution']}',
              style: const TextStyle(color: Colors.blueGrey, height: 1.7)),
          const SizedBox(height: 12),
          _card(const Text(
              '按原文分章阅读，配套原文记忆与注释对应练习。资料标题中的 N1 为原作者标注；本板块不是官方真题，也不认证词汇等级。',
              style: TextStyle(height: 1.8))),
          TextField(
              decoration: const InputDecoration(
                  labelText: '搜索小说标题', prefixIcon: Icon(Icons.search)),
              onChanged: (v) => setState(() => query = v.trim())),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            ChoiceChip(
                label: const Text('全部篇目'),
                selected: category == null,
                onSelected: (_) => setState(() => category = null)),
            for (final c in categories)
              ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c))
          ]),
          const SizedBox(height: 18),
          if (lessons.isEmpty) const Text('没有找到对应篇目。'),
          for (final l in lessons)
            _card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l['category']} · 第 ${l['startPage']}–${l['endPage']} 页',
                  style: const TextStyle(color: Colors.blueGrey)),
              const SizedBox(height: 8),
              Text(l['title'],
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text('${l['questionCount']} 道练习 · ${l['vocabularyCount']} 个原文词卡'),
              const SizedBox(height: 14),
              FilledButton.icon(
                  onPressed: () => context.go('/novel/${l['id']}'),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('阅读与练习')),
            ])),
        ]);
      });
}

class _NovelLessonPage extends StatefulWidget {
  final LearningClient api;
  final String id;
  const _NovelLessonPage({required this.api, required this.id});
  @override
  State<_NovelLessonPage> createState() => _NovelLessonPageState();
}

class _NovelLessonPageState extends State<_NovelLessonPage> {
  late Future<Map<String, dynamic>> data = widget.api.novelLesson(widget.id);
  int pageIndex = 0;
  bool starting = false;
  Future<void> start(String paperId) async {
    if (starting) return;
    setState(() => starting = true);
    try {
      final s = await widget.api.startFun(paperId);
      if (mounted) context.go('/sessions/${s['id']}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_error(e))));
      }
    } finally {
      if (mounted) setState(() => starting = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
      future: data,
      builder: (context, s) {
        if (s.hasError) {
          return _Message(
              text: _error(s.error!),
              retry: () =>
                  setState(() => data = widget.api.novelLesson(widget.id)));
        }
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final l = s.data!;
        final pages = _maps(l['pages']);
        final vocabulary = _maps(l['vocabulary']);
        final p = pages[pageIndex];
        final material = l['material'] as Map;
        return _Body(children: [
          TextButton.icon(
              onPressed: () => context.go('/novel'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('返回小说词汇')),
          _heading(l['title'], '${l['category']} · ${l['questionCount']} 道练习'),
          Wrap(spacing: 12, runSpacing: 8, children: [
            FilledButton.icon(
                onPressed: starting || l['published'] != true
                    ? null
                    : () => start(l['paperId']),
                icon: const Icon(Icons.edit_note),
                label: Text(starting ? '正在准备…' : '开始本篇练习')),
            OutlinedButton.icon(
                onPressed: () => launchUrl(
                    Uri.parse('${material['fileUrl']}#page=${p['number']}')),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: const Text('查看原 PDF')),
          ]),
          const SizedBox(height: 14),
          Text(l['note'],
              style: const TextStyle(color: Colors.blueGrey, height: 1.7)),
          const SizedBox(height: 18),
          _card(ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('本篇词卡（${vocabulary.length}）'),
              subtitle: const Text('先阅读，再展开回顾'),
              children: [
                for (final v in vocabulary)
                  ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(v['word'],
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                          '${v['meaning'] == null ? '原文记忆词' : '材料原注：${v['meaning']}'} · 第 ${v['sourcePage']} 页\n${v['excerpt']}',
                          style: const TextStyle(height: 1.7)))
              ])),
          Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton(
                    onPressed: pageIndex == 0
                        ? null
                        : () => setState(() => pageIndex--),
                    child: const Text('上一页')),
                DropdownButton<int>(
                    value: pageIndex,
                    items: [
                      for (var i = 0; i < pages.length; i++)
                        DropdownMenuItem(
                            value: i,
                            child: Text(
                                '第 ${pages[i]['number']} 页${pages[i]['recall'] == true ? ' · 回忆版' : ''}'))
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => pageIndex = v);
                    }),
                OutlinedButton(
                    onPressed: pageIndex + 1 == pages.length
                        ? null
                        : () => setState(() => pageIndex++),
                    child: const Text('下一页')),
              ]),
          const SizedBox(height: 12),
          if (p['readingTokens'] != null)
            const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('假名标在词语上方，点击词语查看中文释义。',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13))),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                p['recall'] == true
                    ? '背诵回忆版 · 原材料'
                    : '原文阅读 · 第 ${p['number']} 页',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: Colors.blueGrey)),
            const SizedBox(height: 16),
            if (p['imageUrl'] != null) ...[
              Image.network(p['imageUrl'],
                  key: ValueKey(p['imageUrl']),
                  errorBuilder: (_, __, ___) =>
                      const Text('原页图片加载失败，请查看原 PDF')),
              ExpansionTile(title: const Text('展开可复制文本（图片内故事见原页）'), children: [
                SelectableText(p['text'],
                    style: const TextStyle(fontSize: 18, height: 1.9))
              ]),
            ] else if (p['readingTokens'] != null)
              AnnotatedNovelText(
                  key: ValueKey(p['number']), tokens: _maps(p['readingTokens']))
            else
              SelectableText(p['text'],
                  key: ValueKey(p['number']),
                  style: const TextStyle(fontSize: 19, height: 2)),
          ])),
          Text(
              '出处：${material['filename']} · 第 ${p['number']} 页\n原作者：@叫我とうさん（小红书号：508109733）',
              style: const TextStyle(
                  fontSize: 12, color: Colors.blueGrey, height: 1.7)),
        ]);
      });
}
