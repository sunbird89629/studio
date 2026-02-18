import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';

class PlaygroundTab extends TabItem {
  PlaygroundTab() {
    title.value = const Text('Playground');
    content.value = const PlaygroundView();
  }
}

class PlaygroundView extends StatefulWidget {
  const PlaygroundView({super.key});

  @override
  State<PlaygroundView> createState() => _PlaygroundViewState();
}

class _PlaygroundViewState extends State<PlaygroundView> {
  var topIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const SizedBox(
            width: 300,
            height: 300,
            child: Center(child: Text('Playground Content')),
          ),
          // Acrylic replacement if needed, for now just a semi-transparent surface
          Positioned.fill(
            child: Container(
              color:
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
