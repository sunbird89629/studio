import 'package:flutter/widgets.dart';

class NewWindowIntent extends Intent {
  const NewWindowIntent();
}

class NewTabIntent extends Intent {
  const NewTabIntent();
}

class PreviousTabIntent extends Intent {
  const PreviousTabIntent();
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class OpenCommandPaletteIntent extends Intent {
  const OpenCommandPaletteIntent();
}

class VimEditIntent extends Intent {
  const VimEditIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class OpenDevToolsIntent extends Intent {
  const OpenDevToolsIntent();
}
