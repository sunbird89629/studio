// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CloseTabButton extends StatelessWidget {
  const CloseTabButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          CupertinoIcons.xmark,
          size: 12,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
