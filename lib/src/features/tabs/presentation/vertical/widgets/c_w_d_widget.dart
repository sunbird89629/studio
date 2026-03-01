// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class CWDWidget extends StatelessWidget {
  const CWDWidget({
    super.key,
    required this.cwd,
    required this.textOpacity,
    required this.isActive,
  });

  final String cwd;
  final double textOpacity;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      cwd,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 15,
        color: Colors.white.withValues(alpha: textOpacity),
        fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
      ),
    );
  }
}
