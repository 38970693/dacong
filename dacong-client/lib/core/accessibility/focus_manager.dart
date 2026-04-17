import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 焦点管理器
/// 提供统一的焦点管理和键盘导航支持
class FocusManager {
  FocusManager._();

  /// 焦点顺序管理器
  static final Map<String, List<FocusNode>> _focusGroups = {};

  /// 注册焦点组
  static void registerFocusGroup(String groupId, List<FocusNode> nodes) {
    _focusGroups[groupId] = nodes;
  }

  /// 注销焦点组
  static void unregisterFocusGroup(String groupId) {
    _focusGroups.remove(groupId);
  }

  /// 移动到下一个焦点
  static void moveToNext(BuildContext context, String groupId) {
    final nodes = _focusGroups[groupId];
    if (nodes == null || nodes.isEmpty) return;

    final currentFocus = FocusScope.of(context).focusedChild;
    if (currentFocus == null) {
      nodes.first.requestFocus();
      return;
    }

    final currentIndex = nodes.indexWhere((node) => node.hasFocus);
    if (currentIndex == -1 || currentIndex == nodes.length - 1) {
      nodes.first.requestFocus();
    } else {
      nodes[currentIndex + 1].requestFocus();
    }
  }

  /// 移动到上一个焦点
  static void moveToPrevious(BuildContext context, String groupId) {
    final nodes = _focusGroups[groupId];
    if (nodes == null || nodes.isEmpty) return;

    final currentFocus = FocusScope.of(context).focusedChild;
    if (currentFocus == null) {
      nodes.last.requestFocus();
      return;
    }

    final currentIndex = nodes.indexWhere((node) => node.hasFocus);
    if (currentIndex <= 0) {
      nodes.last.requestFocus();
    } else {
      nodes[currentIndex - 1].requestFocus();
    }
  }

  /// 清除所有焦点
  static void clearFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// 请求焦点
  static void requestFocus(FocusNode node) {
    node.requestFocus();
  }
}

/// 焦点顺序 Widget
/// 自动管理子组件的焦点顺序
class FocusOrderScope extends StatefulWidget {
  final String groupId;
  final List<Widget> children;
  final Axis direction;

  const FocusOrderScope({
    super.key,
    required this.groupId,
    required this.children,
    this.direction = Axis.vertical,
  });

  @override
  State<FocusOrderScope> createState() => _FocusOrderScopeState();
}

class _FocusOrderScopeState extends State<FocusOrderScope> {
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    _initializeFocusNodes();
  }

  void _initializeFocusNodes() {
    _focusNodes.clear();
    for (var i = 0; i < widget.children.length; i++) {
      _focusNodes.add(FocusNode());
    }
    FocusManager.registerFocusGroup(widget.groupId, _focusNodes);
  }

  @override
  void dispose() {
    FocusManager.unregisterFocusGroup(widget.groupId);
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            if (HardwareKeyboard.instance.isShiftPressed) {
              FocusManager.moveToPrevious(context, widget.groupId);
            } else {
              FocusManager.moveToNext(context, widget.groupId);
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
              widget.direction == Axis.vertical) {
            FocusManager.moveToNext(context, widget.groupId);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
              widget.direction == Axis.vertical) {
            FocusManager.moveToPrevious(context, widget.groupId);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              widget.direction == Axis.horizontal) {
            FocusManager.moveToNext(context, widget.groupId);
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
              widget.direction == Axis.horizontal) {
            FocusManager.moveToPrevious(context, widget.groupId);
          }
        }
      },
      child: widget.direction == Axis.vertical
          ? Column(
              children: _buildFocusableChildren(),
            )
          : Row(
              children: _buildFocusableChildren(),
            ),
    );
  }

  List<Widget> _buildFocusableChildren() {
    return List.generate(
      widget.children.length,
      (index) => Focus(
        focusNode: _focusNodes[index],
        child: widget.children[index],
      ),
    );
  }
}

/// 可聚焦按钮
/// 提供完整的键盘导航支持
class FocusableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool autofocus;

  const FocusableButton({
    super.key,
    required this.child,
    this.onPressed,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onPressed?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: _isFocused
            ? BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: widget.child,
      ),
    );
  }
}

/// 可聚焦卡片
/// 为卡片组件提供焦点指示器
class FocusableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const FocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
  });

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            widget.onTap?.call();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          border: _isFocused
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                )
              : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
