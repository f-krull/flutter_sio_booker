import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/*----------------------------------------------------------------------------*/

class LaDb {
  final Future<Database> _db;
  final Set<DbListener> _listeners = <DbListener>{};

  LaDb._create(Future<Database> db) : _db = db;

  void addListener(final DbListener l) {
    _listeners.add(l);
  }

  Future<void> init() async {
    await _db;
    for (var e in _listeners) {
      await e.onInit();
    }
  }

  Future<Database> database() => _db;

  static Future<LaDb> create() async {
    final db = openDatabase(
      join(await getDatabasesPath(), 'sqlite.db'),
      version: 1,
    );
    return LaDb._create(db);
  }
}

/*----------------------------------------------------------------------------*/

class DbListener {
  final Future<Database> _db;

  @mustCallSuper
  DbListener(LaDb ladb) : _db = ladb.database() {
    ladb.addListener(this);
  }

  @protected
  Future<Database> database() => _db;

  Future<void> onInit() async {}
}

/*----------------------------------------------------------------------------*/
