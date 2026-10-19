import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Source annotations stay attached to their word when text wraps or scrolls.
class AnnotatedNovelText extends StatefulWidget {
  final List<Map<String, dynamic>> tokens;
  const AnnotatedNovelText({super.key, required this.tokens});
  @override
  State<AnnotatedNovelText> createState() => _AnnotatedNovelTextState();
}

class _AnnotatedNovelTextState extends State<AnnotatedNovelText> {
  OverlayEntry? _entry;
  int? _selected;
  final Map<int, LayerLink> _links = {};
  final Map<int, GlobalKey> _keys = {};
  ScrollPosition? _scroll;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (_scroll != scroll) {
      _scroll?.isScrollingNotifier.removeListener(_onScroll);
      _scroll = scroll;
      _scroll?.isScrollingNotifier.addListener(_onScroll);
    }
  }

  void _onScroll() {
    if (_scroll?.isScrollingNotifier.value == true) _hide();
  }

  void _hide({bool rebuild = true}) {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
    if (_selected != null) {
      _selected = null;
      if (rebuild && mounted) setState(() {});
    }
  }

  void _toggle(int index, Map<String, dynamic> token) {
    final same = _selected == index;
    _hide();
    if (same) return;
    final box = _keys[index]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final origin = box.localToGlobal(Offset.zero);
    final size = MediaQuery.sizeOf(context);
    final meaning = token['meaning'].toString();
    final bubbleWidth = math.min(math.min(320.0, size.width - 24),
        math.max(84.0, meaning.runes.length * 20.0 + 32));
    final dx = (box.size.width + 5)
        .clamp(12 - origin.dx,
            math.max(12 - origin.dx, size.width - origin.dx - bubbleWidth - 12))
        .toDouble();
    final below = origin.dy < MediaQuery.paddingOf(context).top + 70;
    setState(() => _selected = index);
    _entry = OverlayEntry(
        builder: (context) => Positioned.fill(
              child: Stack(clipBehavior: Clip.none, children: [
                CompositedTransformFollower(
                  link: _links[index]!,
                  showWhenUnlinked: false,
                  targetAnchor:
                      below ? Alignment.bottomLeft : Alignment.topLeft,
                  followerAnchor:
                      below ? Alignment.topLeft : Alignment.bottomLeft,
                  offset: Offset(dx, below ? 6 : -6),
                  child: TapRegion(
                      groupId: this,
                      onTapOutside: (_) => _hide(),
                      child: Material(
                        elevation: 7,
                        color: const Color(0xff183b45),
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                            width: bubbleWidth,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              child: Semantics(
                                  liveRegion: true,
                                  child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Text(meaning,
                                          maxLines: 1,
                                          softWrap: false,
                                          key: const ValueKey(
                                              'novel-word-meaning'),
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 17,
                                              height: 1.4)))),
                            )),
                      )),
                ),
              ]),
            ));
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  @override
  void didUpdateWidget(covariant AnnotatedNovelText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tokens != widget.tokens) _hide(rebuild: false);
  }

  @override
  void dispose() {
    _scroll?.isScrollingNotifier.removeListener(_onScroll);
    _hide(rebuild: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
          child: Text.rich(
        TextSpan(children: [
          for (var i = 0; i < widget.tokens.length; i++)
            if (widget.tokens[i]['word'] == null)
              TextSpan(text: widget.tokens[i]['text']?.toString() ?? '')
            else
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: TapRegion(
                    groupId: this,
                    child: CompositedTransformTarget(
                      link: _links.putIfAbsent(i, LayerLink.new),
                      child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _toggle(i, widget.tokens[i]),
                            child: Semantics(
                              button: true,
                              label:
                                  '${widget.tokens[i]['word']}，读音${widget.tokens[i]['reading']}，点击查看中文释义',
                              excludeSemantics: true,
                              child: _RubyBaseline(
                                key: _keys.putIfAbsent(i, GlobalKey.new),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      color: _selected == i
                                          ? const Color(0xffd7efed)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 1),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                              widget.tokens[i]['reading']
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  height: 1.15,
                                                  color: Color(0xff347c85))),
                                          Text(
                                              widget.tokens[i]['word']
                                                  .toString(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  height: 1.15,
                                                  color: Color(0xff183b45),
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationStyle:
                                                      TextDecorationStyle
                                                          .dotted,
                                                  decorationColor:
                                                      Color(0xff90bfbd))),
                                        ]),
                                  ),
                                ),
                              ),
                            ),
                          )),
                    )),
              ),
        ]),
        style: const TextStyle(
            fontSize: 20, height: 2.35, color: Color(0xff293c41)),
      ));
}

// A Column normally exposes the reading's baseline. Inline text must instead
// align with the final (base-word) line, so the kana stays above the paragraph.
class _RubyBaseline extends SingleChildRenderObjectWidget {
  const _RubyBaseline({super.key, required super.child});
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderRubyBaseline();
}

class _RenderRubyBaseline extends RenderProxyBox {
  double? _base(RenderBox box, TextBaseline baseline) {
    if (box is RenderFlex && box.lastChild != null) {
      final last = box.lastChild!;
      final data = last.parentData! as FlexParentData;
      return data.offset.dy + (_base(last, baseline) ?? last.size.height);
    }
    if (box is RenderShiftedBox && box.child != null) {
      final c = box.child!;
      final data = c.parentData! as BoxParentData;
      return data.offset.dy + (_base(c, baseline) ?? c.size.height);
    }
    if (box is RenderProxyBox && box.child != null) {
      return _base(box.child!, baseline);
    }
    return box.getDistanceToActualBaseline(baseline);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      child == null ? null : _base(child!, baseline);
}
