// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class HostWidget extends StatelessWidget {
  const HostWidget({
    super.key,
    required this.host,
    required this.textOpacity,
    required this.isActive,
  });

  final String host;
  final double textOpacity;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Text(
      host,
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
