import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip, Material, Colors, InkWell, Icons;

class AddTabButton extends StatelessWidget {
  const AddTabButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New Terminal',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 44,
            child: Center(
              child: Icon(
                Icons.add,
                size: 18,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
