// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'db.dart';

/*----------------------------------------------------------------------------*/

class DbSettings extends DbListener {
  final Set<String> _keys = {};
  Map<String, String> _settings = {};

  static const String ACCESS_TOKEN_STR = "ACCESS_TOKEN_STR";
  static const String BOOKING_AVAILABLE_HOURS_INT =
      "BOOKING_AVAILABLE_HOURS_INT";
  DbSettings(LaDb ladb) : super(ladb);

  @override
  Future<void> onInit() async {
    final Database db = await database();
    //await db.execute(_kDropTableSettings);
    await db.execute(_kCreateTableSettings);
    _keys.clear();
    _settings = await _readFromDb();
    await _initValueInt(BOOKING_AVAILABLE_HOURS_INT, 5 * 24);
    _keys.add(ACCESS_TOKEN_STR);
  }

  bool isDef(key) => _settings.containsKey(key);

  // Future<void> _initValueStr(String key, String v) async {
  //   _keys.add(key);
  //   if (isDef(key)) {
  //     return;
  //   }
  //   await setStr(key, v);
  // }

  Future<void> _initValueInt(String key, int v) async {
    _keys.add(key);
    if (isDef(key)) {
      return;
    }
    await setInt(key, v);
  }

  // Future<void> _initValueDouble(String key, double v) async {
  //   _keys.add(key);
  //   if (isDef(key)) {
  //     return;
  //   }
  //   await setDouble(key, v);
  // }

  // Future<void> _initValueStrList(String key, List<String> v) async {
  //   _keys.add(key);
  //   if (isDef(key)) {
  //     return;
  //   }
  //   await setStr(key, jsonEncode(v));
  // }

  Future<int> setStr(String key, String v) async {
    Database db = await database();
    final int r = await db.insert(
      _kTableNameSettings,
      {
        "key": key,
        "value": v,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    // update cache
    _settings = await _readFromDb();
    return r;
  }

  Future<int> setInt(String key, int v) async {
    return await setStr(key, v.toString());
  }

  Future<int> setDouble(String key, double v) async {
    return await setStr(key, v.toString());
  }

  Future<int> setStrList(String key, List<String> v) async {
    return await setStr(key, jsonEncode(v));
  }

  String getStr(String key) {
    return _settings[key] ?? "undefined";
  }

  int getInt(String key) {
    return int.tryParse(_settings[key] ?? "-1") ?? -1;
  }

  double getDouble(String key) {
    return double.tryParse(_settings[key] ?? "-1") ?? -1;
  }

  List<String> getStrList(String key) {
    return jsonDecode(_settings[key] ?? "[]").cast<String>();
  }

  Future<Map<String, String>> _readFromDb() async {
    Database db = await database();
    List<Map> q =
        await db.query(_kTableNameSettings, columns: ["key", "value"]);
    Map<String, String> r = {};
    for (var e in q) {
      r[e["key"]] = e["value"];
    }
    return r;
  }

  Future<bool> delete(String key) async {
    Database db = await database();
    return (await db.delete(
          _kTableNameSettings,
          where: "key = ?",
          whereArgs: [key],
        )) ==
        1;
  }

  // Future<int> deleteTable() async {
  //   Database db = await database();
  //   return await db.delete(
  //     _kTableNameSettings,
  //   );
  // }
}

/*----------------------------------------------------------------------------*/

const String _kTableNameSettings = "settings";

/*----------------------------------------------------------------------------*/

const String _kDropTableSettings = """
DROP TABLE IF EXISTS $_kTableNameSettings;
""";

/*----------------------------------------------------------------------------*/

const String _kCreateTableSettings = """
-- DROP TABLE IF EXISTS $_kTableNameSettings;
CREATE TABLE IF NOT EXISTS $_kTableNameSettings(
  key     TEXT,
  value   TEXT,
  PRIMARY KEY (key)
);
""";
