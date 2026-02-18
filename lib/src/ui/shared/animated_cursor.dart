import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:xterm/xterm.dart';

class AnimatedCursorTerminalView extends StatefulWidget {
  const AnimatedCursorTerminalView({
    super.key,
    required this.terminal,
    this.controller,
    this.theme = TerminalThemes.defaultTheme,
    this.textStyle = const TerminalStyle(),
    this.textScaler,
    this.padding,
    this.scrollController,
    this.autoResize = true,
    this.backgroundOpacity = 1,
    this.focusNode,
    this.autofocus = false,
    this.onTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapUp,
    this.mouseCursor = SystemMouseCursors.text,
    this.keyboardType = TextInputType.emailAddress,
    this.keyboardAppearance = Brightness.dark,
    this.cursorType = TerminalCursorType.block,
    this.alwaysShowCursor = false,
    this.deleteDetection = false,
    this.shortcuts,
    this.onKeyEvent,
    this.readOnly = false,
    this.hardwareKeyboardOnly = false,
    this.simulateScroll = true,
  });

  final Terminal terminal;
  final TerminalController? controller;
  final TerminalTheme theme;
  final TerminalStyle textStyle;
  final TextScaler? textScaler;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final bool autoResize;
  final double backgroundOpacity;
  final FocusNode? focusNode;
  final bool autofocus;
  final void Function(TapUpDetails, CellOffset)? onTapUp;
  final void Function(TapDownDetails, CellOffset)? onSecondaryTapDown;
  final void Function(TapUpDetails, CellOffset)? onSecondaryTapUp;
  final MouseCursor mouseCursor;
  final TextInputType keyboardType;
  final Brightness keyboardAppearance;
  final TerminalCursorType cursorType;
  final bool alwaysShowCursor;
  final bool deleteDetection;
  final Map<ShortcutActivator, Intent>? shortcuts;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool readOnly;
  final bool hardwareKeyboardOnly;
  final bool simulateScroll;

  @override
  State<AnimatedCursorTerminalView> createState() =>
      _AnimatedCursorTerminalViewState();
}

class _AnimatedCursorTerminalViewState extends State<AnimatedCursorTerminalView>
    with TickerProviderStateMixin {
  late TerminalController _controller;
  late ScrollController _scrollController;
  late FocusNode _focusNode;

  // Animation state
  late AnimationController _cursorXController;
  late AnimationController _cursorYController;
  late Animation<double> _cursorXAnimation;
  late Animation<double> _cursorYAnimation;

  double _currentCursorX = 0;
  double _currentCursorY = 0;

  Size _cellSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TerminalController();
    _scrollController = widget.scrollController ?? ScrollController();
    _focusNode = widget.focusNode ?? FocusNode();

    _cursorXController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _cursorYController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));

    _cursorXAnimation =
        Tween<double>(begin: 0, end: 0).animate(_cursorXController);
    _cursorYAnimation =
        Tween<double>(begin: 0, end: 0).animate(_cursorYController);

    widget.terminal.addListener(_onTerminalChanged);

    // Initial measurement
    _updateCellSize();
  }

  @override
  void didUpdateWidget(covariant AnimatedCursorTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller = widget.controller ?? TerminalController();
    }
    if (widget.scrollController != oldWidget.scrollController) {
      _scrollController = widget.scrollController ?? ScrollController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode = widget.focusNode ?? FocusNode();
    }

    if (widget.textStyle != oldWidget.textStyle ||
        widget.textScaler != oldWidget.textScaler) {
      _updateCellSize();
    }
  }

  @override
  void dispose() {
    widget.terminal.removeListener(_onTerminalChanged);
    _cursorXController.dispose();
    _cursorYController.dispose();
    super.dispose();
  }

  void _onTerminalChanged() {
    if (!mounted) return;

    // We need to synchronize the animation target with the actual terminal cursor position
    _updateCursorTarget();
  }

  void _updateCellSize() {
    // Re-measure cell size based on text style
    final textScaler = widget.textScaler ?? TextScaler.noScaling;
    final textStyle = widget.textStyle.toTextStyle();

    const test = 'mmmmmmmmmm';
    final builder = ParagraphBuilder(textStyle.getParagraphStyle());
    builder.pushStyle(textStyle.getTextStyle(textScaler: textScaler));
    builder.addText(test);
    final paragraph = builder.build();
    paragraph.layout(const ParagraphConstraints(width: double.infinity));

    setState(() {
      _cellSize =
          Size(paragraph.maxIntrinsicWidth / test.length, paragraph.height);
    });
  }

  void _updateCursorTarget() {
    final buffer = widget.terminal.buffer;
    final targetX = buffer.cursorX.toDouble();
    final targetY = buffer.absoluteCursorY.toDouble();

    if (_currentCursorX != targetX) {
      _cursorXAnimation = Tween<double>(
        begin: _currentCursorX,
        end: targetX,
      ).animate(CurvedAnimation(
        parent: _cursorXController,
        curve: Curves.easeOutCubic,
      ));
      _cursorXController.forward(from: 0);
      _currentCursorX = targetX;
    }

    if (_currentCursorY != targetY) {
      _cursorYAnimation = Tween<double>(
        begin: _currentCursorY,
        end: targetY,
      ).animate(CurvedAnimation(
        parent: _cursorYController,
        curve: Curves.easeOutCubic,
      ));
      _cursorYController.forward(from: 0);
      _currentCursorY = targetY;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a modified theme that hides the default cursor
    final modifiedTheme = widget.theme.copyWith(
      cursor: Colors.transparent,
      // Keep other colors same
    );

    // Calculate scroll offset to adjust cursor Y position relative to viewport
    // Note: This is tricky because we need the exact scroll offset from the TerminalView's internal state or controller.
    // However, xterm.dart doesn't easily expose the scroll offset in pixels in a way we can consume synchronously for the overlay without lag.
    // A better approach might be to let TerminalView render everything EXCEPT the cursor, and we render the cursor on top using the SAME coordinate system.
    // But TerminalView manages its own scrollable.

    // Wait, if we wrap TerminalView, we are outside its Scrollable.
    // If we put the cursor overlay *inside* the TerminalView, we need to modify xterm.dart. We can't do that easily without forking.
    // If we put it *over* the TerminalView, we need to match the Scroll position.

    // Fortunately, `TerminalView` takes a `ScrollController`. We can pass one and listen to it!

    return Stack(
      fit: StackFit.expand,
      children: [
        TerminalView(
          widget.terminal,
          controller: _controller,
          theme: modifiedTheme,
          textStyle: widget.textStyle,
          textScaler: widget.textScaler,
          padding: widget.padding,
          scrollController: _scrollController,
          autoResize: widget.autoResize,
          backgroundOpacity: widget.backgroundOpacity,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onTapUp: widget.onTapUp,
          onSecondaryTapDown: widget.onSecondaryTapDown,
          onSecondaryTapUp: widget.onSecondaryTapUp,
          mouseCursor: widget.mouseCursor,
          keyboardType: widget.keyboardType,
          keyboardAppearance: widget.keyboardAppearance,
          cursorType: widget.cursorType,
          alwaysShowCursor: widget.alwaysShowCursor,
          deleteDetection: widget.deleteDetection,
          shortcuts: widget.shortcuts,
          onKeyEvent: widget.onKeyEvent,
          readOnly: widget.readOnly,
          hardwareKeyboardOnly: widget.hardwareKeyboardOnly,
          simulateScroll: widget.simulateScroll,
        ),

        // Animated Cursor Overlay
        if (_cellSize != Size.zero)
          AnimatedBuilder(
            animation: Listenable.merge([
              _cursorXController,
              _cursorYController,
              _scrollController,
              _focusNode
            ]),
            builder: (context, child) {
              if (!_focusNode.hasFocus &&
                  !widget.alwaysShowCursor &&
                  !widget.terminal.cursorVisibleMode) {
                return const SizedBox.shrink();
              }

              // Calculate metrics
              final charWidth = _cellSize.width;
              final charHeight = _cellSize.height;

              // Effective properties from TerminalView logic
              // We need to replicate how TerminalView calculates effective scroll offset.
              // In TerminalView:
              // double get _viewportHeight => size.height - _padding.vertical;
              // double get _maxScrollExtent => max(_terminalHeight - _viewportHeight, 0.0);

              // The scrollController.offset corresponds to pixels.
              // The terminal buffer y is absolute.

              // Cursor Y on screen = (AbsoluteCursorY * CharHeight) - ScrollOffset + PaddingTop

              final scrollOffset =
                  _scrollController.hasClients ? _scrollController.offset : 0.0;
              final paddingTop = widget.padding?.top ?? 0.0;
              final paddingLeft = widget.padding?.left ?? 0.0;

              final cursorX = _cursorXAnimation.value * charWidth + paddingLeft;
              final cursorY = _cursorYAnimation.value * charHeight -
                  scrollOffset +
                  paddingTop;

              // Optimization: specific check for visibility would be good

              return Positioned(
                left: cursorX,
                top: cursorY,
                width: charWidth,
                height: charHeight,
                child: IgnorePointer(
                  child: Container(
                    color: widget.theme.cursor.withValues(
                        alpha:
                            0.5), // Semi-transparent for "trail" look or full opacity?
                    // Kitty cursor usually inverse or block.
                    // Let's stick to simple block for now with the theme color.
                  ),
                ),
              );
            },
          ),

        // The Actual "Head" of the cursor (immediate position) - optional if we want trailing effect.
        // Kitty animation: The cursor block moves smoothly.

        // Wait, if we just animate the position, that IS the smooth cursor.
        // We probably want the main block to be the animated one.

        // But wait, what if the cursor is at the bottom of the screen and we scroll?
        // The ScrollController updates, triggering the builder.
        // _cursorYAnimation value is absolute row index.
        // absolute row index * char height gives total height from top of buffer.
        // minus scroll offset gives relative y.
        // This seems correct.
      ],
    );
  }
}

// Extension to help copyWith on TerminalTheme since it's immutable and might not have copyWith
extension TerminalThemeCopyWith on TerminalTheme {
  TerminalTheme copyWith({
    Color? cursor,
    Color? selection,
    Color? foreground,
    Color? background,
    Color? black,
    Color? white,
    Color? red,
    Color? green,
    Color? yellow,
    Color? blue,
    Color? magenta,
    Color? cyan,
    Color? brightBlack,
    Color? brightRed,
    Color? brightGreen,
    Color? brightYellow,
    Color? brightBlue,
    Color? brightMagenta,
    Color? brightCyan,
    Color? brightWhite,
    Color? searchHitBackground,
    Color? searchHitBackgroundCurrent,
    Color? searchHitForeground,
  }) {
    return TerminalTheme(
      cursor: cursor ?? this.cursor,
      selection: selection ?? this.selection,
      foreground: foreground ?? this.foreground,
      background: background ?? this.background,
      black: black ?? this.black,
      white: white ?? this.white,
      red: red ?? this.red,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      blue: blue ?? this.blue,
      magenta: magenta ?? this.magenta,
      cyan: cyan ?? this.cyan,
      brightBlack: brightBlack ?? this.brightBlack,
      brightRed: brightRed ?? this.brightRed,
      brightGreen: brightGreen ?? this.brightGreen,
      brightYellow: brightYellow ?? this.brightYellow,
      brightBlue: brightBlue ?? this.brightBlue,
      brightMagenta: brightMagenta ?? this.brightMagenta,
      brightCyan: brightCyan ?? this.brightCyan,
      brightWhite: brightWhite ?? this.brightWhite,
      searchHitBackground: searchHitBackground ?? this.searchHitBackground,
      searchHitBackgroundCurrent:
          searchHitBackgroundCurrent ?? this.searchHitBackgroundCurrent,
      searchHitForeground: searchHitForeground ?? this.searchHitForeground,
    );
  }
}
