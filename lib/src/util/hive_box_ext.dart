import 'package:hive_ce_flutter/hive_flutter.dart';

extension HiveSingleBox<T extends HiveObject> on Box<T> {
  /// Returns the first record, or creates one via [factory] if the box is empty.
  /// The created object is NOT automatically persisted — call [saveOrAdd] after.
  T getOrCreate(T Function() factory) {
    return isNotEmpty ? getAt(0)! : factory();
  }

  /// Saves the item if it's already in the box, otherwise adds it.
  Future<void> saveOrAdd(T item) async {
    if (item.isInBox) {
      await item.save();
    } else {
      await add(item);
    }
  }
}
