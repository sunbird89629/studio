import 'dart:typed_data';

/// A single inline image received via the iTerm2 Inline Image Protocol
/// (OSC 1337).
class InlineImageEntry {
  /// Raw image bytes (PNG, JPEG, etc.) decoded from base64.
  final Uint8List bytes;

  /// Cursor column (0-based) at the time the OSC was received.
  final int col;

  /// Cursor row (0-based, viewport-relative) at the time the OSC was received.
  final int row;

  /// Image width in terminal cells, or null if the sender did not specify.
  final int? widthCells;

  /// Image height in terminal cells, or null if the sender did not specify.
  final int? heightCells;

  const InlineImageEntry({
    required this.bytes,
    required this.col,
    required this.row,
    this.widthCells,
    this.heightCells,
  });
}
