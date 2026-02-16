import 'package:hive_ce_flutter/hive_flutter.dart';

part 'keymap_record.g.dart';

@HiveType(typeId: 4)
class KeymapRecord extends HiveObject {
  /// Action ID → key combination string.
  /// e.g. {"newTab": "cmd+t", "closeTab": "cmd+w"}
  @HiveField(0)
  Map<String, String> bindings;

  KeymapRecord({Map<String, String>? bindings})
      : bindings = bindings ?? <String, String>{};
}
