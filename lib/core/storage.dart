import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

abstract interface class ProgressStore {
  AppData read();
  Future<void> write(AppData data);
}

class HiveProgressStore implements ProgressStore {
  HiveProgressStore(this.box);
  final Box<String> box;
  static Future<HiveProgressStore> open() async {
    await Hive.initFlutter();
    return HiveProgressStore(
      await Hive.openBox<String>(
        'science_adventure_v1',
        compactionStrategy: (entries, deleted) => deleted > 20,
      ),
    );
  }

  @override
  AppData read() {
    final raw = box.get('data');
    return raw == null
        ? const AppData()
        : AppData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> write(AppData data) async {
    final previous = box.get('data');
    final oldPhoto = previous == null
        ? null
        : (jsonDecode(previous) as Map)['profile']?['photo'];
    final json = data.toJson();
    await box.put('data', jsonEncode(json));
    if (oldPhoto != json['profile']?['photo']) await box.compact();
    await box.flush();
  }
}

class MemoryProgressStore implements ProgressStore {
  MemoryProgressStore([this.data = const AppData()]);
  AppData data;
  @override
  AppData read() => data;
  @override
  Future<void> write(AppData value) async {
    data = value;
  }
}
