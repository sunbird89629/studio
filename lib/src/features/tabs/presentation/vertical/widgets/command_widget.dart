// ─── Tab Tile ────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';

class CommandWidget extends StatelessWidget {
  const CommandWidget({
    super.key,
    required this.lastThreeText,
    required this.secondaryColor,
  });

  final String lastThreeText;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Text(
      lastThreeText,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        color: secondaryColor,
      ),
    );
  }
}
