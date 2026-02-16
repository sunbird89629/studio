import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';

class DebugIndicator extends StatelessWidget {
  const DebugIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const SizedBox.shrink();
    }

    final theme = FluentTheme.of(context);

    String label = 'DEBUG';
    if (kProfileMode) {
      label = 'PROFILE';
    }

    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: theme.accentColor.toAccentColor().darker,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: theme.typography.caption?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
