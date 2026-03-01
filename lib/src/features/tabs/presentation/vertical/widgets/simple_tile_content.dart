// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SimpleTileContent extends StatelessWidget {
  const SimpleTileContent({
    super.key,
    required this.tabItem,
    required this.isActive,
  });

  final TabItem tabItem;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Widget?>(
      valueListenable: tabItem.title,
      builder: (context, titleWidget, _) {
        return titleWidget ??
            Text(
              'Tab',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.7),
              ),
            );
      },
    );
  }
}
