class KeymapRecord {
  /// Action ID → key combination string.
  /// e.g. {"newTab": "cmd+t", "closeTab": "cmd+w"}
  Map<String, String> bindings;

  KeymapRecord({Map<String, String>? bindings})
      : bindings = bindings ?? <String, String>{};

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(bindings);

  factory KeymapRecord.fromJson(Map<String, dynamic> json) {
    return KeymapRecord(
      bindings: json.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
