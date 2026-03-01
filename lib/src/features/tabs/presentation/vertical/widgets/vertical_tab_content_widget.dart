// ─── Tab Tile ────────────────────────────────────────────────────────────────
import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:terminal_studio/src/features/terminal/presentation/terminal_plugin.dart';
import 'package:terminal_studio/src/features/tabs/presentation/vertical/widgets/simple_tile_content.dart';
import 'package:terminal_studio/src/features/tabs/presentation/vertical/widgets/terminal_tile_content.dart';

class VerticalTabContentWidget extends StatelessWidget {
  const VerticalTabContentWidget({
    super.key,
    required this.terminal,
    required this.isActive,
    required TabItem tab,
  }) : _tab = tab;

  final TerminalPlugin? terminal;
  final bool isActive;
  final TabItem _tab;

  @override
  Widget build(BuildContext context) {
    if (terminal != null) {
      return TerminalTileContent(
        terminal: terminal!,
        isActive: isActive,
      );
    } else {
      return SimpleTileContent(
        tabItem: _tab,
        isActive: isActive,
      );
    }
  }
}
