import 'package:flutter/material.dart';

class FluentNavigatorCommandBar extends StatelessWidget {
  const FluentNavigatorCommandBar({super.key, required this.primaryItems});

  final List<Widget> primaryItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: primaryItems,
      ),
    );
  }
}
