/// 键盘快捷键支持
///
/// 为 Web 端提供键盘快捷键功能
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 键盘快捷键管理器
class KeyboardShortcutManager extends StatefulWidget {
  /// 子组件
  final Widget child;

  /// 快捷键映射
  final Map<LogicalKeySet, VoidCallback> shortcuts;

  const KeyboardShortcutManager({
    super.key,
    required this.child,
    required this.shortcuts,
  });

  @override
  State<KeyboardShortcutManager> createState() =>
      _KeyboardShortcutManagerState();
}

class _KeyboardShortcutManagerState extends State<KeyboardShortcutManager> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (node, event) {
        if (event is! RawKeyDownEvent) return KeyEventResult.ignored;

        // 检查是否匹配任何快捷键
        for (final entry in widget.shortcuts.entries) {
          final keySet = entry.key;
          final callback = entry.value;

          if (_matchesKeySet(event, keySet)) {
            callback();
            return KeyEventResult.handled;
          }
        }

        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }

  bool _matchesKeySet(RawKeyDownEvent event, LogicalKeySet keySet) {
    final modifiers = keySet.keys;

    // 检查修饰键
    bool ctrlRequired = modifiers.contains(LogicalKeyboardKey.control);
    bool shiftRequired = modifiers.contains(LogicalKeyboardKey.shift);
    bool altRequired = modifiers.contains(LogicalKeyboardKey.alt);
    bool metaRequired = modifiers.contains(LogicalKeyboardKey.meta);

    bool ctrlPressed = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.controlLeft) ||
        RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.controlRight);
    bool shiftPressed = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.shiftLeft) ||
        RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.shiftRight);
    bool altPressed = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.altLeft) ||
        RawKeyboard.instance.keysPressed.contains(LogicalKeyboardKey.altRight);
    bool metaPressed = RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.metaLeft) ||
        RawKeyboard.instance.keysPressed
            .contains(LogicalKeyboardKey.metaRight);

    if (ctrlRequired != ctrlPressed) return false;
    if (shiftRequired != shiftPressed) return false;
    if (altRequired != altPressed) return false;
    if (metaRequired != metaPressed) return false;

    // 检查主键
    final mainKeys = modifiers.difference({
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    });

    if (mainKeys.length != 1) return false;
    final mainKey = mainKeys.first;

    return event.logicalKey == mainKey;
  }
}

/// 常用快捷键常量
class AppShortcuts {
  /// 首页 (Ctrl/Cmd + 1)
  static final LogicalKeySet goToHome = LogicalKeySet(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.digit1,
  );

  /// 练习 (Ctrl/Cmd + 2)
  static final LogicalKeySet goToPractice = LogicalKeySet(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.digit2,
  );

  /// 复习 (Ctrl/Cmd + 3)
  static final LogicalKeySet goToReview = LogicalKeySet(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.digit3,
  );

  /// 个人中心 (Ctrl/Cmd + 4)
  static final LogicalKeySet goToProfile = LogicalKeySet(
    LogicalKeyboardKey.control,
    LogicalKeyboardKey.digit4,
  );

  /// 返回上一页 (Alt + Left)
  static final LogicalKeySet goBack = LogicalKeySet(
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.arrowLeft,
  );

  /// 前进下一页 (Alt + Right)
  static final LogicalKeySet goForward = LogicalKeySet(
    LogicalKeyboardKey.alt,
    LogicalKeyboardKey.arrowRight,
  );
}
