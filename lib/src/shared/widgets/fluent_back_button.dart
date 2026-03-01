import 'package:flutter/material.dart';

class FluentBackButton extends StatelessWidget {
  const FluentBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => _onPressed(context),
    );
  }

  void _onPressed(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
    } else {
      Navigator.of(context).maybePop();
    }
  }
}
